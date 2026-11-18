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

    // The key the metadata came in, `@metadata` or `metadata`, which errors in it point at.
    let metadataKey: String

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
        metadataKey: String = "metadata",
        properties: JsonMap = [:]
    ) {
        self.id = id
        self.type = type
        self.catalogId = catalogId
        self.accessibility = accessibility
        self.metadata = metadata
        self.metadataKey = metadataKey
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
        properties.removeValue(forKey: "id")
        properties.removeValue(forKey: "component")
        // An envelope field the spec writes with an `@` is also read without it, as earlier
        // versions and the conformance suite's messages write it, unless the `@` form is there
        // too: then the unprefixed key is a catalog property like any other.
        func envelope(_ field: String) -> (key: String, value: (any Sendable)?) {
            let key = json["@" + field] == nil ? field : "@" + field
            return (key, Json.normalized(properties.removeValue(forKey: key)))
        }
        let catalogId = envelope("catalogId")
        let accessibility = envelope("accessibility")
        let metadata = envelope("metadata")
        return Component(
            id: id,
            type: type,
            catalogId: catalogId.value as? String,
            accessibility: AccessibilityAttributes(accessibility.value),
            metadata: Json.map(metadata.value),
            metadataKey: metadata.key,
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

    /// The validation rules declared by this component, in `@checks`, or in `checks` as this
    /// renderer's catalog schemas name them.
    var checks: [CheckRule] {
        CheckRule.list(properties["@checks"] ?? properties["checks"])
    }

    /// The serialized wire representation of the component.
    func toJson() -> JsonMap {
        var json = properties
        json["id"] = id
        json["component"] = type
        // A field takes its `@` form only where a catalog property has the unprefixed key.
        func key(_ field: String) -> String {
            properties[field] == nil ? field : "@" + field
        }
        if let catalogId { json[key("catalogId")] = catalogId }
        if let accessibility, !accessibility.rawValue.isEmpty { json[key("accessibility")] = accessibility.rawValue }
        if let metadata { json[key("metadata")] = metadata }
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
