//
//  SavedDestination.swift
//  UKYCampusTour
//
//  Created by JP McNerney on 3/10/26.
//

import Foundation
import CoreLocation

struct SavedDestination: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    
    init(id: UUID = UUID(), title: String, subtitle: String, latitude: Double, longitude: Double) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.latitude = latitude
        self.longitude = longitude
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
