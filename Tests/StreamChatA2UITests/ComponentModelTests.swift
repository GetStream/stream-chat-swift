//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatA2UI
import Testing

@MainActor
@Suite("Components")
struct ComponentTests {
    @Test("Envelope fields are separated from catalog properties")
    func envelopeSplit() throws {
        let component = try #require(
            Component.fromJson(
                [
                    "id": "title",
                    "component": "Text",
                    "catalogId": "app:catalog",
                    "accessibility": ["label": "Heading", "live": "polite"] as JsonMap,
                    "metadata": ["extensions": ["com_acme_tag": "hero"] as JsonMap] as JsonMap,
                    "text": "Hello",
                    "weight": 2
                ]
            )
        )

        #expect(component.id == "title")
        #expect(component.type == "Text")
        #expect(component.catalogId == "app:catalog")
        #expect(component.accessibility?.live == .polite)
        #expect(component.weight == 2)
        #expect(component.properties.keys.sorted() == ["text", "weight"])
        #expect(Json.map(component.metadata?["extensions"])?["com_acme_tag"] as? String == "hero")
    }

    @Test("Components without an id or type are rejected")
    func requiredFields() {
        #expect(Component.fromJson(["component": "Text"]) == nil)
        #expect(Component.fromJson(["id": "a"]) == nil)
        #expect(Component.fromJson(["id": "", "component": "Text"]) == nil)
    }

    @Test("Serialization restores the original payload")
    func roundTrip() throws {
        let json: JsonMap = [
            "id": "root",
            "component": "Column",
            "children": ["a", "b"],
            "align": "stretch"
        ]
        let component = try #require(Component.fromJson(json))

        #expect(Json.isEqual(component.toJson(), json))
        #expect(component == Component.fromJson(component.toJson()))
    }

    @Test("Checks are parsed from the component properties")
    func checks() throws {
        let component = try #require(
            Component.fromJson(
                [
                    "id": "field",
                    "component": "TextField",
                    "checks": [
                        ["condition": ["@call": "required", "args": ["value": ["@path": "/a"]]] as JsonMap, "message": "Required."] as JsonMap,
                        ["message": "no condition"]
                    ] as JsonArray
                ]
            )
        )

        #expect(component.checks.count == 1)
        #expect(component.checks[0].message == "Required.")
    }
}

@MainActor
@Suite("Dynamic values")
struct DynamicValueTests {
    @Test("Literals, bindings and calls are told apart")
    func classification() {
        #expect(DynamicValue("text") == .literal("text"))
        #expect(DynamicValue(["@path": "/a/b"]) == .binding(DataPath("/a/b")))
        #expect(DynamicValue(nil).isMissing)
        #expect(DynamicValue(NSNull()).isMissing)

        guard case let .function(call) = DynamicValue(["@call": "formatString", "args": ["value": "hi"]] as JsonMap) else {
            Issue.record("Expected a function call")
            return
        }
        #expect(call.name == "formatString")
        #expect(Json.string(call.arguments["value"]) == "hi")
    }

    @Test("Objects that are not bindings or calls stay literals")
    func objectLiterals() {
        #expect(DynamicValue(["label": "x"]).literalValue != nil)
        #expect(Json.map(DynamicValue(["path": "/a", "call": "audit"]).literalValue)?["path"] as? String == "/a")
    }

    @Test("Objects that misuse the reserved @ prefix are dropped")
    func reservedKeyMisuse() {
        #expect(DynamicValue(["@path": "/a", "extra": 1] as JsonMap).isMissing)
        #expect(DynamicValue(["@if": true, "then": "active"] as JsonMap).isMissing)
        #expect(DynamicValue(["@": "reserved"]).isMissing)
        #expect(DynamicValue(["@call": 1]).isMissing)
    }

    @Test("Doubled @ keys are unescaped into literal keys")
    func escapedKeys() {
        let literal = Json.map(DynamicValue(["@@path": "/static/file", "@@type": "Resource"]).literalValue)
        #expect(literal?["@path"] as? String == "/static/file")
        #expect(literal?["@type"] as? String == "Resource")
    }

    @Test("Reserved key violations are found in nested values")
    func reservedKeyViolations() {
        #expect(DynamicValue.reservedKeyViolation(in: ["@path": "/a"]) == nil)
        #expect(DynamicValue.reservedKeyViolation(in: ["@@type": "x"]) == nil)
        #expect(DynamicValue.reservedKeyViolation(in: ["@path": 1]) != nil)
        #expect(DynamicValue.reservedKeyViolation(in: ["@call": "f", "args": "x"] as JsonMap) != nil)
        #expect(DynamicValue.reservedKeyViolation(in: ["@call": 2]) != nil)
        #expect(
            DynamicValue.reservedKeyViolation(
                in: ["@call": "and", "args": ["values": [["@x": 1] as JsonMap] as JsonArray] as JsonMap] as JsonMap
            ) != nil
        )
        #expect(DynamicValue.reservedKeyViolation(in: [["a": ["@bad": 1]] as JsonMap] as JsonArray) != nil)
    }

    @Test("Dynamic values round-trip to their wire form")
    func roundTrip() {
        #expect(Json.isEqual(DynamicValue(["@path": "/a"]).rawValue, ["@path": "/a"] as JsonMap))
        #expect(Json.isEqual(DynamicValue(["@call": "now"]).rawValue, ["@call": "now"] as JsonMap))
        #expect(DynamicValue.missing.rawValue == nil)
    }

    @Test("Child lists accept both arrays and templates")
    func childLists() {
        #expect(ChildList(["a", "b"]) == .ids(["a", "b"]))
        #expect(
            ChildList(["componentId": "row", "path": "/items"])
                == .template(componentId: "row", path: DataPath("/items"))
        )
        #expect(ChildList(nil) == .none)
        #expect(ChildList(["componentId": "row"]) == .none)
        #expect(ChildList(["a"]).staticIds == ["a"])
    }

    @Test("Actions are either events or function calls")
    func actions() {
        let event = ActionDefinition(["event": ["name": "submit", "context": ["id": ["@path": "/id"]]] as JsonMap])
        guard case let .event(payload) = event else {
            Issue.record("Expected an event action")
            return
        }
        #expect(payload.name == "submit")
        #expect(payload.context["id"] == .binding(DataPath("/id")))

        let call = ActionDefinition(["functionCall": ["@call": "openUrl", "args": ["url": "https://a.b"]] as JsonMap])
        guard case let .functionCall(function) = call else {
            Issue.record("Expected a function action")
            return
        }
        #expect(function.name == "openUrl")

        #expect(ActionDefinition(["event": [:] as JsonMap]) == nil)
        #expect(ActionDefinition(nil) == nil)
    }

    @Test("Validation results coerce from booleans and objects")
    func validationResults() {
        #expect(ValidationResult(coercing: true).isValid)
        #expect(!ValidationResult(coercing: false).isValid)
        #expect(ValidationResult(coercing: nil).isValid)

        let result = ValidationResult(
            coercing: ["valid": false, "code": "EXPIRED", "message": "Card expired", "severity": "warning"] as JsonMap
        )
        #expect(!result.isValid)
        #expect(result.code == "EXPIRED")
        #expect(result.severity == .warning)
        #expect(Json.isEqual(result.rawValue["message"], "Card expired"))
    }

    @Test("Accessibility attributes parse and serialize")
    func accessibility() {
        #expect(AccessibilityAttributes([:] as JsonMap) == nil)
        let attributes = AccessibilityAttributes(["label": "Mute", "description": ["@path": "/hint"], "hidden": true] as JsonMap)
        #expect(attributes?.label == .literal("Mute"))
        #expect(attributes?.description == .binding(DataPath("/hint")))
        #expect(attributes?.hidden == .literal(true))
        #expect(attributes?.rawValue["live"] == nil)
    }
}

@MainActor
@Suite("Surface definitions")
struct SurfaceDefinitionTests {
    @Test("A surface renders once its root component arrives")
    func renderable() {
        var definition = SurfaceDefinition(surfaceId: "main", catalogId: basicCatalogId)
        #expect(!definition.isRenderable)

        definition.merge([Component(id: "other", type: "Text")])
        #expect(!definition.isRenderable)

        definition.merge([Component(id: "root", type: "Text")])
        #expect(definition.isRenderable)
        #expect(definition.root?.type == "Text")
    }

    @Test("Merging replaces components with the same id")
    func merging() {
        var definition = SurfaceDefinition(surfaceId: "main")
        definition.merge([Component(id: "root", type: "Text", properties: ["text": "one"])])
        definition = definition.merging([Component(id: "root", type: "Text", properties: ["text": "two"])])

        #expect(Json.string(definition.root?.properties["text"]) == "two")
        #expect(definition.components.count == 1)
    }

    @Test("The context description includes the component tree")
    func contextDescription() {
        var definition = SurfaceDefinition(surfaceId: "main", sendDataModel: true)
        definition.merge([Component(id: "root", type: "Text", properties: ["text": "Hi"])])
        let description = definition.asContextDescriptionText()

        #expect(description.contains("\"main\""))
        #expect(description.contains("Text"))
        #expect(Json.isEqual(definition.toJson()["sendDataModel"], true))
    }
}
