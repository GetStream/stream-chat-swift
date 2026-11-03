//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// `Form(name, buttons, fields?)` — scopes field state and validation.
@available(iOS 17.0, macOS 14.0, *)
struct FormView: View {
    let context: ComponentContext
    @State private var validation = FormValidationModel()
    @Environment(\.openUITheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.l) {
            context.render(prop: "fields")
            context.render(prop: "buttons")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .environment(\.openUIFormName, context.props.text("name"))
        .environment(\.openUIFormValidation, validation)
    }
}

/// `FormControl(label, input, hint?)` — label, field, and hint or validation error.
@available(iOS 17.0, macOS 14.0, *)
struct FormControlView: View {
    let context: ComponentContext
    @Environment(\.openUIFormValidation) private var validation
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let input = context.props.element("input")
        let fieldName = input?.props["name"]?.stringValue
        let isRequired = input?.props["rules"]?["required"] == .bool(true)
        let error = fieldName.flatMap { validation?.error(for: $0) }

        VStack(alignment: .leading, spacing: theme.spacing.s) {
            HStack(spacing: 2) {
                Text(context.props.text("label") ?? "")
                    .font(theme.fonts.bodySmall.weight(.medium))
                    .foregroundStyle(theme.colors.textPrimary)
                if isRequired {
                    Text("*").font(theme.fonts.bodySmall.weight(.medium)).foregroundStyle(theme.colors.danger)
                }
            }
            context.render(prop: "input")
            if let error {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(theme.fonts.caption)
                    .foregroundStyle(theme.colors.danger)
                    .transition(.opacity)
            } else if let hint = context.props.text("hint"), !hint.isEmpty {
                Text(hint)
                    .font(theme.fonts.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: error)
    }
}

/// Text field chrome shared by inputs.
@available(iOS 17.0, macOS 14.0, *)
struct FieldChrome: ViewModifier {
    var hasError: Bool
    var isFocused: Bool
    @Environment(\.openUITheme) private var theme

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, theme.spacing.m)
            .padding(.vertical, 10)
            .background(theme.colors.sunkenSurface, in: RoundedRectangle(cornerRadius: theme.radius.small, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.small, style: .continuous)
                    .stroke(hasError ? theme.colors.danger : (isFocused ? theme.colors.accent : .clear), lineWidth: 1.5)
            )
    }
}

/// `Input(name, placeholder?, type?, rules?, value?)` and `TextArea(name, placeholder?, rows?, rules?, value?)`.
@available(iOS 17.0, macOS 14.0, *)
struct TextInputView: View {
    let context: ComponentContext
    let multiline: Bool
    @Environment(\.openUIFormName) private var formName
    @Environment(\.openUIFormValidation) private var validation
    @Environment(\.openUITheme) private var theme
    @FocusState private var focused: Bool

    var body: some View {
        let props = context.props
        let name = props.text("name") ?? ""
        let componentType = multiline ? "TextArea" : "Input"
        let type = props.string("type") ?? "text"
        let field = context.runtime.stateField(
            name: name,
            binding: props["value"],
            formName: formName,
            componentType: componentType,
            isSecret: !multiline && type == "password"
        )
        let rules = FormValidation.rules(from: props["rules"])
        let text = Binding<String>(
            get: { field.value.map { JS.isNullish($0) ? "" : JS.toString($0) } ?? "" },
            set: { newValue in
                field.set(.string(newValue))
                if !rules.isEmpty { validation?.clearError(name) }
            }
        )
        let placeholder = props.text("placeholder") ?? ""

        Group {
            if multiline {
                TextField(placeholder, text: text, axis: .vertical)
                    .lineLimit(Self.lineCount(rows: props.number("rows"))...)
            } else if type == "password" {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
                #if os(iOS)
                    .keyboardType(Self.keyboard(type))
                    .textInputAutocapitalization(type == "email" || type == "url" ? .never : .sentences)
                    .autocorrectionDisabled(type == "email" || type == "url")
                #endif
            }
        }
        .focused($focused)
        .font(theme.fonts.body)
        .modifier(FieldChrome(hasError: validation?.error(for: name) != nil, isFocused: focused))
        .disabled(context.isStreaming)
        .onChange(of: focused) { _, isFocused in
            if isFocused {
                validation?.clearError(name)
            } else if !rules.isEmpty {
                validation?.validateField(name, value: field.value, rules: rules)
            }
        }
        .registersValidation(name: name, rules: rules, isStreaming: context.isStreaming) {
            context.runtime.stateField(name: name, binding: props["value"], formName: formName).value
        }
    }

    // How many lines a TextArea shows at least: the model's `rows`, kept between 2 and 100.
    static func lineCount(rows: Double?) -> Int {
        guard let rows, rows.isFinite else { return 3 }
        return Int(min(max(rows, 2), 100))
    }

    #if os(iOS)
    static func keyboard(_ type: String) -> UIKeyboardType {
        switch type {
        case "email": return .emailAddress
        case "number": return .decimalPad
        case "url": return .URL
        default: return .default
        }
    }
    #endif
}

/// `Select(name, items, placeholder?, rules?, value?, size?)` with `SelectItem(value, label)`.
@available(iOS 17.0, macOS 14.0, *)
struct SelectView: View {
    let context: ComponentContext
    @Environment(\.openUIFormName) private var formName
    @Environment(\.openUIFormValidation) private var validation
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let props = context.props
        let name = props.text("name") ?? ""
        let field = context.runtime.stateField(name: name, binding: props["value"], formName: formName, componentType: "Select")
        let rules = FormValidation.rules(from: props["rules"])
        let items: [(value: String, label: String)] = props.elements("items").compactMap { item in
            guard let value = item.props["value"].map({ JS.toString($0) }), !value.isEmpty, !(item.props["value"]?.isNull ?? true) else { return nil }
            return (value, item.props["label"].map { JS.toString($0) } ?? value)
        }
        let selected = field.value.flatMap { JS.isNullish($0) ? nil : JS.toString($0) }
        let selectedLabel = items.first { $0.value == selected }?.label

        Menu {
            ForEach(items, id: \.value) { item in
                Button {
                    field.set(.string(item.value))
                    if !rules.isEmpty { validation?.validateField(name, value: .string(item.value), rules: rules) }
                } label: {
                    if item.value == selected {
                        Label(item.label, systemImage: "checkmark")
                    } else {
                        Text(item.label)
                    }
                }
            }
        } label: {
            HStack {
                Text(selectedLabel ?? props.text("placeholder") ?? L10n.Select.placeholder)
                    .foregroundStyle(selectedLabel == nil ? theme.colors.textTertiary : theme.colors.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: theme.spacing.s)
                Image(systemName: "chevron.up.chevron.down")
                    .font(theme.fonts.caption.weight(.semibold))
                    .foregroundStyle(theme.colors.textSecondary)
                    .accessibilityHidden(true)
            }
            .font(props.string("size") == "small" ? theme.fonts.bodySmall : .body)
            .contentShape(Rectangle())
            .modifier(FieldChrome(hasError: validation?.error(for: name) != nil, isFocused: false))
        }
        .disabled(context.isStreaming)
        .registersValidation(name: name, rules: rules, isStreaming: context.isStreaming) {
            context.runtime.stateField(name: name, binding: props["value"], formName: formName).value
        }
    }
}

/// `DatePicker(name, mode?, rules?, value?)` — stores `yyyy-MM-dd` (or `{from, to}` for ranges).
@available(iOS 17.0, macOS 14.0, *)
struct DatePickerView: View {
    let context: ComponentContext
    @Environment(\.openUIFormName) private var formName
    @Environment(\.openUIFormValidation) private var validation
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let props = context.props
        let name = props.text("name") ?? ""
        let field = context.runtime.stateField(name: name, binding: props["value"], formName: formName, componentType: "DatePicker")
        let rules = FormValidation.rules(from: props["rules"])
        let isRange = props.string("mode") == "range"

        Group {
            if isRange {
                let from = DateFormatting.date(from: field.value?["from"]?.stringValue)
                let to = DateFormatting.date(from: field.value?["to"]?.stringValue)
                VStack(alignment: .leading, spacing: theme.spacing.s) {
                    dateRow(L10n.DatePicker.from, date: from) { date in
                        var range = field.value?.objectValue ?? [:]
                        range["from"] = .string(DateFormatting.string(from: date))
                        if let to, to < date { range["to"] = .string(DateFormatting.string(from: date)) }
                        update(field, value: .object(range), name: name, rules: rules)
                    }
                    dateRow(L10n.DatePicker.to, date: to, minimum: from) { date in
                        var range = field.value?.objectValue ?? [:]
                        range["to"] = .string(DateFormatting.string(from: date))
                        if range["from"] == nil { range["from"] = .string(DateFormatting.string(from: date)) }
                        update(field, value: .object(range), name: name, rules: rules)
                    }
                }
            } else {
                dateRow(L10n.DatePicker.date, date: DateFormatting.date(from: field.value?.stringValue)) { date in
                    update(field, value: .string(DateFormatting.string(from: date)), name: name, rules: rules)
                }
            }
        }
        .padding(.horizontal, theme.spacing.m)
        .padding(.vertical, 6)
        .background(theme.colors.sunkenSurface, in: RoundedRectangle(cornerRadius: theme.radius.small, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.small, style: .continuous)
                .stroke(validation?.error(for: name) != nil ? theme.colors.danger : .clear, lineWidth: 1.5)
        )
        .disabled(context.isStreaming)
        .registersValidation(name: name, rules: rules, isStreaming: context.isStreaming) {
            context.runtime.stateField(name: name, binding: props["value"], formName: formName).value
        }
    }

    private func update(_ field: StateField, value: OpenUIValue, name: String, rules: [ValidationRule]) {
        field.set(value)
        if !rules.isEmpty { validation?.validateField(name, value: value, rules: rules) }
    }

    @ViewBuilder
    private func dateRow(_ title: String, date: Date?, minimum: Date? = nil, onChange: @escaping @MainActor (Date) -> Void) -> some View {
        HStack {
            Text(title)
                .font(theme.fonts.bodySmall)
                .foregroundStyle(theme.colors.textSecondary)
            Spacer()
            if date == nil {
                Button(L10n.DatePicker.choose) { onChange(minimum ?? Date()) }
                    .font(theme.fonts.bodySmall.weight(.medium))
            } else {
                DatePicker(
                    title,
                    selection: Binding(get: { date ?? Date() }, set: { onChange($0) }),
                    in: (minimum ?? .distantPast)...,
                    displayedComponents: .date
                )
                .labelsHidden()
            }
        }
    }
}

/// `Slider(name, variant, min, max, step?, defaultValue?, label?, rules?, value?)` — stores `[number]`,
/// or `[lower, upper]` when its value or default has two numbers.
@available(iOS 17.0, macOS 14.0, *)
struct SliderView: View {
    let context: ComponentContext
    @Environment(\.openUIFormName) private var formName
    @Environment(\.openUIFormValidation) private var validation
    @Environment(\.openUITheme) private var theme
    @State private var draft: [Double]?
    @State private var editingThumbs: Set<Int> = []

    var body: some View {
        let props = context.props
        let name = props.text("name") ?? ""
        let field = context.runtime.stateField(name: name, binding: props["value"], formName: formName, componentType: "Slider")
        let rules = FormValidation.rules(from: props["rules"])
        let bounds = SliderValues.bounds(minimum: props.number("min"), maximum: props.number("max"))
        let discrete = props.string("variant") == "discrete"
        let step = SliderValues.step(props.number("step"), discrete: discrete, in: bounds)
        let snap = SliderValues.requestedStep(props.number("step"), discrete: discrete, in: bounds)
        let stored = SliderValues.values(field.value.flatMap { JS.isNullish($0) ? nil : $0 } ?? props["defaultValue"], in: bounds)
        let values = draft.map { SliderValues.clamped($0, to: bounds) } ?? stored
        let label = props.text("label") ?? name

        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack {
                Text(label)
                    .font(theme.fonts.bodySmall)
                    .foregroundStyle(theme.colors.textSecondary)
                Spacer()
                Text(values.map(NumberFormatting.decimal).joined(separator: " – "))
                    .font(theme.fonts.bodySmall.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(theme.colors.textPrimary)
            }
            .accessibilityHidden(true)
            ForEach(values.indices, id: \.self) { index in
                thumb(index, values: values, bounds: bounds, step: step, snap: snap, label: label) { next in
                    commit(next, field: field, name: name, rules: rules)
                }
            }
            HStack {
                Text(NumberFormatting.decimal(bounds.lowerBound))
                Spacer()
                Text(NumberFormatting.decimal(bounds.upperBound))
            }
            .font(theme.fonts.caption)
            .monospacedDigit()
            .foregroundStyle(theme.colors.textTertiary)
            .accessibilityHidden(true)
        }
        .disabled(context.isStreaming)
        .savesDefault(isStreaming: context.isStreaming) {
            guard !field.isReactive else { return }
            FieldDefault.save(SliderValues.stored(stored), runtime: context.runtime, formName: formName, componentType: "Slider", name: name)
        }
        .registersValidation(name: name, rules: rules, isStreaming: context.isStreaming) {
            context.runtime.stateField(name: name, binding: props["value"], formName: formName).value
        }
    }

    // VoiceOver adjusts a slider without editing callbacks, so a change outside a drag is saved at once.
    @ViewBuilder
    private func thumb(
        _ index: Int,
        values: [Double],
        bounds: ClosedRange<Double>,
        step: Double?,
        snap: Double?,
        label: String,
        commit: @escaping @MainActor ([Double]) -> Void
    ) -> some View {
        let value = Binding<Double>(
            get: { values.indices.contains(index) ? values[index] : bounds.lowerBound },
            set: { newValue in
                let snapped = snap.map { SliderValues.snapped(newValue, to: $0, in: bounds) } ?? newValue
                let next = SliderValues.setting(draft ?? values, index: index, to: snapped)
                draft = next
                if editingThumbs.isEmpty { commit(next) }
            }
        )
        let onEditingChanged: (Bool) -> Void = { isEditing in
            if isEditing {
                editingThumbs.insert(index)
            } else {
                editingThumbs.remove(index)
                if editingThumbs.isEmpty, let draft { commit(draft) }
            }
        }
        Group {
            if let step {
                Slider(value: value, in: bounds, step: step, onEditingChanged: onEditingChanged)
            } else {
                Slider(value: value, in: bounds, onEditingChanged: onEditingChanged)
            }
        }
        .accessibilityLabel(Text(SliderValues.accessibilityLabel(label, index: index, count: values.count)))
        .accessibilityValue(Text(NumberFormatting.decimal(values[index])))
    }

    private func commit(_ values: [Double], field: StateField, name: String, rules: [ValidationRule]) {
        let stored = SliderValues.stored(values)
        field.set(stored)
        if !rules.isEmpty { validation?.validateField(name, value: stored.arrayValue?.first, rules: rules) }
        draft = nil
    }
}

/// `CheckBoxGroup(name, items, rules?, value?)` and `SwitchGroup(name, items, variant?, value?)` — store `{itemName: bool}`.
@available(iOS 17.0, macOS 14.0, *)
struct ToggleGroupView: View {
    let context: ComponentContext
    let isSwitch: Bool
    @Environment(\.openUIFormName) private var formName
    @Environment(\.openUIFormValidation) private var validation
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let props = context.props
        let name = props.text("name") ?? ""
        let componentType = isSwitch ? "SwitchGroup" : "CheckBoxGroup"
        let field = context.runtime.stateField(name: name, binding: props["value"], formName: formName, componentType: componentType)
        let rules = isSwitch ? [] : FormValidation.rules(from: props["rules"])
        let items = props.elements("items")
        let stored = field.value?.objectValue

        let aggregate: OpenUIObject = {
            var result = OpenUIObject()
            for item in items {
                guard let itemName = item.props["name"].map({ JS.toString($0) }) else { continue }
                result[itemName] = .bool(stored?[itemName]?.boolValue ?? item.props["defaultChecked"]?.boolValue ?? false)
            }
            return result
        }()

        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    let itemProps = ComponentProps(item.props)
                    let itemName = itemProps.text("name") ?? "\(index)"
                    let isOn = aggregate[itemName]?.boolValue ?? false
                    let binding = Binding<Bool>(
                        get: { isOn },
                        set: { newValue in
                            var next = aggregate
                            next[itemName] = .bool(newValue)
                            field.set(.object(next))
                            if !rules.isEmpty { validation?.validateField(name, value: .object(next), rules: rules) }
                        }
                    )
                    Toggle(isOn: binding) {
                        TitleSubtitle(title: itemProps.text("label") ?? itemName, subtitle: itemProps.text("description"))
                    }
                    .modifier(ToggleAppearance(isSwitch: isSwitch))
                    .padding(.vertical, theme.spacing.s)
                    if isSwitch && index < items.count - 1 { Divider() }
                }
            }
            .openUISurface(isSwitch ? (props.string("variant") ?? "clear") : "clear", padding: theme.spacing.m)
            .disabled(context.isStreaming)
            .savesDefault(isStreaming: context.isStreaming) {
                guard !field.isReactive, !aggregate.isEmpty else { return }
                FieldDefault.save(.object(aggregate), runtime: context.runtime, formName: formName, componentType: componentType, name: name)
            }
            .registersValidation(name: name, rules: rules, isStreaming: context.isStreaming) {
                context.runtime.stateField(name: name, binding: props["value"], formName: formName).value ?? .object(aggregate)
            }
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct ToggleAppearance: ViewModifier {
    let isSwitch: Bool

    func body(content: Content) -> some View {
        if isSwitch {
            content.toggleStyle(.switch)
        } else {
            content.toggleStyle(CheckboxToggleStyle())
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct CheckboxToggleStyle: ToggleStyle {
    @Environment(\.openUITheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: .top, spacing: theme.spacing.m) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(theme.fonts.bodyLarge)
                    .foregroundStyle(configuration.isOn ? theme.colors.accent : theme.colors.textTertiary)
                    .accessibilityHidden(true)
                configuration.label
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(Text(configuration.isOn ? L10n.Toggle.checked : L10n.Toggle.unchecked))
    }
}

/// `RadioGroup(name, items, defaultValue?, rules?, value?)` with `RadioItem(label, description, value)`.
@available(iOS 17.0, macOS 14.0, *)
struct RadioGroupView: View {
    let context: ComponentContext
    @Environment(\.openUIFormName) private var formName
    @Environment(\.openUIFormValidation) private var validation
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let props = context.props
        let name = props.text("name") ?? ""
        let field = context.runtime.stateField(name: name, binding: props["value"], formName: formName, componentType: "RadioGroup")
        let rules = FormValidation.rules(from: props["rules"])
        let items = props.elements("items")
        let current = (field.value.flatMap { JS.isNullish($0) ? nil : $0 } ?? props["defaultValue"]).map { JS.toString($0) }
        let shown = items.contains { (ComponentProps($0.props).text("value") ?? "") == current } ? current : nil

        if !items.isEmpty {
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    let itemProps = ComponentProps(item.props)
                    let value = itemProps.text("value") ?? ""
                    let selected = value == current
                    Button {
                        field.set(.string(value))
                        if !rules.isEmpty { validation?.validateField(name, value: .string(value), rules: rules) }
                    } label: {
                        HStack(alignment: .top, spacing: theme.spacing.m) {
                            Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                                .font(theme.fonts.bodyLarge)
                                .foregroundStyle(selected ? theme.colors.accent : theme.colors.textTertiary)
                                .accessibilityHidden(true)
                            TitleSubtitle(title: itemProps.text("label") ?? value, subtitle: itemProps.text("description"))
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? [.isSelected] : [])
                }
            }
            .disabled(context.isStreaming)
            .savesDefault(isStreaming: context.isStreaming) {
                guard !field.isReactive, let shown else { return }
                FieldDefault.save(.string(shown), runtime: context.runtime, formName: formName, componentType: "RadioGroup", name: name)
            }
            .registersValidation(name: name, rules: rules, isStreaming: context.isStreaming) {
                context.runtime.stateField(name: name, binding: props["value"], formName: formName).value
            }
        }
    }
}

/// `Chips(...)` and `OptionCards(...)` — single or multiple selection stored under `name`.
@available(iOS 17.0, macOS 14.0, *)
struct SelectionFieldView: View {
    let context: ComponentContext
    let isCards: Bool
    @Environment(\.openUIFormName) private var formName
    @Environment(\.openUIFormValidation) private var validation
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let props = context.props
        let name = props.text("name") ?? ""
        let componentType = isCards ? "OptionCards" : "Chips"
        let single = (props.string("type") ?? (isCards ? "single" : "multiple")) == "single"
        let rules = FormValidation.rules(from: props["rules"])
        let items = props.elements("items").filter { !JS.isNullish($0.props["value"]) }
        let stored = context.runtime.fieldValue(formName: formName, name: name)
        let selection = SelectionField.normalize(single: single, stored: stored, defaultValue: props["defaultValue"])
        let runtime = context.runtime

        Group {
            if isCards {
                ResponsiveGridLayout(spacing: theme.spacing.s, minItemWidth: 140, maxColumns: 3) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        optionCard(item, selection: selection) { toggle(item, single: single, selection: selection, name: name, componentType: componentType, rules: rules) }
                    }
                }
            } else {
                FlowLayout(horizontalSpacing: theme.spacing.s, verticalSpacing: theme.spacing.s) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        chip(item, selection: selection) { toggle(item, single: single, selection: selection, name: name, componentType: componentType, rules: rules) }
                    }
                }
            }
        }
        .savesDefault(isStreaming: context.isStreaming) {
            SelectionField.hydrateDefault(runtime: runtime, formName: formName, componentType: componentType, name: name, single: single, defaultValue: props["defaultValue"])
        }
        .registersValidation(name: name, rules: rules, isStreaming: context.isStreaming) {
            let value = runtime.fieldValue(formName: formName, name: name) ?? SelectionField.storedDefault(single: single, defaultValue: props["defaultValue"])
            if single {
                if case .string(let string)? = value, !string.isEmpty { return value }
                return nil
            }
            if case .array(let items)? = value, !items.isEmpty { return value }
            return nil
        }
    }

    private func toggle(_ item: ElementNode, single: Bool, selection: [String], name: String, componentType: String, rules: [ValidationRule]) {
        guard !context.isStreaming, item.props["disabled"] != .bool(true) else { return }
        let value = JS.toString(item.props["value"])
        let next = SelectionField.toggle(single: single, selection: selection, value: value)
        let stored: OpenUIValue = single ? (next.first.map(OpenUIValue.string) ?? .null) : .array(next.map(OpenUIValue.string))
        context.runtime.setFieldValue(formName: formName, componentType: componentType, name: name, value: stored)
        if !rules.isEmpty {
            let validationValue: OpenUIValue? = single ? next.first.map(OpenUIValue.string) : (next.isEmpty ? nil : stored)
            validation?.validateField(name, value: validationValue, rules: rules)
        }
    }

    private func chip(_ item: ElementNode, selection: [String], action: @escaping () -> Void) -> some View {
        let props = ComponentProps(item.props)
        let value = JS.toString(item.props["value"])
        let selected = selection.contains(value)
        let disabled = props.bool("disabled") ?? false
        return Button(action: action) {
            HStack(spacing: 6) {
                if let icon = props.element("icon") {
                    OpenUIIconImage(element: icon)
                        .font(theme.fonts.bodySmall.weight(.semibold))
                        .accessibilityHidden(true)
                }
                Text(props.text("label") ?? value)
                    .font(theme.fonts.bodySmall.weight(.medium))
                if selected {
                    Image(systemName: "checkmark")
                        .font(theme.fonts.caption.weight(.bold))
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(selected ? theme.colors.accent : theme.colors.textPrimary)
            .background(selected ? theme.colors.accent.opacity(0.14) : theme.colors.sunkenSurface, in: Capsule())
            .overlay(Capsule().stroke(selected ? theme.colors.accent : .clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(disabled || context.isStreaming)
        .opacity(disabled ? 0.5 : 1)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private func optionCard(_ item: ElementNode, selection: [String], action: @escaping () -> Void) -> some View {
        let props = ComponentProps(item.props)
        let value = JS.toString(item.props["value"])
        let selected = selection.contains(value)
        let disabled = props.bool("disabled") ?? false
        let top = props.element("topContent")
        return Button(action: action) {
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                if let top {
                    if top.props["src"]?.stringValue != nil {
                        RemoteImage(url: top.props["src"]?.stringValue, alt: top.props["alt"]?.stringValue)
                            .filling(height: 80, cornerRadius: theme.radius.small)
                    } else {
                        IconBadge(icon: top, variant: selected ? "soft" : "neutral", size: "sm")
                    }
                }
                TitleSubtitle(title: props.text("title") ?? value, subtitle: props.text("subtitle"), bold: true)
                Spacer(minLength: 0)
            }
            .padding(theme.spacing.m)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(selected ? theme.colors.accent.opacity(0.08) : theme.colors.sunkenSurface, in: RoundedRectangle(cornerRadius: theme.radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.medium, style: .continuous)
                    .stroke(selected ? theme.colors.accent : .clear, lineWidth: 1.5)
            )
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(theme.colors.accent)
                        .padding(theme.spacing.s)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(disabled || context.isStreaming)
        .opacity(disabled ? 0.5 : 1)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}
