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
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape.fill")
                        }
                        .accessibilityLabel("Open settings")
                    }
                }
        }
    }
}
