//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import StreamCore
import XCTest

final class AIUIComponentDefinition_Tests: XCTestCase {
    private let placeCard = AIUIComponentDefinition(
        name: "place_card",
        description: "A photo and a short summary of a place.",
        parameters: [
            .required("title", .string, description: "The place's Wikipedia title."),
            .optional("visit_on", .date),
            .optional("tags", .array(.enumeration(["sight", "food", "nature"])))
        ],
        events: [.init(name: "ask_about", description: "The person asks about the place.")]
    )

    func testParametersAreAJSONSchemaObjectThatKeepsTheirOrder() {
        XCTAssertEqual(placeCard.parametersSchema, [
            "type": .string("object"),
            "properties": .dictionary([
                "title": .dictionary(["type": .string("string"), "description": .string("The place's Wikipedia title.")]),
                "visit_on": .dictionary(["type": .string("string"), "format": .string("date")]),
                "tags": .dictionary([
                    "type": .string("array"),
                    "items": .dictionary(["type": .string("string"), "enum": .array([.string("sight"), .string("food"), .string("nature")])])
                ])
            ]),
            "required": .array([.string("title")]),
            "x-order": .array([.string("title"), .string("visit_on"), .string("tags")])
        ])
    }

    func testADefinitionReadsBackFromItsJSON() throws {
        let data = try JSONEncoder().encode(placeCard)

        let decoded = try JSONDecoder().decode(AIUIComponentDefinition.self, from: data)

        XCTAssertEqual(decoded, placeCard)
    }

    func testParametersWithoutAnOrderReadByName() throws {
        let json = #"""
        {
          "name": "trip_map",
          "parameters": {
            "type": "object",
            "properties": { "zoom": { "type": "number" }, "places": { "type": "array", "items": { "type": "string" } } },
            "required": ["places"]
          },
          "events": [{ "name": "select_place", "parameters": { "type": "object", "properties": { "name": { "type": "string" } } } }]
        }
        """#

        let definition = try JSONDecoder().decode(AIUIComponentDefinition.self, from: Data(json.utf8))

        XCTAssertEqual(definition.description, "")
        XCTAssertEqual(definition.parameters.map(\.name), ["places", "zoom"])
        XCTAssertEqual(definition.parameters.map(\.isRequired), [true, false])
        XCTAssertEqual(definition.events.map(\.name), ["select_place"])
        XCTAssertEqual(definition.events.first?.parameters.map(\.name), ["name"])
    }

    func testAnObjectsFieldsAndAnEventsParametersKeepTheirOrderAndReadBack() throws {
        let tripMap = AIUIComponentDefinition(
            name: "trip_map",
            description: "A map of a plan.",
            parameters: [
                .required("places", .array(.object([.required("name", .string), .required("latitude", .number), .required("longitude", .number)])))
            ],
            events: [
                .init(name: "select_place", description: "The person taps a pin.", parameters: [.required("name", .string), .optional("day", .date)])
            ]
        )
        let data = try JSONEncoder().encode(tripMap)

        let places = tripMap.parametersSchema["properties"]?.dictionaryValue?["places"]?.dictionaryValue
        XCTAssertEqual(
            places?["items"]?.dictionaryValue?["x-order"],
            .array([.string("name"), .string("latitude"), .string("longitude")])
        )
        let json = try JSONDecoder().decode([String: RawJSON].self, from: data)
        let event = json["events"]?.arrayValue?.first?.dictionaryValue
        XCTAssertEqual(event?["parameters"]?.dictionaryValue?["x-order"], .array([.string("name"), .string("day")]))
        XCTAssertEqual(event?["parameters"]?.dictionaryValue?["required"], .array([.string("name")]))
        XCTAssertEqual(try JSONDecoder().decode(AIUIComponentDefinition.self, from: data), tripMap)
    }

    func testOnlyDaysAndMomentsDecodeAsDates() {
        struct Arguments: Decodable {
            let visitOn: Date
        }

        XCTAssertThrowsError(try AIUIArguments.decode(Arguments.self, from: ["visit_on": .string("next Saturday")]))
        XCTAssertThrowsError(try AIUIArguments.decode(Arguments.self, from: ["visit_on": .string("2026-13-40")]))
        XCTAssertThrowsError(try AIUIArguments.decode(Arguments.self, from: ["visit_on": .number(1_794_648_600)]))
    }

    func testArgumentsDecodeFromSnakeCaseWithDaysAndMoments() throws {
        struct Arguments: Decodable {
            let title: String
            let visitOn: Date
            let startsAt: Date
        }

        let arguments = try AIUIArguments.decode(Arguments.self, from: [
            "title": .string("Ohrid"),
            "visit_on": .string("2026-11-14"),
            "starts_at": .string("2026-11-14T09:30:00Z")
        ])

        let day = Calendar.current.dateComponents([.year, .month, .day, .hour], from: arguments.visitOn)
        XCTAssertEqual(arguments.title, "Ohrid")
        XCTAssertEqual([day.year, day.month, day.day, day.hour], [2026, 11, 14, 0], "a day is midnight on this device's calendar")
        XCTAssertEqual(arguments.startsAt, Date(timeIntervalSince1970: 1_794_648_600))
        XCTAssertThrowsError(try AIUIArguments.decode(Arguments.self, from: ["title": .string("Ohrid")]))
    }
}
