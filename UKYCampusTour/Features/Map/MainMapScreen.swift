//
//  ContentView.swift
//  UKYCampusTour
//
//  Created by JP McNerney on 2/22/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            CampusMapView()
                .ignoresSafeArea()
                .navigationTitle("UK Campus Tour")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape.fill")
                        }
                        .accessibilityLabel("Open settings")
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
