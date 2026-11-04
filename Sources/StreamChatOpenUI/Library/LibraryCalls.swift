//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A function of the app's that programs call as `@Name(...)`, with positional arguments in the
/// order of `params` (upstream `defineFunction`).
///
/// ```swift
/// let percent = OpenUIFunction("Percent", description: "Share of a total, in percent", params: [
///     .required("part", .number),
///     .required("total", .number),
/// ], returns: .number) { args in
///     .number((args["part"]?.numberValue ?? 0) / (args["total"]?.numberValue ?? 1) * 100)
/// }
/// ```
///
/// Arguments are checked against `params`, and the result against `returns`. A call with invalid
/// arguments, or whose implementation throws, evaluates to null and reports a runtime error.
@available(iOS 17.0, macOS 14.0, *)
struct OpenUIFunction: Sendable {
    var name: String
    var description: String
    var params: [PropField]
    var returns: PropType?
    /// Runs the function with its arguments by name, schema defaults applied.
    var implementation: @Sendable (OpenUIObject) throws -> OpenUIValue

    init(
        _ name: String,
        description: String,
        params: [PropField],
        returns: PropType? = nil,
        implementation: @escaping @Sendable (OpenUIObject) throws -> OpenUIValue
    ) {
        self.name = name
        self.description = description
        self.params = params
        self.returns = returns
        self.implementation = implementation
    }

    var paramsSchema: OpenUIValue {
        PropField.objectSchema(params, description: nil)
    }

    /// The prompt signature: `Percent(part: number, total: number) → number`.
    var signature: String {
        let base = "\(name)(" + params.map(\.signature).joined(separator: ", ") + ")"
        return returns.map { "\(base) → \($0.signature)" } ?? base
    }
}

/// An action step of the app's, used like the built-in steps: `Button("Copy", @CopyToClipboard(id))`
/// or inside `Action([...])` (upstream `defineAction`).
///
/// On click it reaches `OpenUIRuntime.onAction` as an ``ActionEvent`` whose `type` is the action's
/// name and whose `params` are its arguments. A step with invalid arguments does nothing.
@available(iOS 17.0, macOS 14.0, *)
struct OpenUICustomAction: Sendable, Hashable {
    var name: String
    var description: String
    var params: [PropField]

    init(_ name: String, description: String, params: [PropField]) {
        self.name = name
        self.description = description
        self.params = params
    }

    var paramsSchema: OpenUIValue {
        PropField.objectSchema(params, description: nil)
    }

    /// The prompt signature: `CopyToClipboard(text: string)`.
    var signature: String {
        "\(name)(" + params.map(\.signature).joined(separator: ", ") + ")"
    }

    /// The JSON shape of a step of this action, the `$defs` entry a slot that takes only some
    /// actions refers to: `{type: "CopyToClipboard", params: {...}}`.
    var stepSchema: OpenUIValue {
        PropField.objectSchema([.required("type", .literal(name)), .required("params", .object(params))], description: nil)
    }
}
