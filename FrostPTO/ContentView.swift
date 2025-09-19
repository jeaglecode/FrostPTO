//
//  ContentView.swift
//  FrostPTO
//
//  Created by Jesse Duenas on 9/17/25.
//

import SwiftUI

// Simple navigation router to control the stack path from child views
final class NavRouter: ObservableObject {
    @Published fileprivate var path: [Route] = []
}

struct ContentView: View {
    @State private var selected: Route = .planner

    var body: some View {
        Group {
            switch selected {
            case .planner:
                NavigationStack {
                    SettingsPanelView()
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

            case .requests:
                NavigationStack {
                    PlaceholderPage(title: "Requests", systemImage: "doc.text")
                }
                .id(Route.requests)

            case .history:
                NavigationStack {
                    PlaceholderPage(title: "History", systemImage: "clock")
                }
                .id(Route.history)

            case .reports:
                NavigationStack {
                    PlaceholderPage(title: "Reports", systemImage: "chart.bar")
                }
                .id(Route.reports)

            case .preferences:
                NavigationStack {
                    PreferencesView()
                }
                .id(Route.preferences)
            }
        }
        .safeAreaInset(edge: .bottom, content: {
            BottomBar(
                onSelect: { route in
                    // Switch tabs with no animations
                    withAnimation(.none) { selected = route }
                },
                selected: selected
            )
        })
        .animation(nil, value: selected)
    }
}

enum Route: Hashable {
    case planner
    case requests
    case history
    case reports
    case preferences
}

struct SettingsPanelView: View {
    @EnvironmentObject private var settings: SettingsStore

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

                    Spacer(minLength: 24)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
    }
}

struct PTOPreferencesForm: View {
    @EnvironmentObject private var settings: SettingsStore

    @AppStorage("colorScheme") private var colorSchemeSetting: String = "system" // system | light | dark

    // Binding String <-> Optional Double for carryCap
    private var carryCapTextBinding: Binding<String> {
        Binding<String>(
            get: {
                if let cap = settings.carryCap { return Self.numberFormatter.string(from: NSNumber(value: cap)) ?? String(cap) }
                return ""
            },
            set: { newVal in
                let trimmed = newVal.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty { settings.carryCap = nil; return }
                if let num = Self.numberFormatter.number(from: trimmed)?.doubleValue {
                    settings.carryCap = num
                }
            }
        )
    }

    private var useDefaultCarryResetBinding: Binding<Bool> {
        Binding<Bool>(
            get: { settings.carryReset == nil },
            set: { useDefault in
                if useDefault { settings.carryReset = nil }
                else { settings.carryReset = SettingsStore.jan1(of: Date()) }
            }
        )
    }

    private static let numberFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 0
        return nf
    }()

    private static let integerFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .none
        nf.allowsFloats = false
        nf.maximumFractionDigits = 0
        nf.minimumFractionDigits = 0
        return nf
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
           
                Card {
                    Text("Starting balance")
                        .font(.headline)
                    VStack(spacing: 12) {
                        HStack {
                            Text("Hours")
                            Spacer()
                            TextField("0", value: $settings.startBal, formatter: Self.numberFormatter)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 160)
                        }
                        DatePicker("Starting balance date", selection: $settings.startDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                }

                // Accrual Card
                Card {
                    Text("Accrual")
                        .font(.headline)
                    VStack(spacing: 12) {
                        Picker("Mode", selection: $settings.mode) {
                            Text("Per year").tag(SettingsStore.AccrualMode.perYear)
                            Text("Per period").tag(SettingsStore.AccrualMode.perPeriod)
                        }
                        .pickerStyle(.segmented)

                        if settings.mode == .perYear {
                            HStack {
                                Text("Hours per year")
                                Spacer()
                                TextField("0", value: $settings.hoursPerYear, formatter: Self.numberFormatter)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 160)
                            }
                        }

                        if settings.mode == .perPeriod {
                            HStack {
                                Text("Hours per event")
                                Spacer()
                                TextField("0", value: $settings.hoursPerPeriod, formatter: Self.numberFormatter)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 160)
                            }

                            HStack {
                                Text("Period")
                                Spacer()
                                Picker("Period", selection: $settings.period) {
                                    ForEach(SettingsStore.Period.allCases) { p in
                                        Text(p.label).tag(p)
                                    }
                                }
                                .pickerStyle(.menu)
                            }

                            if settings.period == .custom {
                                HStack {
                                    Text("Custom days")
                                    Spacer()
                                    TextField("days", value: $settings.customDays, formatter: Self.integerFormatter)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: 160)
                                }
                            }

                            Text("For semi-monthly, enter hours per event.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Carryover Card
                Card {
                    Text("Carryover")
                        .font(.headline)
                    VStack(spacing: 12) {
                        HStack {
                            Text("Cap (hours)")
                            Spacer()
                            TextField("optional", text: carryCapTextBinding)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 160)
                        }

                        Toggle("Use default Jan 1 reset", isOn: useDefaultCarryResetBinding)

                        if settings.carryReset != nil {
                            DatePicker("Carryover reset date", selection: Binding<Date>(
                                get: { settings.carryReset ?? SettingsStore.jan1(of: Date()) },
                                set: { settings.carryReset = $0 }
                            ), displayedComponents: .date)
                            .datePickerStyle(.compact)
                        }
                    }
                }
                
                Spacer(minLength: 24)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .navigationTitle("PTO Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// Bottom bar with 4 placeholder icons on the left and profile/settings on the right
private struct BottomBar: View {
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

                    Button(action: { onSelect(.requests) }) {
                        BarItem(title: "Requests", systemImage: "doc.text", selected: selected == .requests)
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

private struct BarItem: View {
    let title: String
    let systemImage: String
    let selected: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var unselectedColor: Color { colorScheme == .dark ? .white : .black }

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
            Text(title)
                .font(.caption2)
        }
        .foregroundColor(selected ? .accentColor : unselectedColor)
        .padding(.vertical, 2)
    }
}

private struct PlaceholderPage: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("\(title) — coming soon")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(title)
                    .font(.title2.weight(.semibold))
            }
        }
    }
}

private struct PreferencesView: View {
    @EnvironmentObject private var settings: SettingsStore
    @AppStorage("colorScheme") private var colorSchemeSetting: String = "system"
    @State private var showPTOPreferences = false

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
                .sheet(isPresented: $showPTOPreferences) {
                    ZStack(alignment: .top) {
                        NavigationStack {
                            PTOPreferencesForm()
                                .environmentObject(settings)
                        }
                        Capsule()
                            .fill(Color.secondary.opacity(0.4))
                            .frame(width: 60, height: 8)
                            .padding(.top, 8)
                    }
                }

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
    }
}

// New Profile Edit View
private struct ProfileEditView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                HStack {
                    Text("Name")
                    Spacer()
                    TextField("Full Name", text: $settings.employeeName)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Employee ID")
                    Spacer()
                    TextField("ID", text: $settings.employeeID)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Department")
                    Spacer()
                    TextField("Department", text: $settings.department)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Manager")
                    Spacer()
                    TextField("Manager Name", text: $settings.manager)
                        .multilineTextAlignment(.trailing)
                }

                DatePicker("Hire Date", selection: $settings.hireDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

private struct ProfileAvatarWithGear: View {
    let selected: Bool
    @Environment(\.colorScheme) private var colorScheme
    private var unselectedColor: Color { colorScheme == .dark ? .white : .black }

    var body: some View {
        ZStack {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(selected ? .accentColor : unselectedColor)

            Image(systemName: "gearshape.fill")
                .font(.system(size: 8))
                .foregroundColor(.white)
                .background(
                    Circle()
                        .fill(selected ? Color.accentColor : (colorScheme == .dark ? Color.black : Color.black))
                        .frame(width: 12, height: 12)
                )
                .offset(x: 8, y: 8)
        }
    }
}

#Preview {
    RootView()
        .environmentObject(SettingsStore())
        .environmentObject(NavRouter())
}

#Preview("PreferencesView") {
    NavigationStack {
        PreferencesView()
            .environmentObject(SettingsStore())
    }
}
