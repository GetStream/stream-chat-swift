//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A single component instance inside a surface.
///
/// A2UI v1.0 sends components as a flat adjacency list: every component has an
/// `id`, a `component` type discriminator and its type-specific properties
/// inline. Parent-child relationships are expressed with id references, so the
/// renderer rebuilds the tree at render time.
@available(iOS 15.0, macOS 12.0, *)
struct Component: Equatable, Sendable {
    /// Wire keys that belong to the component envelope rather than the catalog schema.
    static let envelopeKeys: Set<String> = ["id", "component", "catalogId", "accessibility", "metadata"]

    /// The unique id of this component within its surface.
    let id: String

    /// The catalog component type, for example `Text` or `Column`.
    let type: String

    /// The catalog that defines this component, overriding the surface default.
    let catalogId: String?

    /// Accessibility metadata for assistive technologies.
    let accessibility: AccessibilityAttributes?

    /// Vendor extension metadata attached to this instance.
    let metadata: JsonMap?

    /// The type-specific properties of the component.
    let properties: JsonMap

    /// Creates a component instance.
    /// `properties` must not contain envelope keys such as `id`.
    init(
        id: String,
        type: String,
        catalogId: String? = nil,
        accessibility: AccessibilityAttributes? = nil,
        metadata: JsonMap? = nil,
        properties: JsonMap = [:]
    ) {
        self.id = id
        self.type = type
        self.catalogId = catalogId
        self.accessibility = accessibility
        self.metadata = metadata
        self.properties = properties
    }

    /// Parses a component from a JSON object.
    /// Returns `nil` when the required `id` or `component` fields are missing.
    static func fromJson(_ json: JsonMap) -> Component? {
        guard let id = json["id"] as? String, !id.isEmpty,
              let type = json["component"] as? String, !type.isEmpty else {
            return nil
        }
        var properties = json
        for key in envelopeKeys {
            properties.removeValue(forKey: key)
        }
        return Component(
            id: id,
            type: type,
            catalogId: json["catalogId"] as? String,
            accessibility: AccessibilityAttributes(json["accessibility"]),
            metadata: Json.map(json["metadata"]),
            properties: properties
        )
    }

    /// The layout weight of this component inside a `Row` or `Column`.
    var weight: Double? {
        Json.double(properties["weight"])
    }

    /// Reads a raw property value.
    /// Returns `nil` when the property is absent or null.
    func property(_ key: String) -> (any Sendable)? {
        Json.normalized(properties[key])
    }

    /// Reads a property as a dynamic value.
    /// Missing properties produce ``DynamicValue/missing``.
    func dynamic(_ key: String) -> DynamicValue {
        DynamicValue(properties[key])
    }

    /// The validation rules declared by this component.
    var checks: [CheckRule] {
        CheckRule.list(properties["checks"])
    }

    /// The serialized wire representation of the component.
    func toJson() -> JsonMap {
        var json = properties
        json["id"] = id
        json["component"] = type
        if let catalogId { json["catalogId"] = catalogId }
        if let accessibility, !accessibility.rawValue.isEmpty { json["accessibility"] = accessibility.rawValue }
        if let metadata { json["metadata"] = metadata }
        return json
    }

    /// Compares two components by their wire representation.
    static func == (lhs: Component, rhs: Component) -> Bool {
        Json.isEqual(lhs.toJson(), rhs.toJson())
    }
}

// Surface and component metadata hold only `extensions`, whose keys are Unicode identifiers (UAX #31).
@available(iOS 15.0, macOS 12.0, *)
enum ExtensionMetadata {
    static func violation(in metadata: JsonMap) -> (pointer: String, reason: String)? {
        for key in metadata.keys.sorted() where key != "extensions" {
            return ("/\(escape(key))", "Metadata can only hold 'extensions', not '\(key)'.")
        }
        guard let raw = metadata["extensions"] else { return nil }
        guard let extensions = Json.map(raw) else {
            return ("/extensions", "'extensions' must be an object.")
        }
        for key in extensions.keys.sorted() where !A2UIIdentifier.isValid(key) {
            return ("/extensions/\(escape(key))", "The extension key '\(key)' must be a Unicode identifier (UAX #31).")
        }
        return nil
    }

    private static func escape(_ key: String) -> String {
        key.replacingOccurrences(of: "~", with: "~0").replacingOccurrences(of: "/", with: "~1")
    }
}

// The spec's naming rule for extension keys and catalog names: UAX #31 identifiers, which may start with `_`.
@available(iOS 15.0, macOS 12.0, *)
enum A2UIIdentifier {
    static func isValid(_ name: String) -> Bool {
        guard let first = name.unicodeScalars.first else { return false }
        guard first == "_" || first.properties.isXIDStart else { return false }
        return name.unicodeScalars.dropFirst().allSatisfy(\.properties.isXIDContinue)
    }
}
