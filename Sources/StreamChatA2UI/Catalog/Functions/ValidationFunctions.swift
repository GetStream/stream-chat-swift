//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The validation functions of the A2UI basic catalog.
///
/// Every function returns a ``ValidationResult`` payload so that components can
/// show a message and, in the case of `Button`, disable themselves.
@available(iOS 15.0, macOS 12.0, *)
enum ValidationFunctions {
    /// All validation functions, in catalog order.
    static var all: [FunctionDefinition] {
        [required, regex, length, numeric, email]
    }

    /// Checks that a value is present and not empty.
    static let required = FunctionDefinition(
        name: "required",
        description: "Checks that the value is not null, undefined, or empty.",
        arguments: JsonSchema.object(
            properties: ["value": ["description": "The value to check."]],
            required: ["value"],
            additionalProperties: false
        ),
        returnType: .validationResult
    ) { invocation in
        let value = invocation.value("value")
        let isPresent: Bool
        switch value {
        case nil:
            isPresent = false
        case let string as String:
            isPresent = !string.isEmpty
        case let array as JsonArray:
            isPresent = !array.isEmpty
        default:
            isPresent = true
        }
        return isPresent
            ? ValidationResult.valid.rawValue
            : ValidationResult(isValid: false).rawValue
    }

    /// Checks that a value matches a regular expression.
    ///
    /// Empty values pass so that optional fields do not report an error before
    /// the user has typed anything; combine with `required` to make a field
    /// mandatory.
    static let regex = FunctionDefinition(
        name: "regex",
        description: "Checks that the value matches a regular expression string.",
        arguments: JsonSchema.object(
            properties: [
                "value": JsonSchema.dynamicString(),
                "pattern": JsonSchema.string(description: "The regex pattern to match against.")
            ],
            required: ["value", "pattern"],
            additionalProperties: false
        ),
        returnType: .validationResult
    ) { invocation in
        let pattern = try invocation.requireString("pattern")
        let value = invocation.string("value") ?? ""
        guard !value.isEmpty else { return ValidationResult.valid.rawValue }

        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            throw A2UIFunctionError.invalidArgument(
                "pattern",
                function: "regex",
                reason: "'\(pattern)' is not a valid regular expression."
            )
        }
        guard let matches = firstMatch(of: expression, in: value) else {
            throw A2UIFunctionError.invalidArgument(
                "pattern",
                function: "regex",
                reason: "'\(pattern)' took too long to match, so it can't be checked."
            )
        }
        return matches
            ? ValidationResult.valid.rawValue
            : ValidationResult(isValid: false).rawValue
    }

    // The agent writes the pattern, and one that backtracks, such as `^(a+)+$`, can take minutes
    // on a short value. `nil` when the match took longer than `timeout`.
    static func firstMatch(of expression: NSRegularExpression, in value: String, timeout: TimeInterval = 0.1) -> Bool? {
        let deadline = ProcessInfo.processInfo.systemUptime + timeout
        var found = false
        var timedOut = false
        expression.enumerateMatches(in: value, options: .reportProgress, range: NSRange(value.startIndex..., in: value)) { result, _, stop in
            if result != nil {
                found = true
                stop.pointee = true
            } else if ProcessInfo.processInfo.systemUptime > deadline {
                timedOut = true
                stop.pointee = true
            }
        }
        return timedOut ? nil : found
    }

    /// Checks the length of a string, or the number of items in an array,
    /// against `min` and `max` bounds.
    static let length = FunctionDefinition(
        name: "length",
        description: "Checks string length constraints.",
        arguments: JsonSchema.object(
            properties: [
                "value": JsonSchema.dynamicString(),
                "min": JsonSchema.integer(description: "The minimum allowed length.", minimum: 0),
                "max": JsonSchema.integer(description: "The maximum allowed length.", minimum: 0)
            ],
            required: ["value"],
            additionalProperties: false
        ),
        returnType: .validationResult
    ) { invocation in
        let count = invocation.array("value")?.count ?? (invocation.string("value") ?? "").count
        if let min = invocation.int("min"), count < min {
            return ValidationResult(isValid: false).rawValue
        }
        if let max = invocation.int("max"), count > max {
            return ValidationResult(isValid: false).rawValue
        }
        return ValidationResult.valid.rawValue
    }

    /// Checks that a number is within the `min` and `max` bounds.
    static let numeric = FunctionDefinition(
        name: "numeric",
        description: "Checks numeric range constraints.",
        arguments: JsonSchema.object(
            properties: [
                "value": JsonSchema.dynamicNumber(),
                "min": JsonSchema.number(description: "The minimum allowed value."),
                "max": JsonSchema.number(description: "The maximum allowed value.")
            ],
            required: ["value"],
            additionalProperties: false
        ),
        returnType: .validationResult
    ) { invocation in
        guard let rawValue = invocation.value("value"), !Json.isNull(rawValue) else {
            return ValidationResult.valid.rawValue
        }
        guard let value = Json.double(rawValue) else {
            return ValidationResult(isValid: false).rawValue
        }
        if let min = invocation.double("min"), value < min {
            return ValidationResult(isValid: false).rawValue
        }
        if let max = invocation.double("max"), value > max {
            return ValidationResult(isValid: false).rawValue
        }
        return ValidationResult.valid.rawValue
    }

    /// Checks that a value is a syntactically valid email address.
    static let email = FunctionDefinition(
        name: "email",
        description: "Checks that the value is a valid email address.",
        arguments: JsonSchema.object(
            properties: ["value": JsonSchema.dynamicString()],
            required: ["value"],
            additionalProperties: false
        ),
        returnType: .validationResult
    ) { invocation in
        let value = invocation.string("value") ?? ""
        guard !value.isEmpty else { return ValidationResult.valid.rawValue }
        return isValidEmail(value)
            ? ValidationResult.valid.rawValue
            : ValidationResult(isValid: false, code: "INVALID_EMAIL", message: invalidEmailMessage).rawValue
    }

    /// The message shown for a failed basic validation when neither the check nor the function gives one.
    static func defaultMessage(forFunction name: String) -> String? {
        switch name {
        case required.name: return "This field is required."
        case regex.name: return "This value has an invalid format."
        case length.name: return "This value has an invalid length."
        case numeric.name: return "Enter a number in the allowed range."
        default: return nil
        }
    }

    static let invalidEmailMessage = "Please enter a valid email address (e.g. user@example.com)."

    /// Validates an email address with a conservative pattern.
    /// Exposed for reuse by app-specific catalogs.
    static func isValidEmail(_ value: String) -> Bool {
        let range = NSRange(value.startIndex..., in: value)
        return emailExpression?.firstMatch(in: value, options: [], range: range) != nil
    }

    private static let emailExpression = try? NSRegularExpression(
        pattern: "^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*\\.[A-Za-z]{2,}$"
    )
}
