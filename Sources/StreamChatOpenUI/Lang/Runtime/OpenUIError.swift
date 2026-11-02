//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A structured, LLM-friendly error from the OpenUI pipeline (mirrors `OpenUIError`).
///
/// Only errors that can be fixed by changing the OpenUI Lang code are reported, which makes them
/// suitable for an automated correction loop (send them back to the model as a follow-up).
@available(iOS 17.0, macOS 14.0, *)
public struct OpenUIError: Sendable, Hashable, CustomStringConvertible {
    public enum Source: String, Sendable, Hashable {
        case parser, runtime, query, mutation
    }

    public var source: Source
    /// Machine-readable code, e.g. `unknown-component`, `missing-required`, `tool-not-found`.
    public var code: String
    public var message: String
    /// Statement to patch (e.g. `"header"`).
    public var statementId: String?
    public var component: String?
    /// Prop path, e.g. `"/title"`.
    public var path: String?
    /// Tool name for query/mutation errors.
    public var toolName: String?
    /// Actionable fix context (available components, the correct signature, ...).
    public var hint: String?

    public init(
        source: Source,
        code: String,
        message: String,
        statementId: String? = nil,
        component: String? = nil,
        path: String? = nil,
        toolName: String? = nil,
        hint: String? = nil
    ) {
        self.source = source
        self.code = code
        self.message = message
        self.statementId = statementId
        self.component = component
        self.path = path
        self.toolName = toolName
        self.hint = hint
    }

    public var description: String {
        "\(source.rawValue)/\(code): \(message)"
    }

    /// Converts parser validation errors into enriched errors with hints (port of `enrichErrors`).
    static func enriched(_ errors: [ValidationError], schema: OpenUIValue, componentNames: [String]) -> [OpenUIError] {
        errors.map { error in
            var enriched = OpenUIError(
                source: .parser,
                code: error.code.rawValue,
                message: error.message,
                statementId: error.statementId,
                component: error.component,
                path: error.path.isEmpty ? nil : error.path
            )
            switch error.code {
            case .unknownComponent where !componentNames.isEmpty:
                enriched.hint = "Available components: " + componentNames.joined(separator: ", ")
            case .missingRequired, .nullRequired:
                enriched.hint = signatureHint(component: error.component, definition: schema["$defs"]?[error.component])
            case .inlineReserved:
                enriched.hint = "Declare as a top-level statement: myVar = \(error.component)(...)"
            default:
                break
            }
            return enriched
        }
    }

    private static func signatureHint(component: String, definition: OpenUIValue?) -> String? {
        guard case .object(let properties)? = definition?["properties"] else { return nil }
        let required = Set(definition?["required"]?.arrayValue?.compactMap(\.stringValue) ?? [])
        let params = properties.keys.map { required.contains($0) ? "\($0)*" : $0 }.joined(separator: ", ")
        return "Signature: \(component)(\(params)) — * marks required"
    }
}
