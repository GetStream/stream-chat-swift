//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A dynamically typed value flowing through the OpenUI pipeline.
///
/// OpenUI Lang is evaluated with JavaScript semantics in the reference implementation, so the
/// runtime works on JSON-like values. On top of plain JSON, two kinds of values can appear in
/// component props:
/// - ``element(_:)``: a parsed component invocation (``ElementNode``).
/// - ``expression(_:)``: a runtime expression (``ASTNode``) preserved by the parser and resolved
///   by the evaluator (state references, query results, operators, action plans, ...).
@available(iOS 17.0, macOS 14.0, *)
enum OpenUIValue: Sendable, Hashable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([OpenUIValue])
    case object(OpenUIObject)
    case element(ElementNode)
    case expression(ASTNode)
}

// MARK: - Accessors

@available(iOS 17.0, macOS 14.0, *)
extension OpenUIValue {
    var isNull: Bool {
        if case .null = self { return true }
        return false
    }

    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var numberValue: Double? {
        if case .number(let value) = self { return value }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    var arrayValue: [OpenUIValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    var objectValue: OpenUIObject? {
        if case .object(let value) = self { return value }
        return nil
    }

    var elementValue: ElementNode? {
        if case .element(let value) = self { return value }
        return nil
    }

    var expressionValue: ASTNode? {
        if case .expression(let value) = self { return value }
        return nil
    }

    /// Reads a property the way JavaScript's `value[key]` would (own properties only).
    subscript(key: String) -> OpenUIValue? {
        JS.property(of: self, key: key)
    }

    /// This value with elements and expressions converted (deeply) to their plain JSON object shapes.
    var plainJSON: OpenUIValue {
        switch self {
        case .number(let number) where !number.isFinite:
            return .null
        case .null, .bool, .number, .string:
            return self
        case .array(let items):
            return .array(items.map(\.plainJSON))
        case .object(var object):
            // The token that marks custom steps real calls made never leaves the runtime.
            _ = object.removeValue(forKey: ActionPlan.callTokenKey)
            return .object(object.mapValues(\.plainJSON))
        case .element(let element):
            return element.jsonValue
        case .expression(let node):
            return node.jsonValue
        }
    }
}

// MARK: - Literals

@available(iOS 17.0, macOS 14.0, *)
extension OpenUIValue: ExpressibleByBooleanLiteral {
    init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension OpenUIValue: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension OpenUIValue: ExpressibleByFloatLiteral {
    init(floatLiteral value: Double) {
        self = .number(value)
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension OpenUIValue: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self = .string(value)
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension OpenUIValue: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: OpenUIValue...) {
        self = .array(elements)
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension OpenUIValue: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (String, OpenUIValue)...) {
        self = .object(OpenUIObject(elements))
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension OpenUIValue: CustomStringConvertible {
    var description: String {
        JS.jsonStringify(self) ?? "undefined"
    }
}
