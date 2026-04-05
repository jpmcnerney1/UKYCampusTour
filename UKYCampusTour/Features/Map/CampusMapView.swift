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
    @State private var selectedDestination = CampusDestination.williamTYoungLibrary

    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchService = LocationSearchService()
    @StateObject private var savedService = SavedDestinationsService()

    @State private var route: MKRoute?
    @State private var sheetState: DirectionsSheetState = .loading(title: CampusDestination.williamTYoungLibrary.name)
    @State private var lastRequestedLocation: CLLocation?
    @State private var routeTask: Task<Void, Never>?
    @State private var showingStepsSheet = false

    @State private var cameraPosition: MapCameraPosition = .userLocation(
        fallback: .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 38.032871, longitude: -84.501717),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )
    )

    // Bottom panel UI state
    @State private var usingCustomStart: Bool = false
    @State private var startLocationText: String = ""
    @State private var destinationText: String = ""
    @State private var hasLoadedRoute: Bool = false
    @State private var distanceText: String = "0.8 mi"
    @State private var etaText: String = "6 min"

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(position: $cameraPosition) {
                UserAnnotation()

                Marker(selectedDestination.name, coordinate: selectedDestination.coordinate)

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
                        ForEach(savedService.savedDestinations) { savedDestination in
                            Button {
                                let campusDestination = CampusDestination(
                                    name: savedDestination.title,
                                    coordinate: savedDestination.coordinate
                                )

                                selectedDestination = campusDestination
                                moveCamera(to: savedDestination.coordinate)
                                searchService.searchText = savedDestination.title
                                destinationText = savedDestination.title
                                savedService.moveDestinationToTop(savedDestination)

                                if let currentLocation = locationManager.currentLocation {
                                    fetchRoute(from: currentLocation, to: selectedDestination)
                                }
                            } label: {
                                Label(savedDestination.title, systemImage: "bookmark")
                            }
                        }
                    }
                }
            }
            .onReceive(locationManager.$authorizationStatus) { status in
                guard status == .denied || status == .restricted else { return }
                sheetState = .message(
                    title: "Location Access Needed",
                    message: "Enable location access to generate walking directions to \(selectedDestination.name)."
                )
            }
            .onReceive(locationManager.$currentLocation) { currentLocation in
                guard let currentLocation else { return }
                guard shouldRequestRoute(for: currentLocation) else { return }
                fetchRoute(from: currentLocation, to: selectedDestination)
            }
            .onDisappear {
                routeTask?.cancel()
            }

            // bottom panel
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
                    resolveDestinationAndRoute(showSteps: false)
                },
                onSteps: {
                    resolveDestinationAndRoute(showSteps: true)
                },
                onClear: {
                    startLocationText = ""
                    destinationText = ""
                    hasLoadedRoute = false
                    usingCustomStart = false
                    route = nil
                    routeTask?.cancel()
                }
            )
            .padding(.horizontal)
            .padding(.bottom, 12)

            // recenter button on top
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
            .padding(.bottom, 140)
        }
        .sheet(isPresented: $showingStepsSheet) {
            DirectionsBottomSheet(state: sheetState)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

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

            let campusDestination = CampusDestination(
                name: completion.title,
                coordinate: coordinate
            )

            selectedDestination = campusDestination
            moveCamera(to: coordinate)
            savedService.addDestinationIfNeeded(newDestination)
            savedService.moveDestinationToTop(newDestination)
            searchService.searchText = completion.title
            destinationText = completion.title

            if let currentLocation = locationManager.currentLocation {
                fetchRoute(from: currentLocation, to: selectedDestination)
            }
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

    private func recenterOnUser() {
        guard let location = locationManager.currentLocation else { return }

        cameraPosition = .region(
            MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        )
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

    private func fetchRoute(from location: CLLocation, to destination: CampusDestination) {
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
                    hasLoadedRoute = false
                    return
                }

                route = firstRoute
                sheetState = .route(walkingRoute)
                hasLoadedRoute = true
                distanceText = String(format: "%.1f mi", firstRoute.distance / 1609.34)
                etaText = "\(Int(ceil(firstRoute.expectedTravelTime / 60))) min"

                let rect = firstRoute.polyline.boundingMapRect
                let paddedRect = rect.insetBy(dx: -rect.size.width * 0.25, dy: -rect.size.height * 0.25)
                cameraPosition = .rect(paddedRect)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                route = nil
                hasLoadedRoute = false
                sheetState = .message(
                    title: "Directions Unavailable",
                    message: "Walking directions could not be loaded right now."
                )
            }
        }
    }

    private func resolveDestinationAndRoute(showSteps: Bool = false) {
        let query = searchService.searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if query.isEmpty {
            if let currentLocation = locationManager.currentLocation {
                fetchRoute(from: currentLocation, to: selectedDestination)
                if showSteps {
                    showingStepsSheet = true
                }
            }
            return
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 38.032871, longitude: -84.501717),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )

        let search = MKLocalSearch(request: request)

        search.start { response, error in
            guard let mapItem = response?.mapItems.first,
                  let coordinate = mapItem.placemark.location?.coordinate else {
                print("Search failed: \(error?.localizedDescription ?? "Unknown error")")
                sheetState = .message(
                    title: "Destination Not Found",
                    message: "Could not find a campus destination matching \"\(query)\"."
                )
                hasLoadedRoute = false
                return
            }

            let resolvedName = mapItem.name ?? query

            let campusDestination = CampusDestination(
                name: resolvedName,
                coordinate: coordinate
            )

            let newSavedDestination = SavedDestination(
                title: resolvedName,
                subtitle: mapItem.placemark.title ?? "",
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )

            selectedDestination = campusDestination
            destinationText = resolvedName
            searchService.searchText = resolvedName
            moveCamera(to: coordinate)
            savedService.addDestinationIfNeeded(newSavedDestination)

            guard let currentLocation = locationManager.currentLocation else {
                sheetState = .message(
                    title: "Location Access Needed",
                    message: "Enable location access to generate walking directions to \(resolvedName)."
                )
                return
            }

            fetchRoute(from: currentLocation, to: campusDestination)

            if showSteps {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showingStepsSheet = true
                }
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

#Preview {
    NavigationStack {
        CampusMapView()
    }
}
