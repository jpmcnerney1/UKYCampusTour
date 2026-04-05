//
//  LocationSearchService.swift
//  UKYCampusTour
//
//  Created by JP McNerney on 3/10/26.
//

import Foundation
import MapKit

final class LocationSearchService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchText: String = "" {
        didSet {
            if searchText.isEmpty {
                completions = []
            } else {
                completer.queryFragment = searchText
            }
        }
    }
    
    // For others: "Published" means our views will be notified whenever this variable changes (live update of list in this case)
    @Published var completions: [MKLocalSearchCompletion] = []
    
    private let completer = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        completer.delegate = self
        //38.009810406199115, -84.5045889823727 = arboretum, so making our span a little longer than that from UK library should give us a proper scope
        // Prioritize coordinates near uk area
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 38.032871, longitude: -84.501717),
            span: MKCoordinateSpan(latitudeDelta: 0.007, longitudeDelta: 0.007)
        )
        
        completer.resultTypes = [.pointOfInterest, .query]
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer failed: \(error.localizedDescription)")
    }
}
