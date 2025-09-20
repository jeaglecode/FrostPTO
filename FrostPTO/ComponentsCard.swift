//
//  ComponentsCard.swift
//  FrostPTO
//
//  Created by Jesse Duenas on 9/17/25.
//

import SwiftUI

// MARK: - Basic Card Component
struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    
    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Expandable Card for Complex Data
struct ExpandableCard<Header: View, Details: View>: View {
    @ViewBuilder var header: Header
    @ViewBuilder var details: Details
    @State private var isExpanded = false
    
    let padding: CGFloat
    let cornerRadius: CGFloat
    
    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 16,
        @ViewBuilder header: () -> Header,
        @ViewBuilder details: () -> Details
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.header = header()
        self.details = details()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section - always visible
            VStack(alignment: .leading, spacing: 12) {
                header
                
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text(isExpanded ? "Hide Details" : "Show Details")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(padding)
            
            // Expandable details section
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.horizontal, padding)
                    
                    details
                        .padding(.horizontal, padding)
                        .padding(.bottom, padding)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Data Display Components for Accruals
struct DataRow: View {
    let label: String
    let value: String
    let valueColor: Color?
    let isEditable: Bool
    let onEdit: ((String) -> Void)?
    
    @State private var editingValue: String
    @State private var isEditing = false
    
    init(
        label: String,
        value: String,
        valueColor: Color? = nil,
        isEditable: Bool = false,
        onEdit: ((String) -> Void)? = nil
    ) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
        self.isEditable = isEditable
        self.onEdit = onEdit
        self._editingValue = State(initialValue: value)
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isEditable && isEditing {
                TextField("Value", text: $editingValue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                    .onSubmit {
                        onEdit?(editingValue)
                        isEditing = false
                    }
            } else {
                Text(value)
                    .font(.body.monospacedDigit())
                    .foregroundColor(valueColor ?? .primary)
                    .onTapGesture {
                        if isEditable {
                            editingValue = value
                            isEditing = true
                        }
                    }
            }
        }
    }
}

struct ChipList: View {
    let items: [String]
    let emptyText: String
    
    init(items: [String], emptyText: String = "—") {
        self.items = items
        self.emptyText = emptyText
    }
    
    var body: some View {
        if items.isEmpty {
            Text(emptyText)
                .foregroundColor(.secondary)
                .font(.caption)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                        .lineLimit(1)
                }
            }
        }
    }
}

// MARK: - Accrual Window Card
struct AccrualWindowCard: View {
    let window: AccrualWindow
    let onOverrideChange: (Double) -> Void
    let onManageEntries: () -> Void
    
    @State private var overrideValue: Double
    
    init(window: AccrualWindow, onOverrideChange: @escaping (Double) -> Void, onManageEntries: @escaping () -> Void) {
        self.window = window
        self.onOverrideChange = onOverrideChange
        self.onManageEntries = onManageEntries
        self._overrideValue = State(initialValue: window.accrualOverride)
    }
    
    private var dateRangeText: String {
        // Format dates to be more compact
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let startDate = ISO8601DateFormatter().date(from: window.start + "T00:00:00Z") ?? Date()
        let endDate = ISO8601DateFormatter().date(from: window.endDisplay + "T00:00:00Z") ?? Date()
        
        let startText = formatter.string(from: startDate)
        let endText = formatter.string(from: endDate)
        
        // Check if same year to avoid redundancy
        let calendar = Calendar.current
        let startYear = calendar.component(.year, from: startDate)
        let endYear = calendar.component(.year, from: endDate)
        let currentYear = calendar.component(.year, from: Date())
        
        if startYear == endYear && startYear == currentYear {
            return "\(startText) - \(endText)"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
    }
    
    var body: some View {
        ExpandableCard {
            // Header content
            VStack(alignment: .leading, spacing: 16) {
                // Top row - Window period and End Balance
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Window Period")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(dateRangeText)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    
                    Spacer(minLength: 16)
                    
                    VStack(alignment: .trailing, spacing: 6) {
                        HStack(spacing: 8) {
                            Text("End Balance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Image(systemName: window.endBalance >= 0 ? "checkmark.circle" : "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundColor(window.endBalance >= 0 ? .green : .orange)
                        }
                        
                        Text(String(format: "%.1f h", window.endBalance))
                            .font(.headline.monospacedDigit())
                            .fontWeight(.semibold)
                            .foregroundColor(window.endBalance >= 0 ? .green : .red)
                    }
                }
                
                // Bottom row - Key metrics in a grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 16) {
                    MetricCell(
                        title: "Accrual Date",
                        value: formatAccrualDate(window.accrualDate),
                        icon: "plus.circle",
                        color: .blue
                    )
                    
                    MetricCell(
                        title: "Start Balance",
                        value: String(format: "%.1f h", window.startBalance),
                        icon: "hourglass.bottomhalf.filled",
                        color: .secondary
                    )
                    
                    MetricCell(
                        title: "PTO Used",
                        value: String(format: "%.1f h", window.ptoUsed),
                        icon: "minus.circle",
                        color: window.ptoUsed > 0 ? .red : .secondary
                    )
                }
            }
            
        } details: {
            // Expandable details content
            VStack(alignment: .leading, spacing: 20) {
                // Entries section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "list.bullet")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("Entries in Window")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if !window.entries.isEmpty {
                            Spacer()
                            Text("\(window.entries.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    
                    ChipList(items: window.entries.map { entry in
                        "\(formatEntryDate(entry.date)): -\(String(format: "%.1f", entry.hours))h" + 
                        (entry.note.isEmpty ? "" : " — \(entry.note)")
                    }, emptyText: "No entries in this window")
                }
                
                Divider()
                
                // Accrual override section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text("Accrual Override")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Override Value")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            TextField("Hours", value: $overrideValue, format: .number.precision(.fractionLength(2)))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                                .onChange(of: overrideValue) { _, newValue in
                                    onOverrideChange(newValue)
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Computed")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(String(format: "%.1f h", window.computedAccrual))
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                        }
                        
                        Spacer()
                    }
                }
                
                // Action button
                Button(action: onManageEntries) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Manage Entries")
                    }
                    .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
        }
    }
    
    private func formatAccrualDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func formatEntryDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Metric Cell Component
struct MetricCell: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            Text(value)
                .font(.caption.monospacedDigit())
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Supporting Data Models
struct AccrualWindow {
    let start: String
    let endDisplay: String
    let accrualDate: String
    let startBalance: Double
    let ptoUsed: Double
    let computedAccrual: Double
    let accrualOverride: Double
    let endBalance: Double
    let entries: [PTOEntry]
    
    init(
        start: String,
        endDisplay: String,
        accrualDate: String,
        startBalance: Double,
        ptoUsed: Double,
        computedAccrual: Double,
        accrualOverride: Double,
        entries: [PTOEntry] = []
    ) {
        self.start = start
        self.endDisplay = endDisplay
        self.accrualDate = accrualDate
        self.startBalance = startBalance
        self.ptoUsed = ptoUsed
        self.computedAccrual = computedAccrual
        self.accrualOverride = accrualOverride
        self.endBalance = startBalance - ptoUsed + accrualOverride
        self.entries = entries
    }
}

struct PTOEntry {
    let date: String
    let hours: Double
    let note: String
    
    init(date: String, hours: Double, note: String = "") {
        self.date = date
        self.hours = hours
        self.note = note
    }
}

// MARK: - Accrual Window Generation
extension AccrualWindow {
    static func generateWindows(from settings: SettingsStore, for year: Int = Calendar.current.component(.year, from: Date())) -> [AccrualWindow] {
        let calendar = Calendar.current
        guard let yearStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let yearEnd = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) else {
            return []
        }
        
        var windows: [AccrualWindow] = []
        
        switch settings.mode {
        case .perYear:
            // For per-year mode, create one window for the entire year
            let window = AccrualWindow(
                start: formatDate(yearStart),
                endDisplay: formatDate(yearEnd),
                accrualDate: formatDate(yearEnd),
                startBalance: settings.startBal,
                ptoUsed: 0.0, // This would be calculated from actual PTO entries
                computedAccrual: settings.hoursPerYear,
                accrualOverride: settings.hoursPerYear,
                entries: [] // This would be loaded from data store
            )
            windows.append(window)
            
        case .perPeriod:
            // Generate windows based on the period
            windows = generatePeriodicWindows(
                from: yearStart,
                to: yearEnd,
                settings: settings
            )
        }
        
        return windows
    }
    
    private static func generatePeriodicWindows(from startDate: Date, to endDate: Date, settings: SettingsStore) -> [AccrualWindow] {
        let calendar = Calendar.current
        var windows: [AccrualWindow] = []
        var currentStart = startDate
        
        let periodDays = settings.period == .custom ? settings.customDays : settings.period.days
        
        switch settings.period {
        case .weekly, .biweekly, .custom:
            // Generate windows based on day intervals
            while currentStart < endDate {
                let currentEnd = calendar.date(byAdding: .day, value: periodDays, to: currentStart) ?? endDate
                let actualEnd = min(currentEnd, endDate)
                
                let window = AccrualWindow(
                    start: formatDate(currentStart),
                    endDisplay: formatDate(actualEnd),
                    accrualDate: formatDate(actualEnd),
                    startBalance: calculateStartBalance(for: currentStart, settings: settings),
                    ptoUsed: 0.0, // Would be calculated from actual entries
                    computedAccrual: settings.hoursPerPeriod,
                    accrualOverride: settings.hoursPerPeriod,
                    entries: [] // Would be loaded from data store
                )
                windows.append(window)
                
                currentStart = currentEnd
            }
            
        case .monthly:
            // Generate monthly windows
            var currentDate = startDate
            while currentDate < endDate {
                let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? endDate
                let actualEnd = min(nextMonth, endDate)
                
                let window = AccrualWindow(
                    start: formatDate(currentDate),
                    endDisplay: formatDate(actualEnd),
                    accrualDate: formatDate(actualEnd),
                    startBalance: calculateStartBalance(for: currentDate, settings: settings),
                    ptoUsed: 0.0,
                    computedAccrual: settings.hoursPerPeriod,
                    accrualOverride: settings.hoursPerPeriod,
                    entries: []
                )
                windows.append(window)
                
                currentDate = nextMonth
            }
            
        case .semimonthly:
            // Generate semi-monthly windows (15th and end of month)
            var currentDate = startDate
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            while currentDate < endDate {
                let year = calendar.component(.year, from: currentDate)
                let month = calendar.component(.month, from: currentDate)
                
                // First period: 1st to 15th
                if let fifteenth = calendar.date(from: DateComponents(year: year, month: month, day: 15)),
                   currentDate <= fifteenth && fifteenth <= endDate {
                    
                    let periodStart = max(currentDate, calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? currentDate)
                    
                    let window = AccrualWindow(
                        start: formatDate(periodStart),
                        endDisplay: formatDate(fifteenth),
                        accrualDate: formatDate(fifteenth),
                        startBalance: calculateStartBalance(for: periodStart, settings: settings),
                        ptoUsed: 0.0,
                        computedAccrual: settings.hoursPerPeriod,
                        accrualOverride: settings.hoursPerPeriod,
                        entries: []
                    )
                    windows.append(window)
                }
                
                // Second period: 16th to end of month
                let range = calendar.range(of: .day, in: .month, for: currentDate)
                let daysInMonth = range?.count ?? 31
                if let monthEnd = calendar.date(from: DateComponents(year: year, month: month, day: daysInMonth)),
                   let sixteenth = calendar.date(from: DateComponents(year: year, month: month, day: 16)),
                   sixteenth <= endDate {
                    
                    let actualEnd = min(monthEnd, endDate)
                    
                    let window = AccrualWindow(
                        start: formatDate(sixteenth),
                        endDisplay: formatDate(actualEnd),
                        accrualDate: formatDate(actualEnd),
                        startBalance: calculateStartBalance(for: sixteenth, settings: settings),
                        ptoUsed: 0.0,
                        computedAccrual: settings.hoursPerPeriod,
                        accrualOverride: settings.hoursPerPeriod,
                        entries: []
                    )
                    windows.append(window)
                }
                
                // Move to next month
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? endDate
            }
        }
        
        return windows
    }
    
    private static func calculateStartBalance(for date: Date, settings: SettingsStore) -> Double {
        // This is a simplified calculation - in a real app you'd calculate the actual balance
        // at the start of this period based on previous windows and PTO usage
        return settings.startBal
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}