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
public final class FormValidationModel {
    public private(set) var errors: [String: String] = [:]

    private struct Registration {
        var rules: [ValidationRule]
        var value: @MainActor () -> OpenUIValue?
    }

    @ObservationIgnored private var fields: [String: Registration] = [:]

    public init() {}

    public func error(for name: String) -> String? {
        errors[name]
    }

    public func register(_ name: String, rules: [ValidationRule], value: @escaping @MainActor () -> OpenUIValue?) {
        fields[name] = Registration(rules: rules, value: value)
    }

    public func unregister(_ name: String) {
        fields.removeValue(forKey: name)
    }

    @discardableResult
    public func validateField(_ name: String, value: OpenUIValue?, rules: [ValidationRule]) -> Bool {
        let error = FormValidation.validate(value, rules: rules)
        if errors[name] != error { errors[name] = error }
        return error == nil
    }

    /// Validates every registered field; returns `true` when the form is valid.
    public func validateForm() -> Bool {
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

    public func clearError(_ name: String) {
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
public extension EnvironmentValues {
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

    static func toggle(single: Bool, selection: [String], value: String) -> [String] {
        if single {
            return selection.first == value ? [] : [value]
        }
        return selection.contains(value) ? selection.filter { $0 != value } : selection + [value]
    }
}
