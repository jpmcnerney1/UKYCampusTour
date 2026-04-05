//
//  SettingsView.swift
//  UKYCampusTour
//
//  Created by Codex on 3/27/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    @AppStorage("unitSystem") private var unitSystem = UnitSystem.imperial.rawValue
    @AppStorage("voiceSpeed") private var voiceSpeed = 1.0

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Mode", selection: $appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Navigation") {
                Picker("Units", selection: $unitSystem) {
                    ForEach(UnitSystem.allCases) { system in
                        Text(system.title).tag(system.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Voice Guide") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Speed")
                        Spacer()
                        Text(voiceSpeed.formatted(.number.precision(.fractionLength(2))) + "x")
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: $voiceSpeed, in: 0.5...2.0, step: 0.05) {
                        Text("Voice Speed")
                    } minimumValueLabel: {
                        Text("0.5x")
                    } maximumValueLabel: {
                        Text("2.0x")
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
