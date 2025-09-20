//
//  BottomBar.swift
//  FrostPTO
//
//  Created by Jesse Duenas on 9/17/25.
//

import SwiftUI

// Bottom bar with tab navigation items
struct BottomBar: View {
    let onSelect: (Route) -> Void
    let selected: Route?
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var barBackground: Color {
        colorScheme == .dark ? .black : Color.clear
    }
    
    private var dividerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }
    
    private var unselectedColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .frame(height: 0.5)
                .background(dividerColor)
            HStack(spacing: 16) {
                Group {
                    Button(action: { onSelect(.planner) }) {
                        BarItem(title: "Home", systemImage: "house.fill", selected: selected == .planner)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button(action: { onSelect(.accruals) }) {
                        BarItem(title: "Accruals", systemImage: "doc.text", selected: selected == .accruals)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button(action: { onSelect(.history) }) {
                        BarItem(title: "History", systemImage: "clock", selected: selected == .history)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button(action: { onSelect(.reports) }) {
                        BarItem(title: "Reports", systemImage: "chart.bar", selected: selected == .reports)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Spacer(minLength: 6)
                
                Button(action: { onSelect(.preferences) }) {
                    VStack(spacing: 4) {
                        ProfileAvatarWithGear(selected: selected == .preferences)
                        Text("Profile")
                            .font(.caption2)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .minimumScaleFactor(0.7)
                            .allowsTightening(false)
                    }
                    .foregroundColor(selected == .preferences ? .accentColor : unselectedColor)
                    .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                colorScheme == .dark ? AnyShapeStyle(Color.black) : AnyShapeStyle(.ultraThinMaterial)
            )
        }
    }
}

struct BarItem: View {
    let title: String
    let systemImage: String
    let selected: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    private var unselectedColor: Color { 
        colorScheme == .dark ? .white : .black 
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
            Text(title)
                .font(.caption2)
                .lineLimit(1)
                .truncationMode(.tail)
                .minimumScaleFactor(0.7)
                .allowsTightening(false)
        }
        .foregroundColor(selected ? .accentColor : unselectedColor)
        .padding(.vertical, 2)
    }
}