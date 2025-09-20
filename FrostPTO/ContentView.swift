so when I toogle up it missed some of the record if I scrool down
//  ContentView.swift
//  FrostPTO
//
//  Created by Jesse Duenas on 9/17/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selected: Route = .planner
    @State private var isKeyboardVisible: Bool = false

    var body: some View {
        Group {
            switch selected {
            case .planner:
                NavigationStack {
                    HomeView()
                        .navigationTitle("PTO Planner")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text("PTO Planner")
                                    .font(.title2.weight(.semibold))
                            }
                        }
                }
                .id(Route.planner)

            case .accruals:
                NavigationStack {
                    AccrualsView()
                }
                .id(Route.accruals)

            case .history:
                NavigationStack {
                    HistoryView()
                }
                .id(Route.history)

            case .reports:
                NavigationStack {
                    ReportsView()
                }
                .id(Route.reports)

            case .preferences:
                NavigationStack {
                    PreferencesView()
                }
                .id(Route.preferences)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !isKeyboardVisible {
                BottomBar(
                    onSelect: { route in
                        // Switch tabs with no animations
                        withAnimation(.none) { selected = route }
                    },
                    selected: selected
                )
            }
        }
        .animation(nil, value: selected)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
    }
}

#Preview {
    RootView()
        .environmentObject(SettingsStore())
        .environmentObject(NavRouter())
}

#Preview("Dark Mode") {
    ContentView()
        .environmentObject(SettingsStore())
        .environmentObject(NavRouter())
        .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    ContentView()
        .environmentObject(SettingsStore())
        .environmentObject(NavRouter())
        .preferredColorScheme(.light)
}

#Preview("PreferencesView") {
    NavigationStack {
        PreferencesView()
            .environmentObject(SettingsStore())
    }
}

