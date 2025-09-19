//
//  RootView.swift
//  FrostPTO
//
//  Created by Jesse Duenas on 9/17/25.
//

import SwiftUI

struct RootView: View {
    @AppStorage("colorScheme") private var colorSchemeSetting: String = "system"

    private var preferredScheme: ColorScheme? {
        switch colorSchemeSetting {
        case "light": return .light
        case "dark": return .dark
        default: return nil // follow system
        }
    }

    var body: some View {
        ContentView()
            .preferredColorScheme(preferredScheme)
    }
}

#Preview {
    RootView()
        .environmentObject(SettingsStore())
}
