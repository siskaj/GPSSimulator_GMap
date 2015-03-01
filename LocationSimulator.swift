//
//  LocationSimulator.swift
//  GPSSimulator_GMap
//
//  Created by Jaromir on 28.02.15.
//  Copyright (c) 2015 Baltoro. All rights reserved.
//

import UIKit

let rad = 180/M_PI

func delay(delay:Double, closure:()->()) {
	dispatch_after(
		dispatch_time(
			DISPATCH_TIME_NOW,
			Int64(delay * Double(NSEC_PER_SEC))
		),
		dispatch_get_main_queue(), closure)
}

class LocationSimulator: CLLocationManager {
   
}
