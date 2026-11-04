//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// Read access to a component's evaluated props with lenient, JavaScript-like conversions.
@available(iOS 17.0, macOS 14.0, *)
public struct ComponentProps: Sendable {
    let values: OpenUIObject

    init(_ values: OpenUIObject) {
        self.values = values
    }

    subscript(key: String) -> OpenUIValue? {
        values[key]
    }

    /// The value if it is a string.
    public func string(_ key: String) -> String? {
        values[key]?.stringValue
    }

    /// The value converted to display text (`String(value)`), or `nil` when null/absent.
    public func text(_ key: String) -> String? {
        let value = values[key]
        if JS.isNullish(value) { return nil }
        return JS.toString(value)
    }

    /// The value as a number (numbers and numeric strings).
    public func number(_ key: String) -> Double? {
        switch values[key] {
        case .number(let number)?: return number
        case .string(let string)?:
            let number = JS.stringToNumber(string)
            return number.isNaN ? nil : number
        default: return nil
        }
    }

    /// The value as a boolean (booleans and `"true"`/`"false"` strings).
    public func bool(_ key: String) -> Bool? {
        switch values[key] {
        case .bool(let bool)?: return bool
        case .string("true")?: return true
        case .string("false")?: return false
        default: return nil
        }
    }

    /// The value as an array: arrays as-is, `null`/absent as `[]`, anything else wrapped (`asArray`).
    func array(_ key: String) -> [OpenUIValue] {
        switch values[key] {
        case .array(let items)?: return items
        case nil, .null?: return []
        case let value?: return [value]
        }
    }

    /// Element nodes in an array prop (non-elements are skipped).
    func elements(_ key: String) -> [ElementNode] {
        array(key).compactMap(\.elementValue)
    }

    /// The value if it is an element.
    func element(_ key: String) -> ElementNode? {
        values[key]?.elementValue
    }

    /// The value if it is an object.
    func object(_ key: String) -> OpenUIObject? {
        values[key]?.objectValue
    }

    /// String array (non-strings converted with `String(value)`).
    public func strings(_ key: String) -> [String] {
        array(key).map { JS.isNullish($0) ? "" : JS.toString($0) }
    }

    /// Number array (non-numbers coerced, invalid values become 0).
    public func numbers(_ key: String) -> [Double] {
        array(key).map { JS.toNumber($0) }
    }
}

/// Everything a component renderer needs: its element, evaluated props and the runtime.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
public struct ComponentContext {
    let element: ElementNode
    let runtime: OpenUIRuntime
    // The library's own view of the component, when an app replaced it.
    var defaultRenderer: ComponentRenderer?

    init(element: ElementNode, runtime: OpenUIRuntime) {
        self.element = element
        self.runtime = runtime
    }

    /// The library's own view of the component, to wrap or restyle in a view that replaces it.
    /// It keeps the component's validation and actions.
    public var defaultView: some View {
        defaultRenderer.map { $0(self) }
    }

    /// The view of a prop that holds components, such as a card's `children`.
    public func view(of prop: String) -> some View {
        render(prop: prop)
    }

    public var props: ComponentProps { ComponentProps(element.props) }
    var typeName: String { element.typeName }
    var statementId: String? { element.statementId }
    public var isStreaming: Bool { runtime.isStreaming }

    /// Renders any prop value (an element, an array of elements, or a primitive).
    func render(_ value: OpenUIValue?) -> OpenUINodeView {
        OpenUINodeView(value: value)
    }

    /// Renders a prop by name.
    func render(prop key: String) -> OpenUINodeView {
        OpenUINodeView(value: element.props[key])
    }

    /// A copy of an element with some props overridden (used by parents to style children).
    static func overriding(_ element: ElementNode, _ overrides: OpenUIObject) -> ElementNode {
        var copy = element
        for (key, value) in overrides.entries {
            copy.props[key] = value
        }
        return copy
    }
}
