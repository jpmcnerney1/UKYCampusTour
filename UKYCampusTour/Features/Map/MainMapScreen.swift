//
//  ContentView.swift
//  UKYCampusTour
//
//  Created by JP McNerney on 2/22/26.
//

import SwiftUI

struct MainMapScreen: View {
    var body: some View {
        NavigationStack {
            CampusMapView()
                .navigationTitle("UK Campus Tour")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                        } label: {
                            Image(systemName: "gearshape") // *placeholder
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                        } label: {
                            Image(systemName: "magnifyingglass") // *placeholder
                        }
                    }
                }
        }
    }
}
