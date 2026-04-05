//
//  LocationManager.swift
//  UKYCampusTour
//
//  Created by JP McNerney on 3/3/26.
//

import MapKit
import CoreLocation
import Foundation

// Helper class to ask iOS for location permission and receive GPS updates
// needs to be an ObservableObject so MapView can watch it and update view accordingly
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // our manager that actually communicates with GPS chip
    private let manager = CLLocationManager()
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    
    @Published var userCoordinate: CLLocationCoordinate2D?
    
    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init() //initialize our parent classes before we configure manager
        manager.delegate = self //designate "manager" to be the recipient of gps data
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.requestWhenInUseAuthorization() //show popup
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation() //continuousoly update gps location
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            manager.stopUpdatingLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }

        currentLocation = latestLocation
        userCoordinate = latestLocation.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed: \(error.localizedDescription)")
    }
}
