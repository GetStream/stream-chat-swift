//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// The input components of the A2UI basic catalog.
///
/// Input components establish a two-way binding with the surface data model:
/// they read their value from the bound path and write back immediately as the
/// user interacts, without contacting the agent. The updated state reaches the
/// agent when an action is dispatched.
@available(iOS 15.0, macOS 12.0, *)
enum InputComponents {
    /// All input components, in catalog order.
    static var all: [ComponentDefinition] {
        [textField, checkBox, choicePicker, slider, dateTimeInput]
    }

    private static let checksSchema = JsonSchema.array(
        description: "Checks that are evaluated whenever the value changes.",
        items: JsonSchema.commonType("CheckRule")
    )

    /// A single or multi line text input.
    static let textField = ComponentDefinition(
        name: "TextField",
        description: "A field for user text input.",
        properties: [
            "label": JsonSchema.dynamicString(description: "The text label for the input field."),
            "value": JsonSchema.dynamicString(description: "The value of the text field."),
            "placeholder": JsonSchema.dynamicString(description: "The placeholder text for the input field."),
            "variant": JsonSchema.string(
                description: "The type of input field to display.",
                enumValues: ["longText", "number", "shortText", "obscured"],
                defaultValue: "shortText"
            ),
            "checks": checksSchema,
            "weight": JsonSchema.weight()
        ],
        required: ["label"],
        examples: [
            """
            [
              {
                "id": "root",
                "component": "TextField",
                "label": "Email",
                "value": {"@path": "/form/email"},
                "placeholder": "you@example.com",
                "checks": [{"condition": {"@call": "email", "args": {"value": {"@path": "/form/email"}}}, "message": "Enter a valid email address."}]
              }
            ]
            """
        ]
    ) { context in
        AnyView(A2UITextFieldView(context: context))
    }

    /// A labelled boolean input.
    static let checkBox = ComponentDefinition(
        name: "CheckBox",
        description: "A checkbox with a label and a boolean value.",
        properties: [
            "label": JsonSchema.dynamicString(description: "The text to display next to the checkbox."),
            "value": JsonSchema.dynamicBoolean(
                description: "The current state of the checkbox (true for checked, false for unchecked)."
            ),
            "checks": checksSchema,
            "weight": JsonSchema.weight()
        ],
        required: ["label", "value"],
        examples: [
            """
            [
              {
                "id": "root",
                "component": "CheckBox",
                "label": "Subscribe to the newsletter",
                "value": {"@path": "/form/subscribe"}
              }
            ]
            """
        ]
    ) { context in
        AnyView(A2UICheckBoxView(context: context))
    }

    /// A single or multi select option list.
    static let choicePicker = ComponentDefinition(
        name: "ChoicePicker",
        description: "A component that allows selecting one or more options from a list.",
        properties: [
            "label": JsonSchema.dynamicString(description: "The label for the group of options."),
            "variant": JsonSchema.string(
                description: "A hint for how the choice picker should be displayed and behave.",
                enumValues: ["multipleSelection", "mutuallyExclusive"],
                defaultValue: "mutuallyExclusive"
            ),
            "options": JsonSchema.array(
                description: "The list of available options to choose from.",
                items: JsonSchema.object(
                    properties: [
                        "label": JsonSchema.dynamicString(description: "The text to display for this option."),
                        "value": JsonSchema.string(description: "The stable value associated with this option.")
                    ],
                    required: ["label", "value"],
                    additionalProperties: false
                )
            ),
            "value": JsonSchema.dynamicStringList(
                description: "The list of currently selected values. Bind this to a string array in the data model."
            ),
            "displayStyle": JsonSchema.string(
                description: "The display style of the component.",
                enumValues: ["checkbox", "chips"],
                defaultValue: "checkbox"
            ),
            "filterable": JsonSchema.boolean(
                description: "If true, displays a search input to filter the options.",
                defaultValue: false
            ),
            "checks": checksSchema,
            "weight": JsonSchema.weight()
        ],
        required: ["options", "value"],
        examples: [
            """
            [
              {
                "id": "root",
                "component": "ChoicePicker",
                "label": "Order type",
                "variant": "mutuallyExclusive",
                "displayStyle": "chips",
                "options": [
                  {"label": "Pickup", "value": "pickup"},
                  {"label": "Delivery", "value": "delivery"}
                ],
                "value": {"@path": "/order/type"}
              }
            ]
            """
        ]
    ) { context in
        AnyView(A2UIChoicePickerView(context: context))
    }

    /// A numeric slider with an optional discrete step count.
    static let slider = ComponentDefinition(
        name: "Slider",
        description: "A slider for selecting a numeric value within a range.",
        properties: [
            "label": JsonSchema.dynamicString(description: "The label for the slider."),
            "min": JsonSchema.number(description: "The minimum value of the slider.", defaultValue: 0),
            "max": JsonSchema.number(description: "The maximum value of the slider."),
            "value": JsonSchema.dynamicNumber(description: "The current value of the slider."),
            "steps": JsonSchema.integer(
                description: "The number of discrete divisions in the slider range.",
                minimum: 1
            ),
            "checks": checksSchema,
            "weight": JsonSchema.weight()
        ],
        required: ["value", "max"],
        examples: [
            """
            [
              {
                "id": "root",
                "component": "Slider",
                "label": "Party size",
                "min": 1,
                "max": 8,
                "steps": 7,
                "value": {"@path": "/order/partySize"}
              }
            ]
            """
        ]
    ) { context in
        AnyView(A2UISliderView(context: context))
    }

    /// A date and/or time input.
    static let dateTimeInput = ComponentDefinition(
        name: "DateTimeInput",
        description: "An input for date and/or time.",
        properties: [
            "value": JsonSchema.dynamicString(
                description: "The selected date and/or time value in ISO 8601 format. "
                    + "If not yet set, initialize with an empty string."
            ),
            "enableDate": JsonSchema.boolean(
                description: "If true, allows the user to select a date.",
                defaultValue: false
            ),
            "enableTime": JsonSchema.boolean(
                description: "If true, allows the user to select a time.",
                defaultValue: false
            ),
            "min": JsonSchema.dynamicString(description: "The minimum allowed date/time in ISO 8601 format."),
            "max": JsonSchema.dynamicString(description: "The maximum allowed date/time in ISO 8601 format."),
            "label": JsonSchema.dynamicString(description: "The text label for the input field."),
            "checks": checksSchema,
            "weight": JsonSchema.weight()
        ],
        required: ["value"],
        examples: [
            """
            [
              {
                "id": "root",
                "component": "DateTimeInput",
                "label": "Pickup time",
                "value": {"@path": "/order/pickupAt"},
                "enableDate": true,
                "enableTime": true
              }
            ]
            """
        ]
    ) { context in
        AnyView(A2UIDateTimeInputView(context: context))
    }
}

// MARK: - Views

/// Renders an A2UI `TextField`, including its validation state.
@available(iOS 15.0, macOS 12.0, *)
private struct A2UICheckBoxView: View {
    let context: ComponentRenderContext

    @Environment(\.a2uiTheme) private var theme

    var body: some View {
        let binding = context.boolBinding()
        let failures = context.failingChecks

        VStack(alignment: .leading, spacing: 4) {
            Button {
                binding.wrappedValue.toggle()
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: binding.wrappedValue ? "checkmark.square.fill" : "square")
                        .foregroundColor(binding.wrappedValue ? theme.accent : theme.secondaryText)
                    Text(context.string("label", default: ""))
                        .font(theme.body)
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(binding.wrappedValue ? [.isButton, .isSelected] : .isButton)
            ValidationMessages(results: failures)
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
private struct A2UITextFieldView: View {
    let context: ComponentRenderContext

    @Environment(\.a2uiTheme) private var theme

    var body: some View {
        let label = context.string("label", default: "")
        let placeholder = context.string("placeholder", default: "")
        let variant = context.option("variant", default: "shortText")
        let binding = context.stringBinding()
        let failures = context.failingChecks
        let hasError = failures.contains { $0.severity == .error }

        return VStack(alignment: .leading, spacing: 4) {
            if !label.isEmpty {
                Text(label)
                    .font(theme.label)
                    .foregroundColor(hasError ? theme.error : theme.secondaryText)
            }
            input(variant: variant, placeholder: placeholder.isEmpty ? label : placeholder, binding: binding)
                .font(theme.body)
                .padding(10)
                .background(theme.subtleSurface)
                .clipShape(RoundedRectangle(cornerRadius: theme.controlCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.controlCornerRadius, style: .continuous)
                        .stroke(hasError ? theme.error : Color.clear, lineWidth: 1)
                )
                .accessibilityLabel(Text(label))
            ValidationMessages(results: failures)
        }
    }

    @ViewBuilder
    private func input(variant: String, placeholder: String, binding: Binding<String>) -> some View {
        switch variant {
        case "obscured":
            SecureField(placeholder, text: binding)
        case "longText":
            TextEditor(text: binding)
                .frame(minHeight: 80)
        case "number":
            #if os(iOS)
            TextField(placeholder, text: binding).keyboardType(.decimalPad)
            #else
            TextField(placeholder, text: binding)
            #endif
        default:
            TextField(placeholder, text: binding)
        }
    }
}

/// Renders an A2UI `ChoicePicker` in checkbox or chip style.
@available(iOS 15.0, macOS 12.0, *)
private struct A2UIChoicePickerView: View {
    let context: ComponentRenderContext

    @State private var filter = ""
    @Environment(\.a2uiTheme) private var theme

    private struct Option: Identifiable {
        let label: String
        let value: String
        var id: String { value }
    }

    var body: some View {
        let label = context.string("label", default: "")
        let isMultiSelect = context.option("variant", default: "mutuallyExclusive") == "multipleSelection"
        let usesChips = context.option("displayStyle", default: "checkbox") == "chips"
        let isFilterable = Json.bool(context.component.property("filterable")) ?? false
        let selection = context.stringArrayBinding()
        let failures = context.failingChecks
        let options = self.options.filter {
            filter.isEmpty || $0.label.localizedCaseInsensitiveContains(filter)
        }

        return VStack(alignment: .leading, spacing: 6) {
            if !label.isEmpty {
                Text(label).font(theme.label).foregroundColor(theme.secondaryText)
            }
            if isFilterable {
                TextField("Search", text: $filter)
                    .font(theme.body)
                    .padding(8)
                    .background(theme.subtleSurface)
                    .clipShape(RoundedRectangle(cornerRadius: theme.controlCornerRadius, style: .continuous))
            }
            if usesChips {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(options) { option in
                        chip(option, selection: selection, isMultiSelect: isMultiSelect)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(options) { option in
                        row(option, selection: selection, isMultiSelect: isMultiSelect)
                    }
                }
            }
            ValidationMessages(results: failures)
        }
    }

    private var options: [Option] {
        (Json.array(context.component.property("options")) ?? []).compactMap { entry in
            guard let map = Json.map(entry), let value = map["value"] as? String else { return nil }
            let label = context.evaluator.string(DynamicValue(map["label"]), in: context.dataContext) ?? value
            return Option(label: label, value: value)
        }
    }

    private func isSelected(_ option: Option, _ selection: Binding<[String]>) -> Bool {
        selection.wrappedValue.contains(option.value)
    }

    private func toggle(_ option: Option, _ selection: Binding<[String]>, isMultiSelect: Bool) {
        var values = selection.wrappedValue
        if isMultiSelect {
            if let index = values.firstIndex(of: option.value) {
                values.remove(at: index)
            } else {
                values.append(option.value)
            }
        } else {
            values = values.contains(option.value) ? [] : [option.value]
        }
        selection.wrappedValue = values
    }

    private func row(_ option: Option, selection: Binding<[String]>, isMultiSelect: Bool) -> some View {
        let selected = isSelected(option, selection)
        let symbol: String
        if isMultiSelect {
            symbol = selected ? "checkmark.square.fill" : "square"
        } else {
            symbol = selected ? "largecircle.fill.circle" : "circle"
        }
        return Button {
            toggle(option, selection, isMultiSelect: isMultiSelect)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: symbol)
                    .foregroundColor(selected ? theme.accent : theme.secondaryText)
                Text(option.label).font(theme.body)
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    private func chip(_ option: Option, selection: Binding<[String]>, isMultiSelect: Bool) -> some View {
        let selected = isSelected(option, selection)
        return Button {
            toggle(option, selection, isMultiSelect: isMultiSelect)
        } label: {
            Text(option.label)
                .font(theme.label)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(selected ? theme.accent.opacity(0.18) : theme.subtleSurface)
                .foregroundColor(selected ? theme.accent : theme.text)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}

/// Renders an A2UI `Slider`, snapping to discrete steps when requested.
@available(iOS 15.0, macOS 12.0, *)
struct A2UISliderView: View {
    let context: ComponentRenderContext

    @Environment(\.a2uiTheme) private var theme

    var body: some View {
        let label = context.string("label", default: "")
        let range = Self.range(
            minimum: Json.double(context.component.property("min")),
            maximum: Json.double(context.component.property("max"))
        )
        let step = Self.step(in: range, steps: Json.int(context.component.property("steps")))
        let binding = context.doubleBinding(default: range.lowerBound)
        let failures = context.failingChecks

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                if !label.isEmpty {
                    Text(label).font(theme.label).foregroundColor(theme.secondaryText)
                }
                Spacer(minLength: 0)
                Text(Json.stringify(binding.wrappedValue)).font(theme.label.monospacedDigit())
            }
            slider(binding: binding, range: range, step: step)
                .tint(theme.accent)
                .accessibilityLabel(Text(label))
            ValidationMessages(results: failures)
        }
        // What the slider shows is what the person submits.
        .onAppear {
            if context.double("value") == nil {
                context.write(range.lowerBound, to: "value")
            }
        }
    }

    @ViewBuilder
    private func slider(binding: Binding<Double>, range: ClosedRange<Double>, step: Double?) -> some View {
        if let step {
            Slider(value: binding, in: range, step: step)
        } else {
            Slider(value: binding, in: range)
        }
    }

    // The agent writes the bounds, so they can be anything: SwiftUI's Slider needs finite bounds
    // whose difference is representable, and a positive step.
    static func range(minimum: Double?, maximum: Double?) -> ClosedRange<Double> {
        let limit = 1e15
        func bounded(_ value: Double?) -> Double? {
            value.flatMap { $0.isFinite ? min(max($0, -limit), limit) : nil }
        }
        let lower = bounded(minimum) ?? 0
        let upper = bounded(maximum).flatMap { $0 > lower ? $0 : nil } ?? lower + 1
        return lower...upper
    }

    static func step(in range: ClosedRange<Double>, steps: Int?) -> Double? {
        guard let steps, steps > 0 else { return nil }
        let step = (range.upperBound - range.lowerBound) / Double(steps)
        return step.isFinite && step > 0 ? step : nil
    }
}

/// Renders an A2UI `DateTimeInput` and writes ISO 8601 values back.
@available(iOS 15.0, macOS 12.0, *)
private struct A2UIDateTimeInputView: View {
    let context: ComponentRenderContext

    @Environment(\.a2uiTheme) private var theme

    var body: some View {
        let label = context.string("label", default: "")
        let enableDate = Json.bool(context.component.property("enableDate")) ?? false
        let enableTime = Json.bool(context.component.property("enableTime")) ?? false
        let failures = context.failingChecks
        var components: DatePickerComponents = []
        if enableDate || (!enableDate && !enableTime) { components.insert(.date) }
        if enableTime { components.insert(.hourAndMinute) }

        let selection = Binding<Date>(
            get: {
                A2UIDateParser.date(from: context.string("value"), timeZone: context.services.timeZone)
                    ?? context.services.now()
            },
            set: { newValue in
                context.write(
                    A2UIDateTimeInputView.format(
                        newValue,
                        enableDate: enableDate,
                        enableTime: enableTime,
                        timeZone: context.services.timeZone
                    ),
                    to: "value"
                )
            }
        )

        return VStack(alignment: .leading, spacing: 4) {
            picker(label: label, selection: selection, components: components)
                .font(theme.body)
                .tint(theme.accent)
            ValidationMessages(results: failures)
        }
        // What the picker shows is what the person submits.
        .onAppear {
            if (context.string("value") ?? "").isEmpty {
                selection.wrappedValue = shown(selection.wrappedValue)
            }
        }
    }

    // A date within the picker's bounds, as the picker shows it.
    private func shown(_ date: Date) -> Date {
        let range = self.range
        if let lower = range.lower, date < lower { return lower }
        if let upper = range.upper, date > upper { return upper }
        return date
    }

    @ViewBuilder
    private func picker(label: String, selection: Binding<Date>, components: DatePickerComponents) -> some View {
        let range = self.range
        if let lower = range.lower, let upper = range.upper, lower <= upper {
            DatePicker(label, selection: selection, in: lower...upper, displayedComponents: components)
        } else if let lower = range.lower {
            DatePicker(label, selection: selection, in: lower..., displayedComponents: components)
        } else if let upper = range.upper {
            DatePicker(label, selection: selection, in: ...upper, displayedComponents: components)
        } else {
            DatePicker(label, selection: selection, displayedComponents: components)
        }
    }

    private var range: (lower: Date?, upper: Date?) {
        (
            A2UIDateParser.date(from: context.string("min"), timeZone: context.services.timeZone),
            A2UIDateParser.date(from: context.string("max"), timeZone: context.services.timeZone)
        )
    }

    /// Formats a date using the narrowest ISO 8601 form the input allows.
    static func format(_ date: Date, enableDate: Bool, enableTime: Bool, timeZone: TimeZone) -> String {
        if enableDate && !enableTime {
            return formatted(date, pattern: "yyyy-MM-dd", timeZone: timeZone)
        }
        if enableTime && !enableDate {
            return formatted(date, pattern: "HH:mm:ss", timeZone: timeZone)
        }
        return A2UITimestamp.string(from: date)
    }

    private static func formatted(_ date: Date, pattern: String, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }
}
