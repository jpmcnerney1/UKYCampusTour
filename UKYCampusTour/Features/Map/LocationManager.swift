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
    
    @Published var userCoordinate: CLLocationCoordinate2D?
    
    override init() {
        super.init() //initialize our parent classes before we configure manager
        manager.delegate = self //designate "manager" to be the recipient of gps data
        manager.requestWhenInUseAuthorization() //show popup
        manager.startUpdatingLocation() //continuousoly update gps location
    }
    
    // need to actually store location somewhere so we can use for non-automatic things such as recentering
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }
        userCoordinate = latestLocation.coordinate
    }
}
