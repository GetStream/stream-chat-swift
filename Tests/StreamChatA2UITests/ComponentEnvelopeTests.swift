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

        #expect(InputComponents.textField.checks(of: component).count == 1)
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

        #expect(InputComponents.textField.checks(of: component).count == 1)
        #expect(component.catalogId == "other")
        #expect(component.metadataKey == "metadata")
        #expect(component.properties.keys.sorted() == ["checks"])
    }

    @Test("An unprefixed catalogId, metadata or accessibility its catalog declares is that property, not the envelope field")
    func declaredUnprefixedKeysStayProperties() throws {
        let recorder = RenderRecorder()
        let status = ComponentDefinition(
            name: "Status",
            properties: [
                "catalogId": JsonSchema.string(),
                "metadata": JsonSchema.object(properties: ["owner": JsonSchema.string()]),
                "accessibility": JsonSchema.string()
            ]
        ) { context in
            recorder.record(context)
            return AnyView(EmptyView())
        }
        let harness = ProcessorHarness(catalogs: [TestCatalog.make(recorder: recorder, extraComponents: [status])])
        let message = try decodeMessage("""
        {"version": "1.0", "createSurface": {"surfaceId": "main", "catalogId": "\(TestCatalog.catalogId)", "components": [
            {"id": "root", "component": "Column", "children": ["status", "widget"]},
            {"id": "status", "component": "Status", "catalogId": "inventory", "metadata": {"owner": "me"}, "accessibility": "loud"},
            {"id": "widget", "component": "Widget", "catalogId": "inventory"}
        ]}}
        """)
        harness.processor.handle(message)

        let definition = try #require(harness.processor.surfaceViewModel("main").definition)
        let received = try #require(definition.component("status"))
        #expect(received.catalogId == nil)
        #expect(received.metadata == nil)
        #expect(received.accessibility == nil)
        #expect(received.property("catalogId") as? String == "inventory")
        #expect(Json.map(received.property("metadata"))?["owner"] as? String == "me")
        #expect(received.property("accessibility") as? String == "loud")
        let expected: JsonMap = [
            "id": "status", "component": "Status", "catalogId": "inventory", "metadata": ["owner": "me"] as JsonMap, "accessibility": "loud"
        ]
        #expect(Json.isEqual(received.toJson(), expected))
        let widgetErrors = harness.errors.filter { $0.path?.hasPrefix("/components/1") == true }
        #expect(widgetErrors.isEmpty)

        _ = harness.processor.makeRenderer(for: definition).rootView(
            dataContext: DataContext(harness.processor.dataModel(for: "main"), "/")
        )
        #expect(recorder.context("status")?.string("catalogId") == "inventory")

        // Where the catalog doesn't declare the key, it is still the envelope field.
        #expect(definition.component("widget")?.catalogId == "inventory")
        #expect(definition.component("widget")?.properties["catalogId"] == nil)
    }

    @Test("An unprefixed checks is validation only where the definition declares it as checks, and @checks always is")
    func unprefixedChecksNeedTheirDefinition() throws {
        let component = try #require(Component.fromJson([
            "id": "rating",
            "component": "Widget",
            "checks": [["condition": false, "message": "x"] as JsonMap] as JsonArray
        ]))
        let widget = try #require(TestCatalog.make(recorder: RenderRecorder()).component("Widget"))

        #expect(widget.checks(of: component).isEmpty)
        #expect(InputComponents.textField.checks(of: component).count == 1)

        let prefixed = try #require(Component.fromJson([
            "id": "rating",
            "component": "Widget",
            "@checks": [["condition": false, "message": "y"] as JsonMap] as JsonArray,
            "checks": [["condition": false, "message": "x"] as JsonMap] as JsonArray
        ]))
        #expect(widget.checks(of: prefixed).map(\.message) == ["y"])
        #expect(InputComponents.textField.checks(of: prefixed).map(\.message) == ["y"])
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
