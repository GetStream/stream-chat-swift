//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

// MARK: - Table

/// `Table(columns)` with `Col(label, data, type?)` — column-oriented, 10 rows per page.
@available(iOS 17.0, macOS 14.0, *)
struct TableView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme
    @State private var page = 0

    private static let pageSize = 10

    private struct Column {
        let label: String
        let data: [OpenUIValue]
        let isNumeric: Bool
    }

    var body: some View {
        let columns: [Column] = context.props.elements("columns").map { column in
            let props = ComponentProps(column.props)
            let data = props.array("data")
            let declaredNumeric = props.string("type") == "number"
            let looksNumeric = !data.isEmpty && data.allSatisfy { value in
                if case .number = value { return true }
                return value.isNull
            }
            return Column(label: props.text("label") ?? "", data: data, isNumeric: declaredNumeric || looksNumeric)
        }
        let rowCount = columns.map(\.data.count).max() ?? 0

        if context.runtime.isQueryLoading && rowCount == 0 {
            TableSkeleton(columns: max(columns.count, 3))
        } else if !columns.isEmpty {
            let pages = max(1, Int(ceil(Double(rowCount) / Double(Self.pageSize))))
            let current = min(page, pages - 1)
            let rows = Array(stride(from: current * Self.pageSize, to: min(rowCount, (current + 1) * Self.pageSize), by: 1))

            VStack(alignment: .trailing, spacing: theme.spacing.s) {
                // Full width when the table fits; horizontally scrollable otherwise.
                ViewThatFits(in: .horizontal) {
                    grid(columns: columns, rows: rows)
                    ScrollView(.horizontal, showsIndicators: false) {
                        grid(columns: columns, rows: rows)
                    }
                }
                if pages > 1 {
                    HStack(spacing: theme.spacing.s) {
                        Button { page = max(0, current - 1) } label: { Image(systemName: "chevron.backward") }
                            .disabled(current == 0)
                            .accessibilityLabel(Text(L10n.Pagination.previousPage))
                        Text(L10n.Pagination.position(current + 1, of: pages))
                            .font(theme.fonts.caption)
                            .monospacedDigit()
                            .foregroundStyle(theme.colors.textSecondary)
                            .accessibilityLabel(Text(L10n.Pagination.positionAccessibility(current + 1, of: pages)))
                        Button { page = min(pages - 1, current + 1) } label: { Image(systemName: "chevron.forward") }
                            .disabled(current >= pages - 1)
                            .accessibilityLabel(Text(L10n.Pagination.nextPage))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }

    private func grid(columns: [Column], rows: [Int]) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                    Text(column.label)
                        .font(theme.fonts.caption.weight(.semibold))
                        .foregroundStyle(theme.colors.textSecondary)
                        .textCase(.uppercase)
                        .frame(maxWidth: .infinity, alignment: column.isNumeric ? .trailing : .leading)
                        .padding(.horizontal, theme.spacing.m)
                        .padding(.vertical, theme.spacing.s)
                }
            }
            .background(theme.colors.subtleFill)
            ForEach(rows, id: \.self) { row in
                Divider().gridCellUnsizedAxes(.horizontal)
                GridRow {
                    ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                        cell(row < column.data.count ? column.data[row] : nil, numeric: column.isNumeric)
                            .frame(maxWidth: .infinity, alignment: column.isNumeric ? .trailing : .leading)
                            .padding(.horizontal, theme.spacing.m)
                            .padding(.vertical, theme.spacing.m)
                    }
                }
            }
        }
        .overlay(RoundedRectangle(cornerRadius: theme.radius.small, style: .continuous).stroke(theme.colors.border, lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.small, style: .continuous))
    }

    @ViewBuilder
    private func cell(_ value: OpenUIValue?, numeric: Bool) -> some View {
        switch value {
        case .element?, .array?:
            HStack(spacing: theme.spacing.xs) { context.render(value) }
        case let value? where !value.isNull:
            Text(JS.toString(value))
                .font(theme.fonts.bodySmall)
                .monospacedDigit(numeric)
                .foregroundStyle(theme.colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 260, alignment: numeric ? .trailing : .leading)
        default:
            Text("—")
                .font(theme.fonts.bodySmall)
                .foregroundStyle(theme.colors.textTertiary)
        }
    }
}

/// Placeholder rows shown while a query loads.
@available(iOS 17.0, macOS 14.0, *)
struct TableSkeleton: View {
    let columns: Int
    @Environment(\.openUITheme) private var theme
    @State private var pulse = false

    var body: some View {
        VStack(spacing: theme.spacing.s) {
            ForEach(0..<5, id: \.self) { _ in
                HStack(spacing: theme.spacing.m) {
                    ForEach(0..<columns, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 4).fill(theme.colors.sunkenSurface).frame(height: 14)
                    }
                }
            }
        }
        .opacity(pulse ? 0.5 : 1)
        .animation(.easeInOut(duration: 0.8).repeatForever(), value: pulse)
        .onAppear { pulse = true }
        .accessibilityLabel(Text(L10n.Table.loading))
    }
}

// MARK: - EditableTable

/// `EditableTable(name?, columns?, data?)` — inline editable cells, saved as a form field.
@available(iOS 17.0, macOS 14.0, *)
struct EditableTableView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme
    @State private var table = EditableTableRows()

    private struct Column {
        let type: String
        let key: String
        let header: String
        let width: CGFloat
        let options: [(value: String, label: String)]
    }

    private var columns: [Column] {
        context.props.array("columns").compactMap(\.objectValue).map { column in
            var values = Set<String>()
            return Column(
                type: column["type"]?.stringValue ?? "text",
                key: column["key"]?.stringValue ?? "default",
                header: column["header"]?.stringValue ?? "",
                width: clampedDimension(column["width"]?.numberValue, in: 40...600, default: 150),
                options: (column["options"]?.arrayValue ?? []).compactMap { option in
                    guard let value = option["value"]?.stringValue, values.insert(value).inserted else { return nil }
                    return (value, option["label"]?.stringValue ?? value)
                }
            )
        }
    }

    private var tableName: String { context.props.text("name") ?? "" }

    var body: some View {
        let columns = self.columns
        let keys = columns.map(\.key)
        let changed = table.changedCellCount(keys: keys)
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            ScrollView(.horizontal, showsIndicators: false) {
                Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
                    GridRow {
                        ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                            Text(column.header)
                                .font(theme.fonts.caption.weight(.semibold))
                                .foregroundStyle(theme.colors.textSecondary)
                                .frame(width: column.width, alignment: .leading)
                                .padding(.horizontal, theme.spacing.s)
                                .padding(.vertical, theme.spacing.s)
                        }
                    }
                    .background(theme.colors.subtleFill)
                    ForEach(table.rows.indices, id: \.self) { rowIndex in
                        Divider().gridCellUnsizedAxes(.horizontal)
                        GridRow {
                            ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                                editor(column, row: rowIndex)
                                    .frame(width: column.width, alignment: .leading)
                                    .padding(.horizontal, theme.spacing.s)
                                    .padding(.vertical, theme.spacing.xs)
                            }
                        }
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: theme.radius.small).stroke(theme.colors.border, lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.small))
            }
            if changed > 0 {
                HStack(spacing: theme.spacing.s) {
                    Text(L10n.EditableTable.changes(changed))
                        .font(theme.fonts.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                    Spacer()
                    Button(L10n.EditableTable.reset) { table.reset() }
                        .buttonStyle(.bordered)
                    Button(L10n.EditableTable.save) { save(columns) }
                        .buttonStyle(.borderedProminent)
                }
                .controlSize(.small)
                .transition(.opacity)
            }
        }
        .disabled(context.isStreaming)
        .onAppear { load(keys) }
        .onChange(of: context.props["data"]) { _, _ in load(keys) }
        .onChange(of: context.isStreaming) { _, _ in load(keys) }
    }

    @ViewBuilder
    private func editor(_ column: Column, row: Int) -> some View {
        let binding = Binding<String>(
            get: { row < table.rows.count ? table.rows[row][column.key].map { JS.isNullish($0) ? "" : JS.toString($0) } ?? "" : "" },
            set: { newValue in
                guard row < table.rows.count else { return }
                if column.type == "number" {
                    let number = JS.stringToNumber(newValue)
                    table.rows[row][column.key] = number.isNaN || newValue.isEmpty ? .string(newValue) : .number(number)
                } else {
                    table.rows[row][column.key] = .string(newValue)
                }
            }
        )
        switch column.type {
        case "select":
            Picker(column.header, selection: binding) {
                ForEach(column.options, id: \.value) { option in
                    Text(option.label).tag(option.value)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
        case "date-single":
            DatePicker(
                column.header,
                selection: Binding(
                    get: { DateFormatting.date(from: binding.wrappedValue) ?? Date() },
                    set: { binding.wrappedValue = DateFormatting.string(from: $0) }
                ),
                displayedComponents: .date
            )
            .labelsHidden()
        default:
            TextField(column.header, text: binding)
                .font(theme.fonts.bodySmall)
            #if os(iOS)
                .keyboardType(column.type == "number" ? .decimalPad : column.type == "url" ? .URL : .default)
                .textInputAutocapitalization(column.type == "url" ? .never : .sentences)
            #endif
                .padding(.vertical, theme.spacing.s)
        }
    }

    private func load(_ keys: [String]) {
        let stored = context.runtime.fieldValue(formName: tableName, name: tableName)
        let source = (stored.map { JS.isNullish($0) } ?? true) ? context.props["data"] : stored
        table.load(source, keys: keys, isStreaming: context.isStreaming)
    }

    private func save(_ columns: [Column]) {
        let keys = columns.map(\.key)
        context.runtime.setFieldValue(formName: tableName, componentType: "EditableTable", name: tableName, value: table.data(keys: keys))
        context.trigger(label: L10n.EditableTable.save, formName: tableName)
        table.markSaved()
    }
}

// The edited rows of an `EditableTable`, and the rows they are compared with to count changes.
// The comparison starts only once the model has finished writing the table, as partial rows
// would otherwise count as edits, and starts again from rows that arrive after that, or that a
// later stream wrote.
@available(iOS 17.0, macOS 14.0, *)
struct EditableTableRows {
    var rows: [[String: OpenUIValue]] = []
    private(set) var baseline: [[String: OpenUIValue]]?
    private var loadedSource: OpenUIValue?
    private var loadedKeys: [String] = []
    private var loadedWhileStreaming = false

    mutating func load(_ source: OpenUIValue?, keys: [String], isStreaming: Bool) {
        if source != loadedSource || keys != loadedKeys {
            loadedSource = source
            loadedKeys = keys
            rows = Self.rows(from: source, keys: keys)
            loadedWhileStreaming = isStreaming
            if !isStreaming { baseline = rows }
        }
        if baseline == nil || loadedWhileStreaming, !isStreaming {
            baseline = rows
            loadedWhileStreaming = false
        }
    }

    func changedCellCount(keys: [String]) -> Int {
        guard let baseline else { return 0 }
        var count = 0
        for (index, row) in rows.enumerated() where index < baseline.count {
            for key in keys where row[key] != baseline[index][key] {
                count += 1
            }
        }
        return count
    }

    mutating func reset() {
        if let baseline { rows = baseline }
    }

    mutating func markSaved() {
        baseline = rows
    }

    func data(keys: [String]) -> OpenUIValue {
        .array(rows.map { row in
            ["id": row["id"] ?? .string(""), "values": .array(keys.map { row[$0] ?? .string("") })]
        })
    }

    static func rows(from source: OpenUIValue?, keys: [String]) -> [[String: OpenUIValue]] {
        (source?.arrayValue ?? []).map { row in
            var values: [String: OpenUIValue] = ["id": row["id"] ?? .string("")]
            let cells = row["values"]?.arrayValue ?? []
            for (index, key) in keys.enumerated() {
                values[key] = index < cells.count ? cells[index] : .string("")
            }
            return values
        }
    }
}

/// `yyyy-MM-dd` date strings used by date fields.
@available(iOS 17.0, macOS 14.0, *)
enum DateFormatting {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    // The ISO 8601 dates and times JavaScript's `Date` reads: a day, then optionally a time to the
    // minute, second or fraction of one, and an offset. Before the time, V8 also takes a space,
    // as RFC 3339 allows.
    private static let dateTime: NSRegularExpression = {
        let pattern = #"^([0-9]{4})-([0-9]{2})-([0-9]{2})(?:[Tt ]([0-9]{2}):([0-9]{2})(?::([0-9]{2})(?:\.([0-9]+))?)?([Zz]|[+-][0-9]{2}:?[0-9]{2})?)?\z"#
        do {
            return try NSRegularExpression(pattern: pattern)
        } catch {
            preconditionFailure("Invalid pattern \(pattern): \(error)")
        }
    }()

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    // A time without an offset is one where the person is, as in JavaScript. A day without a time
    // is noon of it where the person is, which daylight saving never skips, rather than midnight
    // in UTC, which is the day before west of it. A day past the month's end isn't one, where
    // JavaScript rolls it over into the next month.
    static func date(from string: String?) -> Date? {
        guard let string, let match = dateTime.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) else { return nil }
        func part(_ index: Int) -> Substring? {
            Range(match.range(at: index), in: string).map { string[$0] }
        }
        func number(_ index: Int) -> Int? {
            part(index).flatMap { Int($0) }
        }
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0) ?? utc.timeZone
        var components = DateComponents(year: number(1), month: number(2), day: number(3), hour: 12)
        if let hour = number(4) {
            components.hour = hour
            components.minute = number(5)
            components.second = number(6) ?? 0
        }
        guard components.isValidDate(in: utc) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        if let offset = part(8) {
            guard let zone = timeZone(offset) else { return nil }
            calendar.timeZone = zone
        }
        guard let date = calendar.date(from: components) else { return nil }
        // JavaScript keeps milliseconds.
        let fraction = part(7).flatMap { Double("0." + $0) } ?? 0
        return date.addingTimeInterval((fraction * 1000).rounded(.down) / 1000)
    }

    private static func timeZone(_ offset: Substring) -> TimeZone? {
        guard offset.uppercased() != "Z" else { return TimeZone(secondsFromGMT: 0) }
        let digits = offset.dropFirst().filter { $0 != ":" }
        guard let hours = Int(digits.prefix(2)), let minutes = Int(digits.suffix(2)), hours < 24, minutes < 60 else { return nil }
        let seconds = (hours * 60 + minutes) * 60
        return TimeZone(secondsFromGMT: offset.hasPrefix("-") ? -seconds : seconds)
    }
}
