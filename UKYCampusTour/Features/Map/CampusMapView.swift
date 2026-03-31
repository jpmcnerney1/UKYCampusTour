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
    
    @StateObject private var locationManager = LocationManager()
    
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 38.032871, longitude: -84.501717),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    ))
    
    // Placeholder UI state for bottom panel
    @State private var usingCustomStart: Bool = false
    @State private var startLocationText: String = ""
    @State private var destinationText: String = ""
    @State private var hasLoadedRoute: Bool = false
    @State private var distanceText: String = "0.8 mi"
    @State private var etaText: String = "6 min"
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                UserAnnotation()
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            
            BottomControlsPanel(
                usingCustomStart: $usingCustomStart,
                startLocationText: $startLocationText,
                destinationText: $destinationText,
                hasLoadedRoute: $hasLoadedRoute,
                distanceText: distanceText,
                etaText: etaText,
                onTapStartField: {
                    print("Open start location search")
                },
                onTapDestinationField: {
                    print("Open destination search")
                },
                onRoute: {
                    print("Build route")
                    hasLoadedRoute = true   // placeholder so ETA/distance appears
                },
                onSteps: {
                    print("Show steps")
                },
                onClear: {
                    print("Clear route")
                    startLocationText = ""
                    destinationText = ""
                    hasLoadedRoute = false
                    usingCustomStart = false
                }
            )
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
    }
}

#Preview {
    NavigationStack {
        CampusMapView()
    }
}
