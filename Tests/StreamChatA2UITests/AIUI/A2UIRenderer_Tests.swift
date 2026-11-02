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

    func test_format_fenceAndVersions() {
        let renderer = A2UIRenderer()

        XCTAssertEqual(renderer.format, .a2ui)
        XCTAssertEqual(renderer.fence, "ui:a2ui@1.0")
        XCTAssertEqual(renderer.catalog.catalogId, BasicCatalog.catalogId)
        XCTAssertEqual(renderer.catalogId, A2UIRenderer.defaultCatalogId)
        XCTAssertTrue(renderer.supports(version: nil))
        XCTAssertTrue(renderer.supports(version: "1.0"))
        XCTAssertTrue(renderer.supports(version: "v1.0"))
        XCTAssertFalse(renderer.supports(version: "0.9"))
        XCTAssertFalse(renderer.supports(version: "2.0"))
    }

    func test_capabilities_describeTheAppsComponents() throws {
        let capabilities = A2UIRenderer(catalogId: "app").capabilities(components: [PlaceCard()])

        XCTAssertEqual(capabilities["fence"], .string("ui:a2ui@1.0"))
        XCTAssertEqual(capabilities["catalog_id"], .string("app"))
        let instructions = try XCTUnwrap(capabilities["instructions"]?.stringValue)
        XCTAssertTrue(instructions.contains("PlaceCard"))
        XCTAssertTrue(instructions.contains("ui:a2ui@1.0"))
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
}
