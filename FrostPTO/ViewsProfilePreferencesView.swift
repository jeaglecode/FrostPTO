//
//  PreferencesView.swift
//  FrostPTO
//
//  Created by Jesse Duenas on 9/17/25.
//

import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject private var settings: SettingsStore
    @AppStorage("colorScheme") private var colorSchemeSetting: String = "system"
    @State private var showPTOPreferences: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quick Action at top
                Button {
                    showPTOPreferences = true
                } label: {
                    Label("PTO Setup", systemImage: "wrench.and.screwdriver")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                // Profile Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Profile").font(.headline)
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 4) {
                            if settings.employeeName.isEmpty {
                                Text("Tap to add name").foregroundColor(.secondary)
                            } else {
                                Text(settings.employeeName).font(.headline)
                            }
                            if !settings.department.isEmpty {
                                Text(settings.department).font(.subheadline).foregroundColor(.secondary)
                            }
                            if !settings.employeeID.isEmpty {
                                Text("ID: \(settings.employeeID)").font(.caption).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    NavigationLink("Edit Profile") {
                        ProfileEditView().environmentObject(settings)
                    }
                }
                .padding(16)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                // Appearance
                VStack(alignment: .leading, spacing: 12) {
                    Text("Appearance").font(.headline)
                    Picker("Appearance", selection: $colorSchemeSetting) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }
                .padding(16)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                // Notifications
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notifications").font(.headline)
                    Toggle("Notifications", isOn: $settings.notifications)
                }
                .padding(16)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                Spacer(minLength: 8)
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Profile")
                    .font(.title2.weight(.semibold))
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