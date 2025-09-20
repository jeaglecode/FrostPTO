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

enum Route: Hashable {
    case planner
    case requests
    case history
    case reports
    case preferences
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
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("colorScheme") private var colorSchemeSetting: String = "system" // system | light | dark
    
    @State private var startBalText: String = ""
    @State private var hoursPerYearText: String = ""
    @State private var hoursPerPeriodText: String = ""
    @State private var carryCapText: String = ""
    
    private enum FocusedField: Hashable {
        case startBal, hoursPerYear, hoursPerPeriod, carryCap, customDays
    }
    
    @FocusState private var focusedField: FocusedField?
    

    
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
    
    // Sanitize input to allow only digits and a single '.' as decimal separator
    private func sanitizeDotOnly(_ input: String) -> String {
        var result = ""
        var seenDot = false
        for ch in input {
            if ch.isNumber {
                result.append(ch)
            } else if ch == "." && !seenDot {
                result.append(ch)
                seenDot = true
            }
        }
        return result
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("PTO Preferences")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                    
                    Card {
                        Text("Starting balance")
                            .font(.headline)
                        VStack(spacing: 12) {
                            HStack {
                                Text("Hours")
                                Spacer()
                                TextField("0", text: $startBalText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .startBal)
                                    .frame(maxWidth: 160)
                                    .onChange(of: startBalText) { newVal in
                                        let sanitized = sanitizeDotOnly(newVal)
                                        if sanitized != newVal { startBalText = sanitized }
                                        if let val = Double(sanitized) { settings.startBal = val }
                                    }
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
                                    TextField("0", text: $hoursPerYearText)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($focusedField, equals: .hoursPerYear)
                                        .frame(maxWidth: 160)
                                        .onChange(of: hoursPerYearText) { newVal in
                                            let sanitized = sanitizeDotOnly(newVal)
                                            if sanitized != newVal { hoursPerYearText = sanitized }
                                            if let val = Double(sanitized) { settings.hoursPerYear = val }
                                        }
                                }
                            }
                            
                            if settings.mode == .perPeriod {
                                HStack {
                                    Text("Hours per event")
                                    Spacer()
                                    TextField("0", text: $hoursPerPeriodText)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($focusedField, equals: .hoursPerPeriod)
                                        .frame(maxWidth: 160)
                                        .onChange(of: hoursPerPeriodText) { newVal in
                                            let sanitized = sanitizeDotOnly(newVal)
                                            if sanitized != newVal { hoursPerPeriodText = sanitized }
                                            if let val = Double(sanitized) { settings.hoursPerPeriod = val }
                                        }
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
                                            .focused($focusedField, equals: .customDays)
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
                                TextField("optional", text: $carryCapText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .carryCap)
                                    .frame(maxWidth: 160)
                                    .onChange(of: carryCapText) { newVal in
                                        let sanitized = sanitizeDotOnly(newVal)
                                        if sanitized != newVal { carryCapText = sanitized }
                                        if sanitized.isEmpty {
                                            settings.carryCap = nil
                                        } else if let num = Double(sanitized) {
                                            settings.carryCap = num
                                        }
                                    }
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
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = nil
            }
            .safeAreaPadding(.top, 12)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                startBalText = settings.startBal == 0 ? "" : String(settings.startBal)
                hoursPerYearText = settings.hoursPerYear == 0 ? "" : String(settings.hoursPerYear)
                hoursPerPeriodText = settings.hoursPerPeriod == 0 ? "" : String(settings.hoursPerPeriod)
                carryCapText = settings.carryCap == nil ? "" : String(settings.carryCap!)
            }
        }
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// Bottom bar with 4 placeholder icons on the left and profile/settings on the right
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
    
    private var unselectedColor: Color { colorScheme == .dark ? .white : .black }
    
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

struct PlaceholderPage: View {
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

// New Profile Edit View
struct ProfileEditView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    
    @FocusState private var isAnyFieldFocused: Bool
    
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
                        .keyboardType(.numberPad)
                        .focused($isAnyFieldFocused)
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
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isAnyFieldFocused = false
                }
            }
        }
    }
}

struct ProfileAvatarWithGear: View {
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
    ContentView()
        .environmentObject(SettingsStore())
        .environmentObject(NavRouter())
}

#Preview("PreferencesView") {
    NavigationStack {
        PreferencesView()
            .environmentObject(SettingsStore())
    }
}
