//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatA2UI
import SwiftUI
import Testing
@MainActor
@Suite("Component envelope and malformed components")
struct ComponentEnvelopeTests {
    @Test("The spec's @ envelope keys are read, and an unprefixed key beside one stays a catalog property")
    func prefixedEnvelopeKeys() throws {
        let component = try #require(Component.fromJson([
            "id": "email",
            "component": "TextField",
            "@checks": [["condition": true, "message": "x"] as JsonMap] as JsonArray,
            "checks": "Two rules",
            "@accessibility": ["label": "Work email"] as JsonMap,
            "@catalogId": "other",
            "catalogId": "custom",
            "@metadata": ["extensions": [:] as JsonMap] as JsonMap
        ]))

        #expect(component.checks.count == 1)
        #expect(component.catalogId == "other")
        #expect(component.accessibility?.label.rawValue as? String == "Work email")
        #expect(component.metadata != nil)
        #expect(component.metadataKey == "@metadata")
        #expect(component.property("catalogId") as? String == "custom")
        #expect(component.property("checks") as? String == "Two rules")
        #expect(component.properties.keys.sorted() == ["@checks", "catalogId", "checks"])

        let json = component.toJson()
        #expect(json["@catalogId"] as? String == "other")
        #expect(json["catalogId"] as? String == "custom")
        #expect(Component.fromJson(json) == component)
    }

    @Test("An unprefixed envelope key without its @ form is still the envelope field")
    func unprefixedEnvelopeKeys() throws {
        let component = try #require(Component.fromJson([
            "id": "email",
            "component": "TextField",
            "checks": [["condition": true, "message": "x"] as JsonMap] as JsonArray,
            "catalogId": "other",
            "metadata": ["extensions": [:] as JsonMap] as JsonMap
        ]))

        #expect(component.checks.count == 1)
        #expect(component.catalogId == "other")
        #expect(component.metadataKey == "metadata")
        #expect(component.properties.keys.sorted() == ["checks"])
    }

    @Test("An error in a component's @metadata points at @metadata")
    func prefixedMetadataErrorPointer() throws {
        let harness = ProcessorHarness()
        let message = try decodeMessage("""
        {"version": "1.0", "createSurface": {"surfaceId": "main", "catalogId": "\(TestCatalog.catalogId)", "components": [
            {"id": "root", "component": "Text", "text": "Hi", "@metadata": {"owner": "me"}}
        ]}}
        """)
        harness.processor.handle(message)

        #expect(harness.errors.map(\.path) == ["/components/0/@metadata/owner"])
    }

    @Test("A component without an id or type is reported, and errors point at the entry in the message")
    func malformedComponents() throws {
        let harness = ProcessorHarness()
        let message = try decodeMessage("""
        {"version": "1.0", "createSurface": {"surfaceId": "main", "catalogId": "\(TestCatalog.catalogId)", "components": [
            {"id": "title", "type": "Text"},
            "nope",
            {"id": "b", "component": "Buton"}
        ]}}
        """)
        harness.processor.handle(message)

        #expect(harness.errors.map(\.path) == ["/components/0/component", "/components/1", "/components/2/component"])
        #expect(harness.errors.allSatisfy { $0.code == RendererError.Code.validationFailed })
    }
}
