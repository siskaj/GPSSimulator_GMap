//
//  LocationSimulator.swift
//  GPSSimulator_GMap
//
//  Created by Jaromir on 28.02.15.
//  Copyright (c) 2015 Baltoro. All rights reserved.
//

import UIKit
import MapKit

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

//TODO: Jsem si jist, ze to chci pocitat ze souradnic na mape a ne lat/lon?
func course2(point1: CLLocationCoordinate2D, point2:CLLocationCoordinate2D) -> Double {
  var tcl: Double = 0
  let p1 = MKMapPointForCoordinate(point1)
  let p2 = MKMapPointForCoordinate(point2)
  let dx = p2.x - p1.x
  println("dx - \(dx)")
  let dy = p2.y - p1.y
  println("dy = \(dy), dx/dy = \(dx/dy), atan  = \(rad * atan(dx/dy))")
  if dx > 0 {
    if dy > 0 { tcl = rad * atan(dx/dy) }
    if dy < 0 { tcl = 180 - rad * atan(-dx/dy) }
    if dy == 0 { tcl = 90 }
  }
  if dx < 0 {
    if dy > 0 { tcl = -rad * atan(-dx/dy) }
    if dy < 0 { tcl = rad * atan(dx/dy) - 180 }
    if dy == 0 { tcl = 270 }
  }
  if dx == 0 {
    if dy >= 0 { tcl = 0 }
    if dy < 0 { tcl = 180 }
  }
  return tcl
}
