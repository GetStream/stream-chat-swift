//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A renderer-side function implementation.
///
/// Implementations receive already-resolved arguments, so nested bindings and
/// function calls have been evaluated before the function runs.
@available(iOS 15.0, macOS 12.0, *)
typealias A2UIFunctionImplementation = @MainActor @Sendable (FunctionInvocation) throws -> (any Sendable)?

/// The arguments and environment of a single function invocation.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
struct FunctionInvocation {
    /// The name of the invoked function.
    let name: String

    /// The resolved arguments of the call.
    let arguments: [String: any Sendable]

    /// The data scope the call was evaluated in.
    let context: DataContext

    /// Host capabilities such as URL opening and the current locale.
    let services: RendererServices

    private let evaluator: ExpressionEvaluator

    /// Creates an invocation.
    /// The renderer builds these; catalog code only reads them.
    init(
        name: String,
        arguments: [String: any Sendable],
        context: DataContext,
        services: RendererServices,
        evaluator: ExpressionEvaluator
    ) {
        self.name = name
        self.arguments = arguments
        self.context = context
        self.services = services
        self.evaluator = evaluator
    }

    /// Reads a raw argument value.
    /// Returns `nil` when the argument is absent or null.
    func value(_ key: String) -> (any Sendable)? {
        Json.normalized(arguments[key])
    }

    /// Reads an argument as a string, coercing other JSON types.
    func string(_ key: String) -> String? {
        Json.string(value(key))
    }

    /// Reads an argument as a number, parsing numeric strings.
    func double(_ key: String) -> Double? {
        Json.double(value(key))
    }

    /// Reads an argument as an integer.
    func int(_ key: String) -> Int? {
        Json.int(value(key))
    }

    /// Reads an argument as a boolean.
    /// A validation result reads as its `valid` flag.
    func bool(_ key: String) -> Bool? {
        guard let value = value(key) else { return nil }
        if let map = Json.map(value), map["valid"] != nil {
            return Json.bool(map["valid"])
        }
        return Json.bool(value)
    }

    /// Reads an argument as an array.
    func array(_ key: String) -> JsonArray? {
        Json.array(value(key))
    }

    /// Requires a string argument.
    /// Throws when the argument is missing.
    func requireString(_ key: String) throws -> String {
        guard let value = string(key) else {
            throw A2UIFunctionError.missingArgument(key, function: name)
        }
        return value
    }

    /// Requires a numeric argument.
    /// Throws when the argument is missing or not numeric.
    func requireDouble(_ key: String) throws -> Double {
        guard let value = double(key) else {
            throw A2UIFunctionError.missingArgument(key, function: name)
        }
        return value
    }

    /// Evaluates a nested expression in the invocation's scope.
    /// Used by `formatString` to resolve interpolated expressions.
    func evaluateInterpolation(_ template: String) throws -> String {
        try evaluator.interpolate(template, in: context)
    }
}

/// Errors raised by renderer-side function implementations.
@available(iOS 15.0, macOS 12.0, *)
enum A2UIFunctionError: Error, Equatable, CustomStringConvertible {
    /// A required argument was not provided.
    case missingArgument(String, function: String)

    /// An argument had a value the function cannot handle.
    case invalidArgument(String, function: String, reason: String)

    /// The function is not available in the current context.
    case unavailable(String, reason: String)

    /// A human-readable description of the failure.
    var description: String {
        switch self {
        case let .missingArgument(key, function):
            return "Function '\(function)' requires the argument '\(key)'."
        case let .invalidArgument(key, function, reason):
            return "Function '\(function)' received an invalid value for '\(key)': \(reason)"
        case let .unavailable(function, reason):
            return "Function '\(function)' is unavailable: \(reason)"
        }
    }

    /// The machine-readable error code reported to the agent.
    var code: String {
        switch self {
        case .missingArgument, .invalidArgument:
            return RendererError.Code.invalidFunctionCall
        case .unavailable:
            return RendererError.Code.executionError
        }
    }
}
