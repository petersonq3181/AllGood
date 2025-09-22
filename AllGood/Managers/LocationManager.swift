//
//  LocationManager.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/21/25.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    
    @Published var lastLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var error: Error?

    override init() {
        super.init()
        manager.delegate = self
        
        // efficiency settings
        manager.distanceFilter = kCLDistanceFilterNone
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.allowsBackgroundLocationUpdates = false
    }
    
    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
    
    func requestSingleLocation() {
        // will trigger delegate callbacks once, then stop automatically
        manager.requestLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.first
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = error
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}
