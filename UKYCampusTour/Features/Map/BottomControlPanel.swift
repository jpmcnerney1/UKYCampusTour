//
//  BottomControlPanel.swift
//  UKYCampusTour
//
//  Created by JP McNerney on 3/31/26.
//

import SwiftUI

struct BottomControlsPanel: View {
    
    @Binding var usingCustomStart: Bool
    @Binding var startLocationText: String
    @Binding var destinationText: String
    @Binding var hasLoadedRoute: Bool
    
    let distanceText: String
    let etaText: String
    
    let onTapStartField: () -> Void
    let onTapDestinationField: () -> Void
    let onRoute: () -> Void
    let onSteps: () -> Void
    let onClear: () -> Void
    
    private let ukBlue = Color(red: 0/255, green: 51/255, blue: 160/255)
    private let ukLightBlue = Color(red: 0/255, green: 91/255, blue: 187/255)
    private let ukGray = Color(.systemGray5)
    
    var body: some View {
        VStack(spacing: 10) {
            
            if hasLoadedRoute {
                HStack {
                    Text("Distance: \(distanceText)")
                    Spacer()
                    Text("ETA: \(etaText)")
                }
                .font(.subheadline)
                .foregroundStyle(ukBlue)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(ukGray.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            if usingCustomStart {
                ControlFieldRow(
                    title: startLocationText.isEmpty ? "Start Location" : startLocationText,
                    systemImage: "arrow.right.circle.fill",
                    action: onTapStartField
                )
            }
            
            ControlFieldRow(
                title: destinationText.isEmpty ? "Destination" : destinationText,
                systemImage: "mappin.and.ellipse",
                action: onTapDestinationField
            )
            
            HStack(spacing: 12) {
                Button(action: onClear) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Clear")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .background(ukGray)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Button(action: onRoute) {
                    HStack {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        Text("Route")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .background(ukBlue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Button(action: onSteps) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Get Steps")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .background(ukLightBlue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(radius: 8)
    }
}

private struct ControlFieldRow: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    private let ukBlue = Color(red: 0/255, green: 51/255, blue: 160/255)
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: systemImage)
                    .foregroundStyle(ukBlue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(ukBlue.opacity(0.5), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
