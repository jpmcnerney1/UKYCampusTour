//
//  DirectionsBottomSheet.swift
//  UKYCampusTour
//
//  Created by Codex on 3/25/26.
//

import SwiftUI
import CoreLocation
import MapKit

struct WalkingRoute: Identifiable {
    let id = UUID()
    let title: String
    let totalDistanceMeters: CLLocationDistance
    let totalDuration: TimeInterval
    let steps: [WalkingStep]

    init(title: String, totalDistanceMeters: CLLocationDistance, totalDuration: TimeInterval, steps: [WalkingStep]) {
        self.title = title
        self.totalDistanceMeters = totalDistanceMeters
        self.totalDuration = totalDuration
        self.steps = steps
    }

    init?(route: MKRoute, destinationName: String) {
        let routeDistance = max(route.distance, 1)
        let mappedSteps = route.steps
            .filter { !$0.instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { step in
                WalkingStep(
                    instruction: step.instructions,
                    distanceMeters: step.distance,
                    duration: route.expectedTravelTime * (step.distance / routeDistance)
                )
            }

        guard !mappedSteps.isEmpty else {
            return nil
        }

        self.init(
            title: "Walk to \(destinationName)",
            totalDistanceMeters: route.distance,
            totalDuration: route.expectedTravelTime,
            steps: mappedSteps
        )
    }
}

struct WalkingStep: Identifiable {
    let id = UUID()
    let instruction: String
    let distanceMeters: CLLocationDistance
    let duration: TimeInterval
}

enum DirectionsSheetState {
    case loading(title: String)
    case message(title: String, message: String)
    case route(WalkingRoute)
}

struct DirectionsBottomSheet: View {
    let state: DirectionsSheetState

    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    isExpanded.toggle()
                }
            } label: {
                VStack(spacing: 10) {
                    Capsule()
                        .fill(.secondary)
                        .frame(width: 44, height: 5)

                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(headerTitle)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)

                            if let subtitle {
                                Text(subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                    .padding(.horizontal, 18)

                Group {
                    switch state {
                    case .loading:
                        VStack(alignment: .leading, spacing: 12) {
                            ProgressView()
                            Text("Fetching turn-by-turn walking directions.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)

                    case let .message(_, message):
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)

                    case let .route(route):
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 14) {
                                ForEach(Array(route.steps.enumerated()), id: \.element.id) { index, step in
                                    DirectionStepRow(stepNumber: index + 1, step: step)
                                }
                            }
                            .padding(18)
                        }
                        .frame(maxHeight: 320)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.35), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 18, y: 8)
    }

    private var headerTitle: String {
        switch state {
        case let .loading(title):
            return title
        case let .message(title, _):
            return title
        case let .route(route):
            return route.title
        }
    }

    private var subtitle: String? {
        switch state {
        case .loading:
            return "Loading walking directions"
        case .message:
            return nil
        case let .route(route):
            return "\(route.totalDistanceMeters.distanceText) • \(route.totalDuration.durationText)"
        }
    }
}

private struct DirectionStepRow: View {
    let stepNumber: Int
    let step: WalkingStep

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 28, height: 28)

                Text("\(stepNumber)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(step.instruction)
                    .font(.body)
                    .foregroundStyle(.primary)

                Text("\(step.distanceMeters.distanceText) • \(step.duration.durationText)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }
}

private extension CLLocationDistance {
    var distanceText: String {
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

private extension TimeInterval {
    var durationText: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = self >= 3600 ? [.hour, .minute] : [.minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter.string(from: self) ?? "\(Int(self / 60)) min"
    }
}
