//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI
import Testing

@Suite("Portable components")
struct PortableComponentsTests {
    static let placeCard: OpenUIValue = [
        "name": "place_card",
        "description": "A photo and a short summary of a place",
        "parameters": [
            "type": "object",
            "properties": [
                "summary": ["type": "string", "description": "One sentence about it"],
                "title": ["type": "string"],
                "rating": ["type": "number"],
                "kind": ["type": "string", "enum": ["museum", "beach"]],
                "tags": ["type": "array", "items": ["type": "string"]],
                "visible": ["type": "boolean"],
                "location": [
                    "type": "object",
                    "properties": ["lat": ["type": "number"], "lng": ["type": "number"]],
                    "required": ["lat"]
                ],
                "extra": [:]
            ],
            "required": ["title"],
            "x-order": ["title", "summary"]
        ],
        "events": [["name": "ask_about", "description": "The person asks about the place."]]
    ]

    @Test func typeNameIsPascalCase() {
        #expect(ComponentSchema.typeName(forPortableName: "place_card") == "PlaceCard")
        #expect(ComponentSchema.typeName(forPortableName: "weather-now view") == "WeatherNowView")
        #expect(ComponentSchema.typeName(forPortableName: "Card") == "Card")
    }

    @Test func readsADefinitionInItsOrder() throws {
        let schema = try ComponentSchema(portableDefinition: Self.placeCard)

        #expect(schema.name == "PlaceCard")
        #expect(schema.props.map(\.name) == ["title", "summary", "rating", "kind", "tags", "visible", "location", "extra"])
        #expect(schema.props.map(\.isOptional) == [false, true, true, true, true, true, true, true])
        #expect(schema.props[2].type == .number)
        #expect(schema.props[3].type == .enumeration(["museum", "beach"]))
        #expect(schema.props[4].type == .array(.string))
        #expect(schema.props[5].type == .boolean)
        #expect(schema.props[6].type == .object([.required("lat", .number), .optional("lng", .number)]))
        #expect(schema.props[7].type == .any)
    }

    @Test func descriptionJoinsTheDescriptionsOfItsParametersAndEvents() throws {
        let schema = try ComponentSchema(portableDefinition: Self.placeCard)

        #expect(schema.description == "A photo and a short summary of a place. summary: One sentence about it. The person asks about the place.")
    }

    @Test func aDefinitionNeedsAName() {
        #expect(throws: PortableComponentError.self) {
            try ComponentSchema(portableDefinition: ["description": "No name"])
        }
    }

    @Test func addedContentIsPlaceableWhereTheLibraryContentGoes() throws {
        let schema = try ComponentSchema(portableDefinition: Self.placeCard)

        let library = ComponentLibrary.openUIChat.addingContent([ComponentDefinition(schema, renderer: nil)], notes: ["Use it for places."])

        #expect(library.component(named: "PlaceCard") != nil)
        #expect(library.componentGroups.last?.name == "App components")
        #expect(library.componentGroups.last?.notes == ["Use it for places."])
        let result = library.parser.parse(#"root = Card([PlaceCard("Ohrid", "A lake town")])"#)
        #expect(result.meta.errors.isEmpty)
        #expect(result.root?.props["children"]?.arrayValue?.first?.elementValue?.typeName == "PlaceCard")
        #expect(library.systemPrompt().contains("PlaceCard(title: string, summary?: string"))
    }
}
