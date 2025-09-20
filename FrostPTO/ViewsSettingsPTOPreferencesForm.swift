//
//  PTOPreferencesForm.swift
//  FrostPTO
//
//  Created by Jesse Duenas on 9/17/25.
//

import SwiftUI

struct PTOPreferencesForm: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("colorScheme") private var colorSchemeSetting: String = "system" // system | light | dark
    
    @State private var startBalText: String = ""
    @State private var hoursPerYearText: String = ""
    @State private var hoursPerPeriodText: String = ""
    @State private var carryCapText: String = ""
    @State private var enableYearEdit: Bool = false
    
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
    
    private static let ymdFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
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
                    
                    // Current Year Picker
                    Card {
                        HStack {
                            Text("Current year")
                                .font(.headline)
                            Text(String(settings.currentYear))
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        VStack(spacing: 12) {
                            Toggle(isOn: $enableYearEdit) {
                                Text("Edit year")
                            }
                            .toggleStyle(.switch)

                            let thisYear = Calendar.current.component(.year, from: Date())
                            let years = Array((thisYear - 5)...(thisYear + 5))

                            if enableYearEdit {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Select year")
                                    Picker("Current Year", selection: $settings.currentYear) {
                                        ForEach(years, id: \.self) { year in
                                            Text(String(year)).tag(year)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(maxHeight: 160)
                                    .clipped()
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }
                    }
                    
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
                            
                            HStack {
                                Text("Starting balance date")
                                Spacer()
                                Toggle(isOn: $settings.useStartDateForAccruals) {
                                    Text("Edit start date")
                                }
                                .labelsHidden()
                                .toggleStyle(.switch)
                            }

                            if settings.useStartDateForAccruals {
                                DatePicker("Starting balance date", selection: $settings.startDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                            } else {
                                // Read-only display of the current start date
                                Text(Self.ymdFormatter.string(from: settings.startDate))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
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
