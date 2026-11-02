//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A parsed validation rule, e.g. `required`, `minLength:3`, `pattern:^[a-z]+$`.
@available(iOS 17.0, macOS 14.0, *)
public struct ValidationRule: Sendable, Hashable {
    public var type: String
    public var argument: OpenUIValue?

    public init(type: String, argument: OpenUIValue? = nil) {
        self.type = type
        self.argument = argument
    }
}

/// Form field validation (port of `utils/validation.ts`).
@available(iOS 17.0, macOS 14.0, *)
public enum FormValidation {
    public typealias Validator = @Sendable (OpenUIValue?, OpenUIValue?) -> String?

    private static let numericRules: Set<String> = ["min", "max", "minLength", "maxLength"]

    /// Parses `"min:8"`-style rule strings.
    public static func parseRule(_ rule: String) -> ValidationRule {
        guard let colon = rule.firstIndex(of: ":") else { return ValidationRule(type: rule) }
        let type = String(rule[..<colon])
        let rawArgument = String(rule[rule.index(after: colon)...])
        if numericRules.contains(type), !JS.stringToNumber(rawArgument).isNaN {
            return ValidationRule(type: type, argument: .number(JS.stringToNumber(rawArgument)))
        }
        return ValidationRule(type: type, argument: .string(rawArgument))
    }

    /// Parses an array of rule strings (non-strings are ignored).
    public static func parseRules(_ rules: OpenUIValue?) -> [ValidationRule] {
        guard case .array(let items)? = rules else { return [] }
        return items.compactMap(\.stringValue).map(parseRule)
    }

    /// Parses a structured rules object: `{required: true, minLength: 5, email: true}`.
    /// Keys with `false`/`null` values are skipped.
    public static func parseStructuredRules(_ rules: OpenUIValue?) -> [ValidationRule] {
        guard case .object(let object)? = rules else { return [] }
        return object.entries.compactMap { key, value in
            switch value {
            case .bool(false), .null: return nil
            case .bool(true): return ValidationRule(type: key)
            default: return ValidationRule(type: key, argument: value)
            }
        }
    }

    /// Parses either rule format.
    public static func rules(from value: OpenUIValue?) -> [ValidationRule] {
        if case .array? = value { return parseRules(value) }
        return parseStructuredRules(value)
    }

    static func isEmpty(_ value: OpenUIValue?) -> Bool {
        guard let value else { return true }
        switch value {
        case .null: return true
        case .string(let string): return string.isEmpty
        case .array(let items): return items.isEmpty
        case .object(let object):
            // Form state stores { value, componentType } — validate the actual value.
            if let wrapped = object["value"] { return isEmpty(wrapped) }
            return object.isEmpty
        default:
            return false
        }
    }

    private static func number(_ value: OpenUIValue?) -> Double {
        if case .number(let number)? = value { return number }
        return JS.parseFloat(JS.toString(value))
    }

    public static let builtInValidators: [String: Validator] = [
        "required": { value, _ in
            if isEmpty(value) { return L10n.Validation.required }
            if case .object(let object)? = value {
                let values = object.values
                if !values.isEmpty, values.allSatisfy({ $0.boolValue != nil }), !values.contains(.bool(true)) {
                    return L10n.Validation.requiredOption
                }
            }
            return nil
        },
        "email": { value, _ in
            if isEmpty(value) { return nil }
            guard case .string(let string)? = value else { return L10n.Validation.email }
            let valid = string.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
            return valid ? nil : L10n.Validation.email
        },
        "url": { value, _ in
            if isEmpty(value) { return nil }
            guard case .string(let string)? = value,
                  let components = URLComponents(string: string),
                  let scheme = components.scheme, !scheme.isEmpty,
                  string.contains(":") else { return L10n.Validation.url }
            return nil
        },
        "numeric": { value, _ in
            if isEmpty(value) { return nil }
            if case .number(let number)? = value, !number.isNaN { return nil }
            if case .string(let string)? = value, !JS.parseFloat(string).isNaN, !JS.trim(string).isEmpty { return nil }
            return L10n.Validation.numeric
        },
        "min": { value, argument in
            if isEmpty(value) { return nil }
            let n = number(value)
            if n.isNaN { return nil }
            let min = JS.toNumber(argument)
            return n >= min ? nil : L10n.Validation.min(JS.numberToString(min))
        },
        "max": { value, argument in
            if isEmpty(value) { return nil }
            let n = number(value)
            if n.isNaN { return nil }
            let max = JS.toNumber(argument)
            return n <= max ? nil : L10n.Validation.max(JS.numberToString(max))
        },
        "minLength": { value, argument in
            if isEmpty(value) { return nil }
            guard case .string(let string)? = value else { return nil }
            let min = JS.toNumber(argument)
            return Double(string.utf16.count) >= min ? nil : L10n.Validation.minLength(JS.numberToString(min))
        },
        "maxLength": { value, argument in
            if isEmpty(value) { return nil }
            guard case .string(let string)? = value else { return nil }
            let max = JS.toNumber(argument)
            return Double(string.utf16.count) <= max ? nil : L10n.Validation.maxLength(JS.numberToString(max))
        },
        "pattern": { value, argument in
            if isEmpty(value) { return nil }
            guard case .string(let string)? = value, case .string(let pattern)? = argument,
                  let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
            let range = NSRange(string.startIndex..., in: string)
            return regex.firstMatch(in: string, range: range) != nil ? nil : L10n.Validation.pattern
        }
    ]

    /// Runs rules against a value, stopping at the first error. Custom validators take precedence.
    public static func validate(_ value: OpenUIValue?, rules: [ValidationRule], customValidators: [String: Validator] = [:]) -> String? {
        for rule in rules {
            guard let validator = customValidators[rule.type] ?? builtInValidators[rule.type] else { continue }
            if let error = validator(value, rule.argument) { return error }
        }
        return nil
    }
}
