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
    let isFirstWindow: Bool
    
    @State private var overrideValue: Double
    
    init(window: AccrualWindow, onOverrideChange: @escaping (Double) -> Void, onManageEntries: @escaping () -> Void, isFirstWindow: Bool = false) {
        self.window = window
        self.onOverrideChange = onOverrideChange
        self.onManageEntries = onManageEntries
        self.isFirstWindow = isFirstWindow
        self._overrideValue = State(initialValue: window.accrualOverride)
    }
    
    private var dateRangeText: String {
        // Format dates to be more compact
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        // Parse the date strings directly
        guard let startDate = formatter.date(from: window.start),
              let endDate = formatter.date(from: window.endDisplay) else {
            // Fallback if parsing fails
            return "\(window.start) - \(window.endDisplay)"
        }
        
        // Check if same year to avoid redundancy
        let calendar = Calendar.current
        let startYear = calendar.component(.year, from: startDate)
        let endYear = calendar.component(.year, from: endDate)
        let currentYear = calendar.component(.year, from: Date())
        
        // For the first window OR if years are different from current year, show years
        if isFirstWindow || startYear != currentYear || endYear != currentYear || startYear != endYear {
            // Show with 2-digit year
            formatter.dateFormat = "MMM d, yy"
            let startText = formatter.string(from: startDate)
            let endText = formatter.string(from: endDate)
            return "\(startText) - \(endText)"
        } else {
            // Show without year for current year windows (except first)
            formatter.dateFormat = "MMM d"
            let startText = formatter.string(from: startDate)
            let endText = formatter.string(from: endDate)
            return "\(startText) - \(endText)"
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
        var windows: [AccrualWindow] = []
        
        // Determine which year to use based on the useStartDateForAccruals setting
        let targetYear: Int
        if settings.useStartDateForAccruals {
            // Use the year from the start date or the requested year, whichever is appropriate
            let startYear = calendar.component(.year, from: settings.startDate)
            targetYear = year
        } else {
            // Use the requested year (which should be currentYear from settings)
            targetYear = year
        }
        
        // Get the start date from settings
        let startDate = settings.startDate
        let startYear = calendar.component(.year, from: startDate)
        
        switch settings.mode {
        case .perYear:
            // For per-year mode, create one window for the entire year
            let windowStartDate: Date
            
            if settings.useStartDateForAccruals {
                // Use the actual start date from settings
                if startYear == targetYear {
                    windowStartDate = startDate
                } else if startYear < targetYear {
                    // Start date is before requested year, start from Jan 1 of requested year
                    windowStartDate = calendar.date(from: DateComponents(year: targetYear, month: 1, day: 1)) ?? startDate
                } else {
                    // Start date is after requested year, return empty
                    return []
                }
            } else {
                // Start from December 31st of previous year
                windowStartDate = calendar.date(from: DateComponents(year: targetYear - 1, month: 12, day: 31)) ?? 
                    calendar.date(from: DateComponents(year: targetYear, month: 1, day: 1))!
            }
            
            guard let yearEnd = calendar.date(from: DateComponents(year: targetYear, month: 12, day: 31)) else {
                return []
            }
            
            let window = AccrualWindow(
                start: formatDate(windowStartDate),
                endDisplay: formatDate(yearEnd),
                accrualDate: formatDate(yearEnd),
                startBalance: settings.startBal,
                ptoUsed: 0.0,
                computedAccrual: settings.hoursPerYear,
                accrualOverride: settings.hoursPerYear,
                entries: []
            )
            windows.append(window)
            
        case .perPeriod:
            // Generate accrual windows based on 15th and last day of each month
            // Starting from the settings start date or December 31st based on toggle
            windows = generateAccrualWindows(for: targetYear, settings: settings)
        }
        
        return windows
    }
    
    private static func generateAccrualWindows(for year: Int, settings: SettingsStore) -> [AccrualWindow] {
        let calendar = Calendar.current
        var windows: [AccrualWindow] = []
        
        // Determine the window start date based on the useStartDateForAccruals setting
        var windowStart: Date
        
        if settings.useStartDateForAccruals {
            // Use the actual start date from settings
            let startDate = settings.startDate
            let startYear = calendar.component(.year, from: startDate)
            
            if startYear > year {
                // Start date is after requested year, return empty
                return []
            } else if startYear == year {
                // Start date is in the requested year, use it
                windowStart = startDate
            } else {
                // Start date is before the requested year, start from Jan 1 of requested year
                windowStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? settings.startDate
            }
        } else {
            // Start from December 31st of the previous year
            windowStart = calendar.date(from: DateComponents(year: year - 1, month: 12, day: 31)) ?? 
                calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        }
        
        // Generate windows starting from the determined start point
        for month in 1...12 {
            // First accrual: 15th of the month
            if let fifteenth = calendar.date(from: DateComponents(year: year, month: month, day: 15)) {
                let window = AccrualWindow(
                    start: formatDate(windowStart),
                    endDisplay: formatDate(fifteenth),
                    accrualDate: formatDate(fifteenth),
                    startBalance: calculateStartBalance(for: windowStart, settings: settings),
                    ptoUsed: 0.0,
                    computedAccrual: settings.hoursPerPeriod,
                    accrualOverride: settings.hoursPerPeriod,
                    entries: []
                )
                windows.append(window)
                windowStart = fifteenth
            }
            
            // Second accrual: Last day of the month
            let range = calendar.range(of: .day, in: .month, for: calendar.date(from: DateComponents(year: year, month: month, day: 1))!)
            let lastDay = range?.count ?? 31
            
            if let monthEnd = calendar.date(from: DateComponents(year: year, month: month, day: lastDay)) {
                let window = AccrualWindow(
                    start: formatDate(windowStart),
                    endDisplay: formatDate(monthEnd),
                    accrualDate: formatDate(monthEnd),
                    startBalance: calculateStartBalance(for: windowStart, settings: settings),
                    ptoUsed: 0.0,
                    computedAccrual: settings.hoursPerPeriod,
                    accrualOverride: settings.hoursPerPeriod,
                    entries: []
                )
                windows.append(window)
                windowStart = monthEnd
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