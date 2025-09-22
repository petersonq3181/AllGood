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
    private var singleLocationCompletion: ((CLLocation?) -> Void)?

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
    
    func requestSingleLocation(completion: @escaping (CLLocation?) -> Void) {
        singleLocationCompletion = completion
        manager.requestLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let loc = locations.first
        lastLocation = loc
        singleLocationCompletion?(loc)
        singleLocationCompletion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        singleLocationCompletion?(nil)
        singleLocationCompletion = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}
