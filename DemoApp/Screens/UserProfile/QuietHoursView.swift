//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 15, *)
struct QuietHoursView: View {
    let onSave: (PushSchedule, @escaping (Result<PushPreference, Error>) -> Void) -> Void
    let onRemove: (@escaping (Result<PushPreference, Error>) -> Void) -> Void
    let onDismiss: () -> Void

    @State private var rules: [EditableRule]
    @State private var hasStoredSchedule: Bool
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let timezone = TimeZone.current
    private static let maxRules = 7

    init(
        initialSchedule: PushSchedule?,
        onSave: @escaping (PushSchedule, @escaping (Result<PushPreference, Error>) -> Void) -> Void,
        onRemove: @escaping (@escaping (Result<PushPreference, Error>) -> Void) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.onSave = onSave
        self.onRemove = onRemove
        self.onDismiss = onDismiss
        let rules = initialSchedule?.quietHours.map { EditableRule($0, in: .current) } ?? []
        _rules = State(initialValue: rules.isEmpty ? [.weeknights] : rules)
        _hasStoredSchedule = State(initialValue: initialSchedule != nil)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(
                    footer: Text("Chat push notifications are dropped, not delayed, while a quiet window is active. Windows that end before they start continue past midnight.")
                ) {
                    HStack {
                        Text("Time zone")
                        Spacer()
                        Text(timezone.identifier)
                            .foregroundColor(.secondary)
                    }
                }

                ForEach($rules) { $rule in
                    Section(header: ruleHeader(for: rule)) {
                        DaysPicker(days: $rule.days)
                        Toggle("All day", isOn: $rule.isAllDay)
                        if !rule.isAllDay {
                            DatePicker("Start", selection: $rule.start, displayedComponents: .hourAndMinute)
                            DatePicker("End", selection: $rule.end, displayedComponents: .hourAndMinute)
                        }
                    }
                }

                if rules.count < Self.maxRules {
                    Section {
                        Button {
                            rules.append(.weeknights)
                        } label: {
                            Label("Add Quiet Window", systemImage: "plus.circle")
                        }
                    }
                }

                Section {
                    Button(action: save) {
                        HStack {
                            if isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "moon.fill")
                            }
                            Text("Save Quiet Hours")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isLoading || rules.isEmpty)
                    .foregroundColor(.white)
                    .listRowBackground(Color.indigo)

                    if hasStoredSchedule {
                        Button(role: .destructive, action: remove) {
                            Text("Remove Quiet Hours")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(isLoading)
                    }
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Quiet Hours")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel", action: onDismiss)
                    .disabled(isLoading)
            )
        }
    }

    private func ruleHeader(for rule: EditableRule) -> some View {
        HStack {
            Text("Quiet window")
            Spacer()
            if rules.count > 1 {
                Button("Delete", role: .destructive) {
                    rules.removeAll { $0.id == rule.id }
                }
                .font(.caption)
            }
        }
    }

    private func save() {
        let schedule = PushSchedule(
            quietHours: rules.map { $0.rule(in: timezone) },
            timezone: timezone
        )
        perform { onSave(schedule, $0) }
    }

    private func remove() {
        perform(onRemove)
    }

    private func perform(_ action: (@escaping (Result<PushPreference, Error>) -> Void) -> Void) {
        isLoading = true
        errorMessage = nil
        action { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    onDismiss()
                case let .failure(error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

@available(iOS 15, *)
private struct DaysPicker: View {
    @Binding var days: Set<QuietHoursDay>

    private let allDays: [(day: QuietHoursDay, label: String)] = [
        (.monday, "M"), (.tuesday, "T"), (.wednesday, "W"), (.thursday, "T"),
        (.friday, "F"), (.saturday, "S"), (.sunday, "S")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(days.isEmpty ? "Every day" : "Opens on")
                .font(.caption)
                .foregroundColor(.secondary)
            HStack {
                ForEach(allDays, id: \.day) { item in
                    let isSelected = days.contains(item.day)
                    Button(item.label) {
                        if isSelected {
                            days.remove(item.day)
                        } else {
                            days.insert(item.day)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(width: 32, height: 32)
                    .background(isSelected ? Color.indigo : Color(.secondarySystemFill))
                    .foregroundColor(isSelected ? .white : .primary)
                    .clipShape(Circle())
                    .accessibilityLabel(item.day.rawValue)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// A quiet window being edited, with the times as dates so they can be picked.
private struct EditableRule: Identifiable {
    let id = UUID()
    var days: Set<QuietHoursDay>
    var isAllDay: Bool
    var start: Date
    var end: Date

    static var weeknights: EditableRule {
        EditableRule(
            QuietHoursRule(days: QuietHoursDay.weekdays, start: "22:00", end: "07:00"),
            in: .current
        )
    }

    init(_ rule: QuietHoursRule, in timezone: TimeZone) {
        days = Set(rule.days ?? [])
        isAllDay = rule.start == "00:00" && rule.end == "24:00"
        start = Self.date(from: rule.start, in: timezone) ?? Date()
        end = Self.date(from: rule.end == "24:00" ? "00:00" : rule.end, in: timezone) ?? Date()
    }

    func rule(in timezone: TimeZone) -> QuietHoursRule {
        let orderedDays = QuietHoursDay.weekdays + QuietHoursDay.weekend
        return QuietHoursRule(
            days: days.isEmpty ? nil : orderedDays.filter(days.contains),
            start: isAllDay ? "00:00" : Self.formatter(in: timezone).string(from: start),
            end: isAllDay ? "24:00" : Self.formatter(in: timezone).string(from: end)
        )
    }

    private static func formatter(in timezone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timezone
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    private static func date(from time: String, in timezone: TimeZone) -> Date? {
        guard let parsed = formatter(in: timezone).date(from: time) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone
        let components = calendar.dateComponents([.hour, .minute], from: parsed)
        return calendar.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: 0, of: Date())
    }
}
