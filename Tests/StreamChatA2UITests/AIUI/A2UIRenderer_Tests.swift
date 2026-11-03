//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatA2UI
import StreamChatAI
import SwiftUI
import XCTest

@MainActor
final class A2UIRenderer_Tests: XCTestCase {
    struct PlaceCard: AIUIComponent {
        struct Arguments: Decodable {
            let title: String
        }

        let definition = AIUIComponentDefinition(
            name: "place_card",
            description: "A place",
            parameters: [.required("title", .string)],
            events: [.init(name: "ask_about", description: "Tapping it asks about the place")]
        )

        func body(arguments: Arguments, context: AIUIComponentContext) -> some View {
            Text(arguments.title)
        }
    }

    struct CardNamedComponent: AIUIComponent {
        struct Arguments: Decodable {}

        let definition = AIUIComponentDefinition(name: "card", description: "The app's card")

        func body(arguments: Arguments, context: AIUIComponentContext) -> some View {
            Text("card")
        }
    }

    func test_format_fenceAndVersions() {
        let renderer = A2UIRenderer()

        XCTAssertEqual(renderer.format, .a2ui)
        XCTAssertEqual(renderer.fence, "ui:a2ui@1.0")
        XCTAssertEqual(renderer.catalog.catalogId, BasicCatalog.catalogId)
        XCTAssertEqual(renderer.catalogId, A2UIRenderer.defaultCatalogId)
        XCTAssertTrue(renderer.supports(version: nil))
        XCTAssertTrue(renderer.supports(version: "1.0"))
        XCTAssertTrue(renderer.supports(version: "v1.0"))
        XCTAssertTrue(renderer.supports(version: "v1"))
        XCTAssertTrue(renderer.supports(version: "1"))
        XCTAssertFalse(renderer.supports(version: "0.9"))
        XCTAssertFalse(renderer.supports(version: "2.0"))
    }

    func test_capabilities_describeTheAppsComponents() throws {
        let capabilities = A2UIRenderer(catalogId: "app").capabilities(components: [PlaceCard()], tools: [])

        XCTAssertEqual(capabilities["fence"], .string("ui:a2ui@1.0"))
        XCTAssertEqual(capabilities["catalog_id"], .string("app"))
        let instructions = try XCTUnwrap(capabilities["instructions"]?.stringValue)
        XCTAssertTrue(instructions.contains("PlaceCard"))
        XCTAssertTrue(instructions.contains("ui:a2ui@1.0"))
    }

    func test_capabilities_followTheAppsInstructions() throws {
        let capabilities = A2UIRenderer(instructions: "Show places as cards.").capabilities(components: [], tools: [])
        let instructions = try XCTUnwrap(capabilities["instructions"]?.stringValue)

        XCTAssertTrue(instructions.hasPrefix("Show places as cards."))
    }

    func test_capabilities_listTheAppsToolsAndWhichOnlyRead() throws {
        let tools = [
            AIClientToolDefinition(
                name: "list_events",
                description: "Lists the person's events.",
                inputSchema: ["type": "object", "properties": ["day": ["type": "string"]]],
                annotations: .init(readOnlyHint: true)
            ),
            AIClientToolDefinition(name: "add_reminder", description: "Adds a reminder.")
        ]
        let instructions = try XCTUnwrap(A2UIRenderer().capabilities(components: [], tools: tools)["instructions"]?.stringValue)

        XCTAssertTrue(instructions.contains("## The app's tools"))
        XCTAssertTrue(instructions.contains(
            #"- `list_events` (read-only): Lists the person's events. Arguments: `{"properties":{"day":{"type":"string"}},"type":"object"}`"#
        ))
        XCTAssertTrue(instructions.contains("- `add_reminder`: Adds a reminder."))
        XCTAssertFalse(try XCTUnwrap(A2UIRenderer().capabilities(components: [], tools: [])["instructions"]?.stringValue)
            .contains("## The app's tools"))
    }

    func test_definitions_leaveOutComponentsNamedLikeTheCatalogs() {
        let definitions = A2UIRenderer().definitions(of: [CardNamedComponent(), PlaceCard()]) { _ in
            { _ in AnyView(EmptyView()) }
        }

        XCTAssertEqual(definitions.map(\.name), ["PlaceCard"])
    }

    func test_catalogs_extendBothIds() {
        let renderer = A2UIRenderer(catalogId: "app")
        let card = ComponentDefinition(name: "PlaceCard") { _ in AnyView(EmptyView()) }

        let catalogs = renderer.catalogs(adding: [card])
        XCTAssertEqual(catalogs.map(\.catalogId), ["app", BasicCatalog.catalogId])
        XCTAssertTrue(catalogs.allSatisfy { $0.component("PlaceCard") != nil && $0.component("Text") != nil })

        let sameId = A2UIRenderer(catalogId: BasicCatalog.catalogId).catalogs(adding: [card])
        XCTAssertEqual(sameId.map(\.catalogId), [BasicCatalog.catalogId])
    }

    func test_catalogs_withEntrancesKeepTheirEntries() {
        let catalog = BasicCatalog.catalog.withEntrances

        XCTAssertEqual(Set(catalog.components.keys), Set(BasicCatalog.catalog.components.keys))
        XCTAssertEqual(Set(catalog.functions.keys), Set(BasicCatalog.catalog.functions.keys))
        XCTAssertEqual(catalog.component("Text")?.requiredProperties, BasicCatalog.catalog.component("Text")?.requiredProperties)
    }

    func test_definition_isNamedAsTheBasicCatalogNamesItsOwn() throws {
        let definition = try A2UIRenderer.definition(of: PlaceCard().definition) { _ in AnyView(EmptyView()) }

        XCTAssertEqual(definition.name, "PlaceCard")
        XCTAssertEqual(definition.requiredProperties, ["title"])
        XCTAssertTrue(definition.description?.contains("Tapping it asks about the place") == true)
    }

    func test_rawJSON_fromA2UIValues() {
        XCTAssertEqual(RawJSON(a2ui: "text"), .string("text"))
        XCTAssertEqual(RawJSON(a2ui: 2), .number(2))
        XCTAssertEqual(RawJSON(a2ui: 1.5), .number(1.5))
        XCTAssertEqual(RawJSON(a2ui: true), .bool(true))
        XCTAssertEqual(RawJSON(a2ui: nil), .nil)
        XCTAssertEqual(RawJSON(a2ui: NSNull()), .nil)
        XCTAssertEqual(
            RawJSON(a2ui: ["a": [1, "b"] as JsonArray, "c": ["d": false] as JsonMap] as JsonMap),
            .dictionary(["a": .array([.number(1), .string("b")]), "c": .dictionary(["d": .bool(false)])])
        )
        // Decoded JSON numbers stay numbers, even 1 and 0.
        XCTAssertEqual(RawJSON(a2ui: Json.decodeMap(#"{"one": 1}"#)?["one"]), .number(1))
    }

    func test_rawJSON_toA2UIValues() {
        let json = RawJSON.dictionary([
            "a": .array([.number(1), .string("b"), .nil]),
            "c": .dictionary(["d": .bool(false)])
        ])

        XCTAssertEqual(RawJSON(a2ui: json.a2uiValue), json)
        XCTAssertTrue(RawJSON.nil.a2uiValue is NSNull)
        XCTAssertEqual(RawJSON.string("x").a2uiValue as? String, "x")
    }
}
