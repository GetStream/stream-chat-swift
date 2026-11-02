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
                        Button { page = max(0, current - 1) } label: { Image(systemName: "chevron.left") }
                            .disabled(current == 0)
                            .accessibilityLabel(Text(L10n.Pagination.previousPage))
                        Text(L10n.Pagination.position(current + 1, of: pages))
                            .font(theme.fonts.caption)
                            .monospacedDigit()
                            .foregroundStyle(theme.colors.textSecondary)
                        Button { page = min(pages - 1, current + 1) } label: { Image(systemName: "chevron.right") }
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
                            .padding(.vertical, theme.spacing.s + 2)
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
    @State private var rows: [[String: OpenUIValue]] = []
    @State private var baseline: [[String: OpenUIValue]] = []
    @State private var loadedSignature = ""

    private struct Column {
        let type: String
        let key: String
        let header: String
        let width: Double?
        let options: [(value: String, label: String)]
    }

    private var columns: [Column] {
        context.props.array("columns").compactMap(\.objectValue).map { column in
            Column(
                type: column["type"]?.stringValue ?? "text",
                key: column["key"]?.stringValue ?? "default",
                header: column["header"]?.stringValue ?? "",
                width: column["width"]?.numberValue,
                options: (column["options"]?.arrayValue ?? []).compactMap { option in
                    guard let value = option["value"]?.stringValue else { return nil }
                    return (value, option["label"]?.stringValue ?? value)
                }
            )
        }
    }

    private var tableName: String { context.props.text("name") ?? "" }

    var body: some View {
        let columns = self.columns
        let changed = changedCellCount(columns)
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            ScrollView(.horizontal, showsIndicators: false) {
                Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
                    GridRow {
                        ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                            Text(column.header)
                                .font(theme.fonts.caption.weight(.semibold))
                                .foregroundStyle(theme.colors.textSecondary)
                                .frame(width: CGFloat(column.width ?? 150), alignment: .leading)
                                .padding(.horizontal, theme.spacing.s)
                                .padding(.vertical, theme.spacing.s)
                        }
                    }
                    .background(theme.colors.subtleFill)
                    ForEach(rows.indices, id: \.self) { rowIndex in
                        Divider().gridCellUnsizedAxes(.horizontal)
                        GridRow {
                            ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                                editor(column, row: rowIndex)
                                    .frame(width: CGFloat(column.width ?? 150), alignment: .leading)
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
                HStack {
                    Text(L10n.EditableTable.changes(changed))
                        .font(theme.fonts.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                    Spacer()
                    Button(L10n.EditableTable.reset) { rows = baseline }
                        .buttonStyle(.bordered)
                    Button(L10n.EditableTable.save) { save(columns) }
                        .buttonStyle(.borderedProminent)
                }
                .controlSize(.small)
                .transition(.opacity)
            }
        }
        .disabled(context.isStreaming)
        .onAppear { load(columns) }
        .onChange(of: OpenUIJSON.stringify(context.props["data"]?.plainJSON ?? .null)) { _, _ in load(columns) }
    }

    @ViewBuilder
    private func editor(_ column: Column, row: Int) -> some View {
        let binding = Binding<String>(
            get: { row < rows.count ? rows[row][column.key].map { JS.isNullish($0) ? "" : JS.toString($0) } ?? "" : "" },
            set: { newValue in
                guard row < rows.count else { return }
                if column.type == "number" {
                    let number = JS.stringToNumber(newValue)
                    rows[row][column.key] = number.isNaN || newValue.isEmpty ? .string(newValue) : .number(number)
                } else {
                    rows[row][column.key] = .string(newValue)
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
                .padding(.vertical, 6)
        }
    }

    private func load(_ columns: [Column]) {
        let stored = context.runtime.fieldValue(formName: tableName, name: tableName)
        let source = (stored.map { JS.isNullish($0) } ?? true) ? context.props["data"] : stored
        let signature = OpenUIJSON.stringify(source?.plainJSON ?? .null)
        guard signature != loadedSignature else { return }
        loadedSignature = signature
        let parsed: [[String: OpenUIValue]] = (source?.arrayValue ?? []).map { row in
            var values: [String: OpenUIValue] = ["id": row["id"] ?? .string("")]
            let cells = row["values"]?.arrayValue ?? []
            for (index, column) in columns.enumerated() {
                values[column.key] = index < cells.count ? cells[index] : .string("")
            }
            return values
        }
        rows = parsed
        if baseline.isEmpty || !context.isStreaming { baseline = parsed }
    }

    private func changedCellCount(_ columns: [Column]) -> Int {
        var count = 0
        for (index, row) in rows.enumerated() where index < baseline.count {
            for column in columns where row[column.key] != baseline[index][column.key] {
                count += 1
            }
        }
        return count
    }

    private func save(_ columns: [Column]) {
        let data: [OpenUIValue] = rows.map { row in
            ["id": row["id"] ?? .string(""), "values": .array(columns.map { row[$0.key] ?? .string("") })]
        }
        context.runtime.setFieldValue(formName: tableName, componentType: "EditableTable", name: tableName, value: .array(data))
        context.trigger(label: L10n.EditableTable.save, formName: tableName)
        baseline = rows
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

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    static func date(from string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        if let date = formatter.date(from: String(string.prefix(10))) { return date }
        return ISO8601DateFormatter().date(from: string)
    }
}
