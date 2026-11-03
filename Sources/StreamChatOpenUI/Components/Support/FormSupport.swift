//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Observation
import SwiftUI

/// Per-form validation state (port of `useCreateFormValidation`). Created by `Form` and shared
/// with its fields through the environment.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
@Observable
final class FormValidationModel {
    private(set) var errors: [String: String] = [:]

    private struct Registration {
        var rules: [ValidationRule]
        var value: @MainActor () -> OpenUIValue?
    }

    @ObservationIgnored private var fields: [String: Registration] = [:]

    init() {}

    func error(for name: String) -> String? {
        errors[name]
    }

    func register(_ name: String, rules: [ValidationRule], value: @escaping @MainActor () -> OpenUIValue?) {
        fields[name] = Registration(rules: rules, value: value)
    }

    func unregister(_ name: String) {
        fields.removeValue(forKey: name)
    }

    @discardableResult
    func validateField(_ name: String, value: OpenUIValue?, rules: [ValidationRule]) -> Bool {
        let error = FormValidation.validate(value, rules: rules)
        if errors[name] != error { errors[name] = error }
        return error == nil
    }

    /// Validates every registered field; returns `true` when the form is valid.
    func validateForm() -> Bool {
        var next: [String: String] = [:]
        for (name, registration) in fields {
            var value = registration.value()
            if case .object(let object)? = value, object.contains("value"), object.contains("componentType") {
                value = object["value"]
            }
            if let error = FormValidation.validate(value, rules: registration.rules) {
                next[name] = error
            }
        }
        errors = next
        return next.isEmpty
    }

    func clearError(_ name: String) {
        if errors[name] != nil { errors[name] = nil }
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct FormNameKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

@available(iOS 17.0, macOS 14.0, *)
private struct FormValidationKey: EnvironmentKey {
    static let defaultValue: FormValidationModel? = nil
}

@available(iOS 17.0, macOS 14.0, *)
extension EnvironmentValues {
    /// The enclosing `Form`'s name (form fields are stored under it).
    var openUIFormName: String? {
        get { self[FormNameKey.self] }
        set { self[FormNameKey.self] = newValue }
    }

    /// The enclosing `Form`'s validation model.
    var openUIFormValidation: FormValidationModel? {
        get { self[FormValidationKey.self] }
        set { self[FormValidationKey.self] = newValue }
    }
}

/// Registers a field's validation rules with the enclosing form while it is visible and not streaming.
@available(iOS 17.0, macOS 14.0, *)
struct FieldValidationRegistration: ViewModifier {
    let name: String
    let rules: [ValidationRule]
    let isStreaming: Bool
    let value: @MainActor () -> OpenUIValue?
    @Environment(\.openUIFormValidation) private var validation

    func body(content: Content) -> some View {
        content
            .onAppear(perform: register)
            .onChange(of: isStreaming) { _, _ in register() }
            .onChange(of: rules) { _, _ in register() }
            .onDisappear { validation?.unregister(name) }
    }

    private func register() {
        guard let validation, !rules.isEmpty, !isStreaming else { return }
        validation.register(name, rules: rules, value: value)
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension View {
    func registersValidation(name: String, rules: [ValidationRule], isStreaming: Bool, value: @escaping @MainActor () -> OpenUIValue?) -> some View {
        modifier(FieldValidationRegistration(name: name, rules: rules, isStreaming: isStreaming, value: value))
    }
}

// Saves the value a field shows by default once the model has finished writing it, unless one is
// already stored, so the form sends and validates what the person sees (useSetDefaultValue).
@available(iOS 17.0, macOS 14.0, *)
enum FieldDefault {
    @MainActor
    static func save(_ value: OpenUIValue?, runtime: OpenUIRuntime, formName: String?, componentType: String, name: String) {
        guard !runtime.isStreaming,
              runtime.fieldValue(formName: formName, name: name) == nil,
              let value else { return }
        runtime.setFieldValue(formName: formName, componentType: componentType, name: name, value: value)
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct SavesDefault: ViewModifier {
    let isStreaming: Bool
    let save: @MainActor () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear(perform: save)
            .onChange(of: isStreaming) { _, isStreaming in
                if !isStreaming { save() }
            }
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension View {
    func savesDefault(isStreaming: Bool, _ save: @escaping @MainActor () -> Void) -> some View {
        modifier(SavesDefault(isStreaming: isStreaming, save: save))
    }
}

/// Helpers for selection fields (port of `selectionFieldUtils.ts`).
@available(iOS 17.0, macOS 14.0, *)
enum SelectionField {
    /// Resolves the stored value (falling back to the default) into the selected values.
    static func normalize(single: Bool, stored: OpenUIValue?, defaultValue: OpenUIValue?) -> [String] {
        func first(_ value: OpenUIValue?) -> [String]? {
            switch value {
            case .string(let string)?: return string.isEmpty ? [] : [string]
            case .array(let items)?:
                guard let first = items.first?.stringValue else { return nil }
                return first.isEmpty ? [] : [first]
            default: return nil
            }
        }
        func all(_ value: OpenUIValue?) -> [String]? {
            switch value {
            case .array(let items)?: return items.compactMap(\.stringValue)
            case .string(let string)?: return string.isEmpty ? [] : [string]
            default: return nil
            }
        }
        if single {
            return first(stored) ?? first(defaultValue) ?? []
        }
        return all(stored) ?? all(defaultValue) ?? []
    }

    /// The default value shaped for storage (string for single, array for multiple).
    static func storedDefault(single: Bool, defaultValue: OpenUIValue?) -> OpenUIValue? {
        if single {
            switch defaultValue {
            case .string(let string)?: return string.isEmpty ? nil : .string(string)
            case .array(let items)?:
                guard let first = items.first?.stringValue, !first.isEmpty else { return nil }
                return .string(first)
            default: return nil
            }
        }
        switch defaultValue {
        case .array(let items)?: return .array(items.filter { $0.stringValue != nil })
        case .string(let string)?: return .array(string.isEmpty ? [] : [.string(string)])
        default: return nil
        }
    }

    @MainActor
    static func hydrateDefault(runtime: OpenUIRuntime, formName: String?, componentType: String, name: String, single: Bool, defaultValue: OpenUIValue?) {
        FieldDefault.save(storedDefault(single: single, defaultValue: defaultValue), runtime: runtime, formName: formName, componentType: componentType, name: name)
    }

    static func toggle(single: Bool, selection: [String], value: String) -> [String] {
        if single {
            return selection.first == value ? [] : [value]
        }
        return selection.contains(value) ? selection.filter { $0 != value } : selection + [value]
    }
}

@available(iOS 17.0, macOS 14.0, *)
enum SliderValues {
    // The model writes the bounds, so they can be anything: SwiftUI's Slider needs finite bounds
    // whose difference is representable.
    static func bounds(minimum: Double?, maximum: Double?) -> ClosedRange<Double> {
        let limit = 1e15
        func bounded(_ value: Double?) -> Double? {
            value.flatMap { $0.isFinite ? Swift.min(Swift.max($0, -limit), limit) : nil }
        }
        let lower = bounded(minimum) ?? 0
        let upper = Swift.max(bounded(maximum) ?? 100, lower + 1)
        return lower...upper
    }

    static let maxSteps = 1000.0

    // The step values move by: the model's, or 1 for a discrete slider. It is finite, positive
    // and no larger than the range, which SwiftUI's Slider otherwise stops on with "max stride
    // must be positive".
    static func requestedStep(_ step: Double?, discrete: Bool, in bounds: ClosedRange<Double>) -> Double? {
        let span = bounds.upperBound - bounds.lowerBound
        if let step, step.isFinite, step > 0 {
            return step <= span ? step : nil
        }
        return discrete && span >= 1 ? 1 : nil
    }

    // The step SwiftUI's Slider gets: none when the range holds more than `maxSteps` of them, as
    // AppKit's tick marks crash on `max: 1e15` with a step of 1 and `step: 1e-8` hangs. Values
    // still snap to the requested step.
    static func step(_ step: Double?, discrete: Bool, in bounds: ClosedRange<Double>) -> Double? {
        guard let requested = requestedStep(step, discrete: discrete, in: bounds) else { return nil }
        return (bounds.upperBound - bounds.lowerBound) / requested <= maxSteps ? requested : nil
    }

    static func snapped(_ value: Double, to step: Double, in bounds: ClosedRange<Double>) -> Double {
        let steps = ((value - bounds.lowerBound) / step).rounded()
        return Swift.min(Swift.max(bounds.lowerBound + steps * step, bounds.lowerBound), bounds.upperBound)
    }

    static func values(_ value: OpenUIValue?, in bounds: ClosedRange<Double>) -> [Double] {
        let numbers: [Double]
        switch value {
        case .number(let number)?:
            numbers = [number]
        case .string?:
            numbers = [JS.toNumber(value)]
        case .array(let items)?:
            numbers = items.prefix(2).map { JS.toNumber($0) }
        default:
            numbers = []
        }
        let finite = numbers.filter(\.isFinite)
        return finite.isEmpty ? [bounds.lowerBound] : clamped(finite, to: bounds)
    }

    static func clamped(_ values: [Double], to bounds: ClosedRange<Double>) -> [Double] {
        let inBounds = values.prefix(2).map { Swift.min(Swift.max($0, bounds.lowerBound), bounds.upperBound) }
        return inBounds.count == 2 ? [Swift.min(inBounds[0], inBounds[1]), Swift.max(inBounds[0], inBounds[1])] : inBounds
    }

    // A range's thumbs stop at each other rather than cross.
    static func setting(_ values: [Double], index: Int, to value: Double) -> [Double] {
        guard values.indices.contains(index) else { return values }
        var next = values
        if values.count == 2 {
            next[index] = index == 0 ? Swift.min(value, values[1]) : Swift.max(value, values[0])
        } else {
            next[index] = value
        }
        return next
    }

    static func stored(_ values: [Double]) -> OpenUIValue {
        .array(values.map { .number(($0 * 1000).rounded() / 1000) })
    }

    static func accessibilityLabel(_ label: String, index: Int, count: Int) -> String {
        guard count == 2 else { return label }
        return index == 0 ? L10n.Slider.lower(label) : L10n.Slider.upper(label)
    }
}
