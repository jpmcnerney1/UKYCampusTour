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
        ZStack(alignment: .bottomTrailing) {
            Map(position: $cameraPosition) {
                UserAnnotation()
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            
            Button {
                recenterOnUser()
            } label: {
                Image(systemName: "location.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 50, height: 50)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 24)
        }
    }
    
    // grab current location from LocationManager and set camera position to that location
    private func recenterOnUser() {
        guard let coordinate = locationManager.userCoordinate else { return }
        
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        )
    }
        
}

#Preview {
    CampusMapView()
}
