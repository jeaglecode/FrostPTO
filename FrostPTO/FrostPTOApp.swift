//
//  FrostPTOApp.swift
//  FrostPTO
//
//  Created by Jesse Duenas on 9/17/25.
//

import SwiftUI

@main
struct FrostPTOApp: App {
    // Shared settings store for the whole app
    @StateObject private var settingsStore = SettingsStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settingsStore)
        }
    }
}
