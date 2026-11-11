//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The logical functions of the A2UI basic catalog.
///
/// Logical functions accept booleans as well as ``ValidationResult`` payloads,
/// so validation functions can be combined directly, as shown by the
/// specification's button validation example.
@available(iOS 15.0, macOS 12.0, *)
enum LogicFunctions {
    /// All logical functions, in catalog order.
    static var all: [FunctionDefinition] {
        [and, or, not]
    }

    /// Returns `true` when every value is truthy.
    static let and = FunctionDefinition(
        name: "and",
        description: "Performs a logical AND operation on a list of boolean values.",
        arguments: JsonSchema.object(
            properties: [
                "values": JsonSchema.array(
                    description: "The list of boolean values to evaluate.",
                    items: JsonSchema.dynamicBoolean(),
                    minItems: 2
                )
            ],
            required: ["values"],
            additionalProperties: false
        ),
        returnType: .boolean
    ) { invocation in
        try values(of: invocation).allSatisfy { truthy($0) }
    }

    /// Returns `true` when at least one value is truthy.
    static let or = FunctionDefinition(
        name: "or",
        description: "Performs a logical OR operation on a list of boolean values.",
        arguments: JsonSchema.object(
            properties: [
                "values": JsonSchema.array(
                    description: "The list of boolean values to evaluate.",
                    items: JsonSchema.dynamicBoolean(),
                    minItems: 2
                )
            ],
            required: ["values"],
            additionalProperties: false
        ),
        returnType: .boolean
    ) { invocation in
        try values(of: invocation).contains { truthy($0) }
    }

    /// Returns the negation of a value.
    static let not = FunctionDefinition(
        name: "not",
        description: "Performs a logical NOT operation on a boolean value.",
        arguments: JsonSchema.object(
            properties: ["value": JsonSchema.dynamicBoolean(description: "The boolean value to negate.")],
            required: ["value"],
            additionalProperties: false
        ),
        returnType: .boolean
    ) { invocation in
        !truthy(invocation.value("value"))
    }

    @MainActor
    private static func values(of invocation: FunctionInvocation) throws -> JsonArray {
        guard let values = invocation.array("values"), values.count >= 2 else {
            throw A2UIFunctionError.invalidArgument(
                "values",
                function: invocation.name,
                reason: "At least two values are required."
            )
        }
        return values
    }

    /// Coerces a value to a boolean.
    ///
    /// Validation results are truthy when they are valid, which lets `and`,
    /// `or` and `not` compose validation functions.
    static func truthy(_ value: (any Sendable)?) -> Bool {
        guard let value = Json.normalized(value) else { return false }
        if let map = value as? JsonMap, let isValid = Json.bool(map["valid"]) {
            return isValid
        }
        if let bool = Json.bool(value) { return bool }
        if let string = value as? String { return !string.isEmpty }
        if let array = value as? JsonArray { return !array.isEmpty }
        if let map = value as? JsonMap { return !map.isEmpty }
        return true
    }
}
