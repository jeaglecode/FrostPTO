//
//  HomeView.swift
//  FrostPTO
//
//  Created by Jesse Duenas on 9/17/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var showPTOPreferences: Bool = false

    private static let numberFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 0
        return nf
    }()

    private var formattedBalance: String {
        let bal = settings.estimatedBalance()
        return Self.numberFormatter.string(from: NSNumber(value: bal)) ?? String(format: "%.2f", bal)
    }
    
    // Temporary debug info
    private var debugInfo: (balance: Double, startBal: Double, accrued: Double, days: Double) {
        let breakdown = settings.balanceBreakdown()
        let balance = settings.estimatedBalance()
        return (balance, breakdown.startBalance, breakdown.accruedHours, breakdown.daysPassed)
    }
    
    private var needsSetup: Bool {
        // Check if user needs to configure their PTO settings
        return settings.startBal == 0 && (
            (settings.mode == .perYear && settings.hoursPerYear == 0) ||
            (settings.mode == .perPeriod && settings.hoursPerPeriod == 0)
        )
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.accentColor.opacity(0.25), Color.clear], startPoint: .top, endPoint: .center)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hero header (condensed)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(formattedBalance)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Text("hours available")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 0)
                    
                    // Show setup prompt if needed
                    if needsSetup {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Setup Required")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            
                            Text("Configure your PTO settings to see your accurate balance.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button(action: { showPTOPreferences = true }) {
                                Label("Setup PTO", systemImage: "wrench.and.screwdriver")
                                    .font(.body.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal)
                    }
                    
                    // Debug info section (temporary)
                    if !needsSetup {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Debug Info")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            let debug = debugInfo
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Starting Balance: \(String(format: "%.6f", debug.startBal))")
                                Text("Accrued Hours: \(String(format: "%.6f", debug.accrued))")
                                Text("Days Since Start: \(String(format: "%.6f", debug.days))")
                                Text("Total Balance: \(String(format: "%.6f", debug.balance))")
                                Text("Mode: \(settings.mode == .perYear ? "Per Year (\(settings.hoursPerYear))" : "Per Period (\(settings.hoursPerPeriod))")")
                                Text("Start Date: \(settings.startDate, style: .date)")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showPTOPreferences) {
            NavigationStack {
                PTOPreferencesForm()
                    .environmentObject(settings)
            }
        }
    }
}