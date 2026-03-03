//
//  MapView.swift
//  UKYCampusTour
//
//  Created by JP McNerney on 2/23/26.
//

import SwiftUI
import MapKit
import CoreLocation

struct CampusMapView: View {
    
    //create instance of LocationManager for our MapView
    //StateObject keeps this instance alive for as long as the view is open
    @StateObject private var locationManager = LocationManager()
    
    //Same thing as StateObject but for simpler value types
    //this block controls where our map is looking
    //start it at live location, if that is unavailable, we go to Willy T
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .region(
        MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 38.032871, longitude: -84.501717),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )
    )

    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation() //blue dot
        }
        .mapStyle(.standard) //compared to satellie, etc
        .ignoresSafeArea()
    }
}

#Preview {
    CampusMapView()
}
