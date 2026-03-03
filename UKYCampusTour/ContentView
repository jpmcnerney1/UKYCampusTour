//
//  ContentView.swift
//  UKYCampusTour
//
//  Created by JP McNerney on 2/22/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            VStack {
                Text("UK Campus Tour")
                    .font(.title)
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            
            MapView()
                .tabItem{
                    Label("Map", systemImage: "map")
                }
        }
    }
}

#Preview {
    ContentView()
}
