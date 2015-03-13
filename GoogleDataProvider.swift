//
//  GoogleDataProvider.swift
//  GPSSimulator_GMap
//
//  Created by Jaromir on 26.02.15.
//  Copyright (c) 2015 Baltoro. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import BrightFutures
import MapKit

class GoogleDataProvider {
	
	let apiKey = "AIzaSyDxMlJ6RUzoXV0ZkfkPOkfmI2Nm2d-Jel8"
	var photoCache = [String:UIImage]()
	var placesTask = NSURLSessionDataTask()
	var session: NSURLSession {
		return NSURLSession.sharedSession()
	}
	
	func fetchPlacesNearCoordinate(coordinate: CLLocationCoordinate2D, radius: Double, types:[String], completion: (([GooglePlace]) -> Void)) -> ()
	{
		var urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?key=\(apiKey)&location=\(coordinate.latitude),\(coordinate.longitude)&radius=\(radius)&rankby=prominence&sensor=true"
		let typesString = types.count > 0 ? join("|", types) : "food"
		urlString += "&types=\(typesString)"
		urlString = urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
		
		if placesTask.taskIdentifier > 0 && placesTask.state == .Running {
			placesTask.cancel()
		}
		UIApplication.sharedApplication().networkActivityIndicatorVisible = true
		placesTask = session.dataTaskWithURL(NSURL(string: urlString)!) {data, response, error in
			UIApplication.sharedApplication().networkActivityIndicatorVisible = false
			var placesArray = [GooglePlace]()
			if let json = NSJSONSerialization.JSONObjectWithData(data, options:nil, error:nil) as? NSDictionary {
				if let results = json["results"] as? NSArray {
					for rawPlace:AnyObject in results {
						let place = GooglePlace(dictionary: rawPlace as! NSDictionary, acceptedTypes: types)
						placesArray.append(place)
					}
				}
			}
			dispatch_async(dispatch_get_main_queue()) {
				completion(placesArray)
			}
		}
		placesTask.resume()
	}
	
	
	
	
	func fetchDirectionsFrom(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, completion: ((String?) -> Void)) -> ()
	{
		let urlString = "https://maps.googleapis.com/maps/api/directions/json?key=\(apiKey)&origin=\(from.latitude),\(from.longitude)&destination=\(to.latitude),\(to.longitude)&mode=walking"
		
		UIApplication.sharedApplication().networkActivityIndicatorVisible = true
		session.dataTaskWithURL(NSURL(string: urlString)!) {data, response, error in
			UIApplication.sharedApplication().networkActivityIndicatorVisible = false
			var encodedRoute: String?
			if let json = NSJSONSerialization.JSONObjectWithData(data, options:nil, error:nil) as? [String:AnyObject] {
				if let routes = json["routes"] as AnyObject? as? [AnyObject] {
					if let route = routes.first as? [String : AnyObject] {
						if let polyline = route["overview_polyline"] as AnyObject? as? [String : String] {
							if let points = polyline["points"] as AnyObject? as? String {
								encodedRoute = points
							}
						}
					}
				}
			}
			dispatch_async(dispatch_get_main_queue()) {
				completion(encodedRoute)
			}
			}.resume()
	}

	func fetchRouteFrom(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Future<JSRoute> {
		let promise = Promise<JSRoute>()
		let urlString = "https://maps.googleapis.com/maps/api/directions/json?key=\(apiKey)&origin=\(from.latitude),\(from.longitude)&destination=\(to.latitude),\(to.longitude)&mode=bicycling"
		
		UIApplication.sharedApplication().networkActivityIndicatorVisible = true
		session.dataTaskWithURL(NSURL(string: urlString)!) {data, response, error in
			UIApplication.sharedApplication().networkActivityIndicatorVisible = false
			var pole = [CLLocationCoordinate2D]()
			var segments = [GoogleLeg]()
			if let json = NSJSONSerialization.JSONObjectWithData(data, options:nil, error:nil) as? [String:AnyObject],
				let routes = json["routes"] as AnyObject? as? [AnyObject],
				let route = routes.first as? [String : AnyObject],
				let polyline = route["overview_polyline"] as AnyObject? as? [String : String],
				let legs = route["legs"] as? [AnyObject],
				let encodedPath = polyline["points"] as AnyObject? as? String {
					let path = GMSPath(fromEncodedPath: encodedPath)
					for i in 0..<path.count() {
						pole.append(path.coordinateAtIndex(i))
					}
					for leg in legs {
						segments.append(self.JSONLeg2GoogleLeg(leg as! [String:AnyObject]))
					}
					promise.success(JSRoute(points: pole, legs: segments))
			} else {
				if error != nil {
					promise.failure(error)
				} else {
					var outError = NSError(domain: "com.baltoro.BrightFuturesTest1", code: 404, userInfo:[NSLocalizedDescriptionKey : "No routes found!"])
					promise.failure(outError)
				}
			}
		}
		return promise.future
	}
	

	func setupScenario() {
		
		func obtainCoordinatesFromString(nazev: String) -> Future<CLLocationCoordinate2D> {
			let promise = Promise<CLLocationCoordinate2D>()
			let geocoder = CLGeocoder()
			
			geocoder.geocodeAddressString(nazev) { (placemarks: [AnyObject]!, error: NSError!) in
				var outError: NSError?
				if placemarks != nil && placemarks.count > 0 {
					let mark = placemarks[0] as! CLPlacemark
					let coordinate = mark.location.coordinate
					promise.success(coordinate)
				} else {
					if error != nil {
						promise.failure(error)
					} else {
						outError = NSError(domain: "com.baltoro.BrightFuturesTest1", code: 404, userInfo:[NSLocalizedDescriptionKey : "No routes found!"])
						promise.failure(outError!)
					}
					
				}
			}
			return promise.future
  	}
		
		let srcCoord: Future<CLLocationCoordinate2D> = obtainCoordinatesFromString("Pruhonice")
		let destCoord: Future<CLLocationCoordinate2D> = obtainCoordinatesFromString("Jílove u Prahy")
		let coordSequence = [srcCoord, destCoord]

		let fut1: Future<[CLLocationCoordinate2D]> = FutureUtils.sequence(coordSequence)
		let fut2: Future<JSRoute> = fut1.flatMap { krajniBody -> Future<JSRoute> in
			return self.fetchRouteFrom(krajniBody[0], to: krajniBody[1])
		}
	
}

struct GoogleStep {
	let instruction: String
	let start: CLLocationCoordinate2D
	let end: CLLocationCoordinate2D
	let encodedPath: String
	init(instruction: String = "", start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, encodedPath: String = "") {
		self.instruction = instruction
		self.start = start
		self.end = end
		self.encodedPath = encodedPath
	}
}

func JSONStep2GoogleStep(step: [String:AnyObject]) -> GoogleStep {
	return GoogleStep(instruction: step["html_instruction"] as! String, start: step["start_location"] as! CLLocationCoordinate2D, end: step["end_location"] as! CLLocationCoordinate2D)
}

func JSONLeg2GoogleLeg(leg: [String:AnyObject]) -> GoogleLeg {
	let pole = leg["steps"] as! [AnyObject]
	var googleSteps = [GoogleStep]()
	for step  in pole {
		googleSteps.append(JSONStep2GoogleStep(step as! [String : AnyObject]))
	}
	let start = leg["start_location"] as! CLLocationCoordinate2D
	let end = leg["end_location"] as! CLLocationCoordinate2D
	return GoogleLeg(steps: googleSteps, start: start, end: end)
}

struct GoogleLeg {
	let steps: [GoogleStep]
	let start: CLLocationCoordinate2D
	let end: CLLocationCoordinate2D
	let startAddress: String
	let endAddress: String
	init(steps: [GoogleStep], start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, startAddress: String = "", endAddress: String = "") {
		self.steps = steps
		self.start = start
		self.end = end
		self.startAddress = startAddress
		self.endAddress = endAddress
	}
}

struct JSRoute {
	var points: [CLLocationCoordinate2D]
	var legs: [GoogleLeg]
}
