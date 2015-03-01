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
	
	func setupScenario() {
		
		func obtainCoordinatesItemFromString(nazev: String) -> Future<CLLocationCoordinate2D> {
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
		
		
	}
	func fetchRouteFrom(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Future<JSRoute> {
	let promise = Promise<JSRoute>()
		let urlString = "https://maps.googleapis.com/maps/api/directions/json?key=\(apiKey)&origin=\(from.latitude),\(from.longitude)&destination=\(to.latitude),\(to.longitude)&mode=bicycling"

		UIApplication.sharedApplication().networkActivityIndicatorVisible = true
		session.dataTaskWithURL(NSURL(string: urlString)!) {data, response, error in
			UIApplication.sharedApplication().networkActivityIndicatorVisible = false
			var pole = [CLLocationCoordinate2D]()
			if let json = NSJSONSerialization.JSONObjectWithData(data, options:nil, error:nil) as? [String:AnyObject],
				let routes = json["routes"] as AnyObject? as? [AnyObject],
				let route = routes.first as? [String : AnyObject],
				let polyline = route["overview_polyline"] as AnyObject? as? [String : String],
				let encodedPath = polyline["points"] as AnyObject? as? String {
					let path = GMSPath(fromEncodedPath: encodedPath)
					for i in 0..<path.count() {
						pole.append(path.coordinateAtIndex(i))
					}
			promise.success(JSRoute(points: pole))
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
	
}

struct JSRoute {
	var points: [CLLocationCoordinate2D]
}
