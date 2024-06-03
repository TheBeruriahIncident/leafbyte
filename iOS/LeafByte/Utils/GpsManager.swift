//
//  GpsManager.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 1/28/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import CoreLocation
import UIKit

// This pretends to be a view controller to get GPS location, because the delegate has a runtime requirement of being a view controller.
final class GpsManager: UIViewController, CLLocationManagerDelegate {
    // This is a static variable so that it doesn't get garbage collected before the callback ( https://en.wikipedia.org/wiki/Garbage_collection_(computer_science) ).
    static let gpsManager = GpsManager()
    
    let clLocationManager = CLLocationManager()
    
    var onLocation: ((_ location: CLLocation) -> Void)!
    var onError: ((_ error: Error) -> Void)!
    
    static func requestLocation(onLocation: @escaping (_ location: CLLocation) -> Void, onError: @escaping (_ error: Error) -> Void) {
        gpsManager.onLocation = onLocation
        gpsManager.onError = onError
        gpsManager.requestLocation()
    }
    
    func requestLocation() {
        clLocationManager.requestWhenInUseAuthorization()
        // Best accuracy is tempting, but that takes ~5 seconds per request, as opposed to nearly instantaneous.
        clLocationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        clLocationManager.delegate = self
        clLocationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        onLocation(locations.first!)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onError(error)
    }
}

