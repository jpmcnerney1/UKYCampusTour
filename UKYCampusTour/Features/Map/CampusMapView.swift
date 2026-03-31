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
    @StateObject private var searchService = LocationSearchService()
    @StateObject private var savedService = SavedDestinationsService()
    
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
            UserAnnotation()
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
}
