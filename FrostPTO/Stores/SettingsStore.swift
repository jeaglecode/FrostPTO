//
//  SettingsStore.swift
//  FrostPTO
//
//  Created by Jesse Duenas on 9/17/25.
//

import Foundation
import SwiftUI

class SettingsStore: ObservableObject {
    // Profile information
    @Published var employeeName: String = ""
    @Published var employeeID: String = ""
    @Published var department: String = ""
    @Published var manager: String = ""
    @Published var hireDate: Date = Date()
    
    // PTO Settings
    @Published var startBal: Double = 0.0 {
        didSet { defaults.set(startBal, forKey: Keys.startBal) }
    }
    @Published var startDate: Date = Date() {
        didSet { defaults.set(startDate.timeIntervalSince1970, forKey: Keys.startDate) }
    }
    @Published var mode: AccrualMode = .perYear {
        didSet { defaults.set(mode.rawValue, forKey: Keys.mode) }
    }
    @Published var hoursPerYear: Double = 120.0 {
        didSet { defaults.set(hoursPerYear, forKey: Keys.hoursPerYear) }
    }
    @Published var hoursPerPeriod: Double = 5.0 {
        didSet { defaults.set(hoursPerPeriod, forKey: Keys.hoursPerPeriod) }
    }
    @Published var period: Period = .biweekly {
        didSet { defaults.set(period.rawValue, forKey: Keys.period) }
    }
    @Published var customDays: Int = 14 {
        didSet { defaults.set(customDays, forKey: Keys.customDays) }
    }
    @Published var carryCap: Double? = nil {
        didSet {
            if let carryCap { defaults.set(carryCap, forKey: Keys.carryCap) }
            else { defaults.removeObject(forKey: Keys.carryCap) }
        }
    }
    @Published var carryReset: Date? = nil {
        didSet {
            if let carryReset { defaults.set(carryReset.timeIntervalSince1970, forKey: Keys.carryReset) }
            else { defaults.removeObject(forKey: Keys.carryReset) }
        }
    }
    @Published var notifications: Bool = true {
        didSet { defaults.set(notifications, forKey: Keys.notifications) }
    }
    @Published var useStartDateForAccruals: Bool = false {
        didSet { defaults.set(useStartDateForAccruals, forKey: Keys.useStartDateForAccruals) }
    }
    @Published var currentYear: Int = Calendar.current.component(.year, from: Date()) {
        didSet { defaults.set(currentYear, forKey: Keys.currentYear) }
    }
    
    enum AccrualMode: String, CaseIterable {
        case perYear = "perYear"
        case perPeriod = "perPeriod"
    }
    
    enum Period: String, CaseIterable, Identifiable {
        case weekly = "weekly"
        case biweekly = "biweekly"
        case semimonthly = "semimonthly"
        case monthly = "monthly"
        case custom = "custom"
        
        var id: String { rawValue }
        
        var label: String {
            switch self {
            case .weekly: return "Weekly"
            case .biweekly: return "Bi-weekly"
            case .semimonthly: return "Semi-monthly"
            case .monthly: return "Monthly"
            case .custom: return "Custom"
            }
        }
        
        var days: Int {
            switch self {
            case .weekly: return 7
            case .biweekly: return 14
            case .semimonthly: return 15 // approximate
            case .monthly: return 30 // approximate
            case .custom: return 1 // will be overridden
            }
        }
    }
    
    // MARK: - Init/Defaults
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Load persisted or defaults
        self.startBal = defaults.object(forKey: Keys.startBal) != nil ? defaults.double(forKey: Keys.startBal) : 0
        let sdInterval = defaults.double(forKey: Keys.startDate)
        self.startDate = defaults.object(forKey: Keys.startDate) != nil ? Date(timeIntervalSince1970: sdInterval) : Date()
        let modeRaw = defaults.string(forKey: Keys.mode) ?? AccrualMode.perYear.rawValue
        self.mode = AccrualMode(rawValue: modeRaw) ?? .perYear
        self.hoursPerYear = defaults.object(forKey: Keys.hoursPerYear) != nil ? defaults.double(forKey: Keys.hoursPerYear) : 120.0
        self.hoursPerPeriod = defaults.object(forKey: Keys.hoursPerPeriod) != nil ? defaults.double(forKey: Keys.hoursPerPeriod) : 5.0
        let periodRaw = defaults.string(forKey: Keys.period) ?? Period.biweekly.rawValue
        self.period = Period(rawValue: periodRaw) ?? .biweekly
        self.customDays = defaults.object(forKey: Keys.customDays) != nil ? defaults.integer(forKey: Keys.customDays) : 30
        if let capVal = defaults.object(forKey: Keys.carryCap) as? Double { self.carryCap = capVal } else { self.carryCap = nil }
        if let crInterval = defaults.object(forKey: Keys.carryReset) as? Double { self.carryReset = Date(timeIntervalSince1970: crInterval) } else { self.carryReset = nil }
        self.notifications = defaults.object(forKey: Keys.notifications) as? Bool ?? true
        self.useStartDateForAccruals = defaults.object(forKey: Keys.useStartDateForAccruals) as? Bool ?? false
        self.currentYear = defaults.object(forKey: Keys.currentYear) != nil ? defaults.integer(forKey: Keys.currentYear) : Calendar.current.component(.year, from: Date())
    }

    func estimatedBalance() -> Double {
        let now = Date()
        
        // Calculate days between start and now, matching Angular logic
        let calendar = Calendar.current
        let startOfStartDate = calendar.startOfDay(for: startDate)
        let startOfToday = calendar.startOfDay(for: now)
        
        // Use whole days only, matching Angular's Math.floor behavior
        let daysPassed = max(0, calendar.dateComponents([.day], from: startOfStartDate, to: startOfToday).day ?? 0)
        
        var accruedHours: Double = 0
        
        switch mode {
        case .perYear:
            // Match Angular: days + 1 for inclusive counting, and use 365 days per year
            let inclusiveDays = Double(daysPassed + 1)
            accruedHours = hoursPerYear / 365.0 * inclusiveDays
        case .perPeriod:
            // Ensure we never divide by zero for custom period
            let baseDays = period == .custom ? customDays : period.days
            let periodDays = max(1, baseDays)
            
            if period.rawValue == "semimonthly" {
                // Special handling for semi-monthly to match Angular
                accruedHours = hoursPerPeriod * Double(countSemiMonthlyPeriods(from: startOfStartDate, to: startOfToday))
            } else {
                let periodsElapsed = Double(daysPassed) / Double(periodDays)
                accruedHours = hoursPerPeriod * floor(periodsElapsed)
            }
        }
        
        return startBal + accruedHours
    }
    
    // Helper method to count semi-monthly periods (matching Angular logic)
    private func countSemiMonthlyPeriods(from start: Date, to end: Date) -> Int {
        let calendar = Calendar.current
        var count = 0
        
        var currentDate = start
        while currentDate <= end {
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            
            // 15th of the month
            if let fifteenth = calendar.date(from: DateComponents(year: year, month: month, day: 15)),
               fifteenth > start && fifteenth <= end {
                count += 1
            }
            
            // Last day of the month
            let range = calendar.range(of: .day, in: .month, for: currentDate)!
            if let lastDay = calendar.date(from: DateComponents(year: year, month: month, day: range.count)),
               lastDay > start && lastDay <= end {
                count += 1
            }
            
            // Move to next month
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? end.addingTimeInterval(86400)
            if currentDate > end { break }
        }
        
        return count
    }
    
    // Helper method for debugging balance calculations
    func balanceBreakdown() -> (startBalance: Double, accruedHours: Double, daysPassed: Double) {
        let now = Date()
        let secondsSinceStart = max(0, now.timeIntervalSince(startDate))
        let daysPassed = secondsSinceStart / 86400
        
        var accruedHours: Double = 0
        
        switch mode {
        case .perYear:
            let yearsElapsed = daysPassed / 365.25
            accruedHours = hoursPerYear * yearsElapsed
        case .perPeriod:
            let baseDays = period == .custom ? Double(customDays) : Double(period.days)
            let periodDays = max(1.0, baseDays)
            let periodsElapsed = daysPassed / periodDays
            accruedHours = hoursPerPeriod * periodsElapsed
        }
        
        return (startBal, accruedHours, daysPassed)
    }
    
    static func jan1(of date: Date) -> Date {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        return calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? date
    }
    
    // Keys
    private enum Keys {
        static let startBal = "settings.startBal"
        static let startDate = "settings.startDate"
        static let mode = "settings.mode"
        static let hoursPerYear = "settings.hoursPerYear"
        static let hoursPerPeriod = "settings.hoursPerPeriod"
        static let period = "settings.period"
        static let customDays = "settings.customDays"
        static let carryCap = "settings.carryCap"
        static let carryReset = "settings.carryReset"
        static let notifications = "settings.notifications"
        static let useStartDateForAccruals = "settings.useStartDateForAccruals"
        static let currentYear = "settings.currentYear"
    }
}

