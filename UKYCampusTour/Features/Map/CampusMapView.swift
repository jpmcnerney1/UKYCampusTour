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
    
    @StateObject private var locationManager = LocationManager()

    @StateObject private var searchService = LocationSearchService()
    @StateObject private var savedService = SavedDestinationsService()

    @State private var route: MKRoute?
    @State private var sheetState: DirectionsSheetState = .loading(title: CampusDestination.williamTYoungLibrary.name)
    @State private var lastRequestedLocation: CLLocation?
    @State private var routeTask: Task<Void, Never>?
    
    // State var for camera position. Defaults to Willy T
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 38.032871, longitude: -84.501717),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    ))
    
    // User defaults identifier. Used for saveDestination() and loadDestination()
    private let savedKey = "saved_destinations"
    
    var body: some View {
        Map(position: $cameraPosition) {

            UserAnnotation() //blue dot

            Marker(destination.name, coordinate: destination.coordinate)

            if let route {
                MapPolyline(route.polyline)
                    .stroke(.blue, lineWidth: 6)
            }
        }
        .mapStyle(.standard)
        .ignoresSafeArea()
        .onAppear {
            savedService.loadSavedDestinations()
        }
        .searchable(
            text: $searchService.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search campus destinations"
        )
        .searchSuggestions {
            ForEach(searchService.completions, id: \.self) { completion in
                Button {
                    searchForCompletion(completion)
                } label: {
                    VStack(alignment: .leading) {
                        Text(completion.title)
                        if !completion.subtitle.isEmpty {
                            Text(completion.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
             
            if !savedService.savedDestinations.isEmpty {
                Section("Saved Destinations") {
                    ForEach(savedService.savedDestinations) { destination in
                        Button {
                            moveCamera(to: destination.coordinate)
                            searchService.searchText = destination.title
                            savedService.moveDestinationToTop(destination)
                        } label: {
                            Label(destination.title, systemImage: "bookmark")
                        }
                        .swipeActions {
                                Button(role: .destructive) {
                                    savedService.deleteDestination(destination)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }
    
    // Turns our chosen suggested location into an actual map detailed location
    private func searchForCompletion(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        
        search.start { response, error in
            guard let mapItem = response?.mapItems.first,
                  let coordinate = mapItem.placemark.location?.coordinate else {
                print("Search failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let newDestination = SavedDestination(
                title: completion.title,
                subtitle: completion.subtitle,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            
            moveCamera(to: coordinate)
            savedService.addDestinationIfNeeded(newDestination)
            searchService.searchText = completion.title
        }
    }
    
    private func moveCamera(to coordinate: CLLocationCoordinate2D) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        )
    }
}

#Preview {
    NavigationStack {
        CampusMapView()
    }
=======
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
