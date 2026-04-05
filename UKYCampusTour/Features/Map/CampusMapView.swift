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
    private let destination = CampusDestination.williamTYoungLibrary
    
    //create instance of LocationManager for our MapView
    //StateObject keeps this instance alive for as long as the view is open
    @StateObject private var locationManager = LocationManager()
    @State private var route: MKRoute?
    @State private var sheetState: DirectionsSheetState = .loading(title: CampusDestination.williamTYoungLibrary.name)
    @State private var lastRequestedLocation: CLLocation?
    @State private var routeTask: Task<Void, Never>?
    
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

            Marker(destination.name, coordinate: destination.coordinate)

            if let route {
                MapPolyline(route.polyline)
                    .stroke(.blue, lineWidth: 6)
            }
        }
        .mapStyle(.standard) //compared to satellie, etc
        .ignoresSafeArea()
        .overlay(alignment: .bottom) {
            DirectionsBottomSheet(state: sheetState)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
        .onReceive(locationManager.$authorizationStatus) { status in
            guard status == .denied || status == .restricted else { return }
            sheetState = .message(
                title: "Location Access Needed",
                message: "Enable location access to generate walking directions to \(destination.name)."
            )
        }
        .onReceive(locationManager.$currentLocation) { currentLocation in
            guard let currentLocation else { return }
            guard shouldRequestRoute(for: currentLocation) else { return }
            fetchRoute(from: currentLocation)
        }
        .onDisappear {
            routeTask?.cancel()
        }
    }

    private func shouldRequestRoute(for location: CLLocation) -> Bool {
        guard location.horizontalAccuracy >= 0 else {
            return false
        }

        guard let lastRequestedLocation else {
            return true
        }

        return location.distance(from: lastRequestedLocation) > 20
    }

    private func fetchRoute(from location: CLLocation) {
        lastRequestedLocation = location
        routeTask?.cancel()
        sheetState = .loading(title: destination.name)

        routeTask = Task {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
            request.transportType = .walking

            let directions = MKDirections(request: request)

            do {
                let response = try await directions.calculate()
                guard !Task.isCancelled else { return }

                guard let firstRoute = response.routes.first,
                      let walkingRoute = WalkingRoute(route: firstRoute, destinationName: destination.name) else {
                    sheetState = .message(
                        title: "Directions Unavailable",
                        message: "No walking directions are available from your current location."
                    )
                    route = nil
                    return
                }

                route = firstRoute
                sheetState = .route(walkingRoute)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                route = nil
                sheetState = .message(
                    title: "Directions Unavailable",
                    message: "Walking directions could not be loaded right now."
                )
            }
        }
    }
}

private struct CampusDestination {
    let name: String
    let coordinate: CLLocationCoordinate2D

    static let williamTYoungLibrary = CampusDestination(
        name: "William T. Young Library",
        coordinate: CLLocationCoordinate2D(latitude: 38.032871, longitude: -84.501717)
    )
}
