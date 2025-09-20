//
//  AccrualsView.swift
//  FrostPTO
//
//  Created by Jesse Duenas on 9/17/25.
//

import SwiftUI

struct AccrualsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var accrualWindows: [AccrualWindow] = []
    @State private var allCardsExpanded = false
    @State private var toggleCounter = 0  // Add counter to force updates
    
    private var displayYear: Int {
        let calendar = Calendar.current
        return settings.useStartDateForAccruals
            ? calendar.component(.year, from: settings.startDate)
            : settings.currentYear
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {  // Changed from LazyVStack to VStack
                if accrualWindows.isEmpty {
                    // Loading or empty state
                    Card {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            
                            Text("No Accrual Windows")
                                .font(.headline)
                            
                            Text("Accrual windows will appear here once data is loaded.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Generate Windows") {
                                generateAccrualWindows()
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .padding(.horizontal)
                } else {
                    // Accrual Window Cards
                    ForEach(Array(accrualWindows.enumerated()), id: \.offset) { index, window in
                        AccrualWindowCard(
                            window: window,
                            onOverrideChange: { newOverride in
                                updateOverride(at: index, newValue: newOverride)
                            },
                            onManageEntries: {
                                manageEntries(for: index)
                            },
                            isFirstWindow: index == 0,
                            forceExpanded: allCardsExpanded,
                            toggleCounter: toggleCounter  // Pass counter to force updates
                        )
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top)
            .padding(.bottom, 120) // Extra bottom padding to ensure last card is fully accessible
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture { dismissKeyboard() }
        .navigationTitle("Accruals " + String(displayYear))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Accruals " + String(displayYear))
                    .font(.title2.weight(.semibold))
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        allCardsExpanded.toggle()
                        toggleCounter += 1  // Increment counter to force all cards to update
                    }
                }) {
                    Image(systemName: allCardsExpanded ? "lightswitch.on" : "lightswitch.off")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
        }
        .refreshable {
            await refreshData()
        }
        .onAppear {
            generateAccrualWindows()
        }
        .onChange(of: settings.mode) { _, _ in
            generateAccrualWindows()
        }
        .onChange(of: settings.period) { _, _ in
            generateAccrualWindows()
        }
        .onChange(of: settings.hoursPerYear) { _, _ in
            generateAccrualWindows()
        }
        .onChange(of: settings.hoursPerPeriod) { _, _ in
            generateAccrualWindows()
        }
        .onChange(of: settings.customDays) { _, _ in
            generateAccrualWindows()
        }
        .onChange(of: settings.currentYear) { _, _ in
            generateAccrualWindows()
        }
        .onChange(of: settings.useStartDateForAccruals) { _, _ in
            generateAccrualWindows()
        }
        .onChange(of: settings.startDate) { _, _ in
            if settings.useStartDateForAccruals { generateAccrualWindows() }
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateAccrualWindows() {
        let calendar = Calendar.current
        let selectedYear: Int
        if settings.useStartDateForAccruals {
            selectedYear = calendar.component(.year, from: settings.startDate)
        } else {
            selectedYear = settings.currentYear
        }
        accrualWindows = AccrualWindow.generateWindows(from: settings, for: selectedYear)
    }
    
    private func getCurrentYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }
    
    private func updateOverride(at index: Int, newValue: Double) {
        guard index < accrualWindows.count else { return }
        
        // Create a new window with the updated override
        let oldWindow = accrualWindows[index]
        let newWindow = AccrualWindow(
            start: oldWindow.start,
            endDisplay: oldWindow.endDisplay,
            accrualDate: oldWindow.accrualDate,
            startBalance: oldWindow.startBalance,
            ptoUsed: oldWindow.ptoUsed,
            computedAccrual: oldWindow.computedAccrual,
            accrualOverride: newValue,
            entries: oldWindow.entries
        )
        
        accrualWindows[index] = newWindow
        
        // Here you would typically save to your data store
        print("Updated override for window \(index) to \(newValue)")
    }
    
    private func manageEntries(for index: Int) {
        // This would typically present a sheet or navigation to an entries management view
        print("Managing entries for window \(index)")
        
        // For now, just show an alert
        // In a real app, you'd present an entry management view
    }
    
    private func dismissKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
    
    private func refreshData() async {
        // Simulate network refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        // Regenerate windows with fresh settings
        await MainActor.run {
            generateAccrualWindows()
        }
    }
}

