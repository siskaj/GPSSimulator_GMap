//
//  GooglePlace.swift
//  GPSSimulator_GMap
//
//  Created by Jaromir on 26.02.15.
//  Copyright (c) 2015 Baltoro. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation

struct GooglePlace {
	
	let name: String
	let address: String
	let coordinate: CLLocationCoordinate2D
	let placeType: String
	
	init(dictionary:NSDictionary, acceptedTypes: [String])
	{
		name = dictionary["name"] as! String
		address = dictionary["vicinity"] as! String
		
		let location = dictionary["geometry"]?["location"] as! NSDictionary
		let lat = location["lat"] as! CLLocationDegrees
		let lng = location["lng"] as! CLLocationDegrees
		coordinate = CLLocationCoordinate2DMake(lat, lng)
				
		var foundType = "restaurant"
		let possibleTypes = acceptedTypes.count > 0 ? acceptedTypes : ["bakery", "bar", "cafe", "grocery_or_supermarket", "restaurant"]
		for type in dictionary["types"] as! [String] {
			if contains(possibleTypes, type) {
				foundType = type
				break
			}
		}
		placeType = foundType
	}
}
