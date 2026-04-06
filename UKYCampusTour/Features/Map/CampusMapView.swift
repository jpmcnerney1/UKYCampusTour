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
    @State private var selectedDestination: CampusDestination?
    @State private var isNavigatingRoute = false

    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchService = LocationSearchService()
    @StateObject private var savedService = SavedDestinationsService()

    @State private var route: MKRoute?
    @State private var sheetState: DirectionsSheetState = .loading(title: "Destination")
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

    private var activeWalkingRoute: WalkingRoute? {
        guard case let .route(route) = sheetState else {
            return nil
        }

        return route
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(position: $cameraPosition) {
                UserAnnotation()

                if let selectedDestination {
                    Marker(selectedDestination.name, coordinate: selectedDestination.coordinate)
                }

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
                                    fetchRoute(from: currentLocation, to: campusDestination)
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
                let destinationName = selectedDestination?.name ?? "your destination"
                sheetState = .message(
                    title: "Location Access Needed",
                    message: "Enable location access to generate walking directions to \(destinationName)."
                )
            }
            .onReceive(locationManager.$currentLocation) { currentLocation in
                guard let currentLocation else { return }
                guard let selectedDestination else { return }
                guard shouldRequestRoute(for: currentLocation) else { return }
                fetchRoute(from: currentLocation, to: selectedDestination)
            }
            .onDisappear {
                routeTask?.cancel()
            }

            if isNavigatingRoute, let activeWalkingRoute {
                VStack(spacing: 0) {
                    NavigationInstructionBanner(route: activeWalkingRoute)
                        .padding(.horizontal)
                        .padding(.top, 12)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                NavigationSummaryBar(
                    distanceText: distanceText,
                    etaText: etaText,
                    onCancel: cancelActiveRoute
                )
                .padding(.horizontal)
                .padding(.bottom, 12)
            } else {
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
                        resolveDestinationAndRoute(enterNavigationMode: true)
                    },
                    onSteps: {
                        resolveDestinationAndRoute(showSteps: true)
                    },
                    onClear: {
                        clearRouteSelection()
                    }
                )
                .padding(.horizontal)
                .padding(.bottom, 12)
            }

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
            .padding(.bottom, isNavigatingRoute ? 120 : 140)
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
                fetchRoute(from: currentLocation, to: campusDestination)
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
                isNavigatingRoute = false
                sheetState = .message(
                    title: "Directions Unavailable",
                    message: "Walking directions could not be loaded right now."
                )
            }
        }
    }

    private func resolveDestinationAndRoute(showSteps: Bool = false, enterNavigationMode: Bool = false) {
        let query = searchService.searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if query.isEmpty {
            clearRouteSelection()
            sheetState = .message(
                title: "Destination Required",
                message: "Search for a campus destination before requesting a route."
            )
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
                isNavigatingRoute = false
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
                isNavigatingRoute = false
                sheetState = .message(
                    title: "Location Access Needed",
                    message: "Enable location access to generate walking directions to \(resolvedName)."
                )
                return
            }

            isNavigatingRoute = enterNavigationMode
            fetchRoute(from: currentLocation, to: campusDestination)

            if showSteps {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showingStepsSheet = true
                }
            }
        }
    }

    private func clearRouteSelection() {
        startLocationText = ""
        destinationText = ""
        searchService.searchText = ""
        selectedDestination = nil
        hasLoadedRoute = false
        usingCustomStart = false
        isNavigatingRoute = false
        route = nil
        sheetState = .loading(title: "Destination")
        lastRequestedLocation = nil
        routeTask?.cancel()
    }

    private func cancelActiveRoute() {
        clearRouteSelection()
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

private struct NavigationInstructionBanner: View {
    let route: WalkingRoute

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Next")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(route.steps.first?.instruction ?? route.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            if let nextStep = route.steps.first {
                Text("\(nextStep.distanceMeters.navigationDistanceText) remaining in this leg")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.35), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 14, y: 6)
    }
}

private struct NavigationSummaryBar: View {
    let distanceText: String
    let etaText: String
    let onCancel: () -> Void

    private let ukBlue = Color(red: 0/255, green: 51/255, blue: 160/255)

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Remaining")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(distanceText)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            Divider()
                .frame(height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text("Time Left")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(etaText)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            Button("Cancel", action: onCancel)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(ukBlue, in: Capsule())
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.35), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 18, y: 8)
    }
}

private extension CLLocationDistance {
    var navigationDistanceText: String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .short

        if self >= 1000 {
            let measurement = Measurement(value: self / 1000, unit: UnitLength.kilometers)
            return formatter.string(from: measurement)
        } else {
            let measurement = Measurement(value: self, unit: UnitLength.meters)
            return formatter.string(from: measurement)
        }
    }
}
