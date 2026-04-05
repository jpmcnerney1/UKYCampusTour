//
//  SavedDestinationsService.swift
//  UKYCampusTour
//
//  Created by JP McNerney on 3/30/26.
//

import Foundation

final class SavedDestinationsService: ObservableObject {
    @Published var savedDestinations: [SavedDestination] = []
    
    private let savedKey = "saved_destinations"
    
    func addDestinationIfNeeded(_ destination: SavedDestination) {
        if !savedDestinations.contains(where: {
            $0.title == destination.title && $0.subtitle == destination.subtitle
        }) {
            savedDestinations.insert(destination, at: 0)
            saveDestinations()
        }
    }
    
    // User defaults
    func saveDestinations() {
        do {
            let data = try JSONEncoder().encode(savedDestinations)
            UserDefaults.standard.set(data, forKey: savedKey)
        } catch {
            print("Failure saving destinations. \(error.localizedDescription)")
        }
    }
    
    func loadSavedDestinations() {
        guard let data = UserDefaults.standard.data(forKey: savedKey) else { return }
        
        do {
            savedDestinations = try JSONDecoder().decode([SavedDestination].self, from: data)
        } catch {
            print("Failure loading destininations. \(error.localizedDescription)")
        }
    }
    
    func moveDestinationToTop(_ destination: SavedDestination) {
        if let index = savedDestinations.firstIndex(of: destination) {
            let item = savedDestinations.remove(at: index)
            savedDestinations.insert(item, at: 0)
            saveDestinations()
        }
    }
    
    func deleteDestination(_ destination: SavedDestination) {
        savedDestinations.removeAll { $0.id == destination.id }
        saveDestinations()
    }
    
}
    
