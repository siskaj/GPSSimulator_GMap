//
//  ViewController.swift
//  GPSSimulator_GMap
//
//  Created by Jaromir on 26.02.15.
//  Copyright (c) 2015 Baltoro. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

	@IBOutlet weak var mapView: GMSMapView!
	
	var locationManager: LocationSimulator!

	private func checkLocationAuthorizationStatus() {
		if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
			locationManager.startUpdatingLocation()
			
			mapView.myLocationEnabled = true
			mapView.settings.myLocationButton = true
		} else {
			self.locationManager.requestWhenInUseAuthorization()
		}
	}

	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

//MARK: LocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
	func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		checkLocationAuthorizationStatus()
	}
	
	func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
		let oldLocation = locations.first as? CLLocation
		let currentLocation = locations.last as? CLLocation
		updateMap(oldLocation, newLocation: currentLocation)
//		detailViewController.localPath = aktualniRouteStep(route, currentLocation!, 1000)
	}
	
//	func updateMap(oldLocation: CLLocation?, newLocation: CLLocation?) {
//		if let theNewLocation = newLocation {
//			if oldLocation?.coordinate.latitude != theNewLocation.coordinate.latitude || oldLocation?.coordinate.longitude != theNewLocation.coordinate.longitude {
//				let region = MKCoordinateRegionMakeWithDistance(theNewLocation.coordinate, 100, 100)
//				mapView.setRegion(region, animated: true)
//				var camera = mapView.camera
//				camera.heading = locationManager.course2(oldLocation!, point2: newLocation!)
//				//				detailViewController.azimut = locationManager.course3(oldLocation!, endLocation: newLocation!)
//				//				camera.heading = detailViewController.azimut
//				mapView.setCamera(camera, animated: true)
//				detailViewController.createSnapshotWithPath(detailViewController.imageView!, route: route!, currentLocation: currentLocation!, previousLocation: oldLocation!)
//			}
//		}
//	}
	
	func updateMap 
}


