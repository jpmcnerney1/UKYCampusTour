//
//  UKYCampusTourApp.swift
//  UKYCampusTour
//
//  Created by JP McNerney on 2/22/26.
//

import SwiftUI

@main
struct UKYCampusTourApp: App {
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue

    var body: some Scene {
        WindowGroup {
            MainMapScreen()
                .preferredColorScheme(AppearanceMode(rawValue: appearanceMode)?.colorScheme)
        }
    }
}
