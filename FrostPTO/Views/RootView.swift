//
//  RootView.swift
//  FrostPTO
//
//  Created by Jesse Duenas on 9/17/25.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        ContentView()
    }
}

#Preview {
    RootView()
        .environmentObject(SettingsStore())
}
