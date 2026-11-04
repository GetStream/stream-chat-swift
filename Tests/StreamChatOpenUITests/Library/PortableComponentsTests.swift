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
        #expect(throws: OpenUIPortableComponentError.self) {
            try ComponentSchema(portableDefinition: ["description": "No name"])
        }
    }

    @Test func addedContentIsPlaceableWhereTheLibraryContentGoes() throws {
        let schema = try ComponentSchema(portableDefinition: Self.placeCard)

        let library = ComponentLibrary.openUIChat.addingContent([OpenUIComponentDefinition(schema, renderer: nil)], notes: ["Use it for places."])

        #expect(library.component(named: "PlaceCard") != nil)
        #expect(library.componentGroups.last?.name == "App components")
        #expect(library.componentGroups.last?.notes == ["Use it for places."])
        let result = library.parser.parse(#"root = Card([PlaceCard("Ohrid", "A lake town")])"#)
        #expect(result.meta.errors.isEmpty)
        #expect(result.root?.props["children"]?.arrayValue?.first?.elementValue?.typeName == "PlaceCard")
        #expect(library.systemPrompt().contains("PlaceCard(title: string, summary?: string"))
    }

    @Test func descriptionsStayOnOneLine() throws {
        let schema = try ComponentSchema(portableDefinition: [
            "name": "note",
            "description": "First line\nsecond  line\n",
            "parameters": ["type": "object", "properties": ["text": ["type": "string", "description": "The\ttext"]]]
        ])

        #expect(schema.description == "First line second line. text: The text.")
    }

    @Test func aNameRepeatedInXOrderIsOneProp() throws {
        let schema = try ComponentSchema(portableDefinition: [
            "name": "pair",
            "parameters": [
                "type": "object",
                "properties": ["a": ["type": "string"], "b": ["type": "number"]],
                "x-order": ["b", "a", "b"]
            ]
        ])

        #expect(schema.props.map(\.name) == ["b", "a"])
    }

    @Test func readsNullableTypesDefaultsAndOtherEnums() throws {
        let schema = try ComponentSchema(portableDefinition: [
            "name": "settings",
            "parameters": [
                "type": "object",
                "properties": [
                    "title": ["type": ["string", "null"]],
                    "count": ["type": "integer", "default": 3],
                    "level": ["type": "number", "enum": [1, 2, 3]],
                    "mixed": ["enum": ["a", 1]],
                    "kind": ["const": "place"],
                    "either": ["anyOf": [["type": "string"], ["type": "number"], ["type": "null"]]],
                    "maybe": ["oneOf": [["type": "boolean"], ["type": "null"]]],
                    "scores": ["type": "object", "additionalProperties": ["type": "number"]]
                ],
                "required": ["count"]
            ]
        ])
        let props = Dictionary(uniqueKeysWithValues: schema.props.map { ($0.name, $0) })

        #expect(props["title"]?.type == .string)
        #expect(props["count"]?.type == .number)
        #expect(props["count"]?.defaultValue == 3)
        #expect(props["count"]?.isOptional == true)
        #expect(schema.jsonSchema["required"] == ["count"])
        #expect(props["level"]?.type == .number)
        #expect(props["mixed"]?.type == .any)
        #expect(props["kind"]?.type == .literal("place"))
        #expect(props["either"]?.type == .union([.string, .number]))
        #expect(props["maybe"]?.type == .boolean)
        #expect(props["scores"]?.type == .record(.number))
    }

    @Test func aDefaultReachesTheParsedProps() throws {
        let schema = try ComponentSchema(portableDefinition: [
            "name": "counter",
            "parameters": ["type": "object", "properties": ["count": ["type": "number", "default": 3]]]
        ])
        let library = ComponentLibrary(root: "Counter", components: [OpenUIComponentDefinition(schema, renderer: nil)])

        let result = library.parser.parse("root = Counter()")

        #expect(result.root?.props["count"] == 3)
    }
}
