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

    // returns CLLocation near the given location, randomized slightly
    func randomNearbyLocation(from location: CLLocation, maxMeters: Double = 5000) -> CLLocation {
        // convert maxMeters to latitude/longitude degrees
        let earthRadius = 6371000.0 // meters
        
        // random distance and bearing
        let randomDistance = Double.random(in: 0...maxMeters)
        let randomBearing = Double.random(in: 0...(2 * Double.pi))
        
        // original lat/lon in radians
        let lat1 = location.coordinate.latitude * .pi / 180
        let lon1 = location.coordinate.longitude * .pi / 180
        
        // angular distance
        let angularDistance = randomDistance / earthRadius
        
        // haversine formula to calculate new lat/lon
        let lat2 = asin(sin(lat1) * cos(angularDistance) + cos(lat1) * sin(angularDistance) * cos(randomBearing))
        let lon2 = lon1 + atan2(sin(randomBearing) * sin(angularDistance) * cos(lat1),
                                cos(angularDistance) - sin(lat1) * sin(lat2))
        
        // convert back to degrees
        let newLat = lat2 * 180 / .pi
        let newLon = lon2 * 180 / .pi
        
        return CLLocation(latitude: newLat, longitude: newLon)
    }
}
