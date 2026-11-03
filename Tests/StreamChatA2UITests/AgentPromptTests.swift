//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatA2UI
import SwiftUI
import Testing

@MainActor
@Suite("What an agent writes and is told")
struct AgentPromptTests {
    @Test("A message counts once it is complete")
    func completeMessages() {
        let text = """
        {"version":"1.0","createSurface":{"surfaceId":"a"}}
        {"version":"1.0","updateComponents":{"surfaceId":"a","components":[{"id":"root","comp
        """

        #expect(A2UIStream.messages(in: text) == [#"{"version":"1.0","createSurface":{"surfaceId":"a"}}"#])
    }

    @Test("Messages are read pretty-printed or in an array")
    func prettyMessages() {
        let pretty = """
        [
          {
            "createSurface": { "surfaceId": "a" }
          },
          { "deleteSurface": { "surfaceId": "a" } }
        ]
        """

        let messages = A2UIStream.messages(in: pretty)
        #expect(messages.count == 2)
        #expect(Json.decodeMap(messages[1])?.keys.first == "deleteSurface")
    }

    @Test("Braces and quotes in text are text")
    func bracesInText() {
        let text = #"{"text":"a } \" { b"} {"text":"c"}"#

        #expect(A2UIStream.messages(in: text) == [#"{"text":"a } \" { b"}"#, #"{"text":"c"}"#])
    }

    @Test("A portable component is named as the basic catalog names its own")
    func portableComponent() throws {
        let definition = try PortableComponent.definition([
            "name": "trip_map",
            "description": "A map of a plan",
            "parameters": [
                "type": "object",
                "properties": ["places": ["type": "array", "items": ["type": "string"]] as JsonMap],
                "required": ["places"]
            ] as JsonMap,
            "events": [["name": "select_place", "description": "Tapping a pin asks about the place"]]
        ]) { _ in AnyView(EmptyView()) }

        #expect(definition.name == "TripMap")
        #expect(definition.description == "A map of a plan. Tapping a pin asks about the place.")
        #expect(definition.requiredProperties == ["places"])
        #expect(definition.propertySchema["places"]?["type"] as? String == "array")
    }

    @Test("A portable component needs a name")
    func unnamedPortableComponent() {
        #expect(throws: PortableComponentError.self) {
            try PortableComponent.definition(["description": "A map"]) { _ in AnyView(EmptyView()) }
        }
    }

    @Test("Problems say what would not render")
    func problems() {
        let catalog = BasicCatalog.catalog.adding(components: [], catalogId: "app")
        let text = """
        {"version":"1.0","createSurface":{"surfaceId":"s","catalogId":"app"}}
        {"version":"1.0","updateComponents":{"surfaceId":"s","components":[{"id":"root","component":"Column","children":["title","gone"]},{"id":"title","component":"Text","text":"Hi","size":2},{"id":"map","component":"Map"},{"id":"lost","component":"Divider"}]}}
        """

        #expect(A2UIProgram.problems(in: text, catalog: catalog) == [
            "map is a Map, which the catalog doesn't have",
            "title is a Text, which has no size",
            "root holds gone, which is not defined",
            "lost is defined but nothing holds it",
            "map is defined but nothing holds it"
        ])
    }

    @Test("A portable component is named with a Unicode identifier other than Surface")
    func portableComponentNames() {
        for name in ["surface", "9_lives", "place card!"] {
            #expect(throws: PortableComponentError.self, "\(name)") {
                try PortableComponent.definition(["name": name]) { _ in AnyView(EmptyView()) }
            }
        }
        #expect(throws: PortableComponentError.self) {
            try PortableComponent.definition([
                "name": "place_card",
                "parameters": ["properties": ["photo-url": ["type": "string"] as JsonMap] as JsonMap] as JsonMap
            ]) { _ in AnyView(EmptyView()) }
        }
    }

    @Test("test_v10_incremental_update_duplicate_component_id_error, _circular_reference_error and _depth_limit_exceeded_error")
    func structuralProblems() {
        let catalog = BasicCatalog.catalog.adding(components: [], catalogId: "app")
        let duplicates = """
        {"version":"1.0","createSurface":{"surfaceId":"s","catalogId":"app","components":[{"id":"root","component":"Text","text":"a"},{"id":"root","component":"Text","text":"b"}]}}
        {"version":"1.0","updateComponents":{"surfaceId":"s","components":[{"id":"root","component":"Text","text":"c"},{"id":"root","component":"Text","text":"d"}]}}
        """
        #expect(A2UIProgram.problems(in: duplicates, catalog: catalog) == [
            "surface s defines root more than once in one message", "surface s defines root more than once in one message"
        ])

        let cycle = """
        {"version":"1.0","createSurface":{"surfaceId":"s","catalogId":"app","components":[{"id":"root","component":"Card","child":"a"},{"id":"a","component":"Card","child":"root"}]}}
        """
        #expect(A2UIProgram.problems(in: cycle, catalog: catalog) == ["root holds itself through its children, so it never finishes rendering"])

        func id(_ level: Int) -> String {
            level == 0 ? "root" : "c\(level)"
        }
        let chain = (0...A2UIProtocol.maxNestingDepth).map { #"{"id":"\#(id($0))","component":"Card","child":"\#(id($0 + 1))"}"# }
            + [#"{"id":"\#(id(A2UIProtocol.maxNestingDepth + 1))","component":"Text","text":"leaf"}"#]
        let deep = #"{"version":"1.0","createSurface":{"surfaceId":"s","catalogId":"app","components":[\#(chain.joined(separator: ","))]}}"#
        #expect(A2UIProgram.problems(in: deep, catalog: catalog) == ["surface s nests components deeper than 50 levels"])
    }

    @Test("test_v10_uax31_invalid_identifier_error: component ids are identifiers")
    func identifierIds() {
        let catalog = BasicCatalog.catalog.adding(components: [], catalogId: "app")
        let text = """
        {"version":"1.0","createSurface":{"surfaceId":"s","catalogId":"app","components":[{"id":"root","component":"Column","children":["day-plan"]},{"id":"day-plan","component":"Text","text":"x"}]}}
        """

        #expect(A2UIProgram.problems(in: text, catalog: catalog) == [
            "day-plan isn't an identifier: use letters, digits and _, not starting with a digit"
        ])
        #expect(A2UIPromptBuilder.protocolOverview.contains("`saturday_plan` (never `saturday-plan`)"))
    }

    @Test("The tabs of a container are followed")
    func tabs() {
        let catalog = BasicCatalog.catalog.adding(components: [], catalogId: "app")
        let text = """
        {"version":"1.0","createSurface":{"surfaceId":"s","catalogId":"app","components":[{"id":"root","component":"Tabs","tabs":[{"title":"One","child":"one"}]},{"id":"one","component":"Text","text":"1"}]}}
        """

        #expect(A2UIProgram.problems(in: text, catalog: catalog).isEmpty)
    }

    @Test("Instructions say how a reply carries its UI, then the protocol, catalog, rules and examples")
    func instructions() {
        let catalog = BasicCatalog.catalog.adding(components: [], catalogId: "app")
        let text = A2UIInstructions(
            catalog: catalog,
            fence: "ui:a2ui@1.0",
            preamble: "Plan trips as UI.",
            rules: ["Keep it short."],
            examples: ["An example."]
        ).text

        let order = ["Plan trips as UI.", "`ui:a2ui@1.0`", A2UIPromptBuilder.protocolOverview, "## The catalog `app`", "1. Keep it short.", "## Examples\n\nAn example."]
        let positions = order.map { text.range(of: $0)?.lowerBound }
        #expect(positions.allSatisfy { $0 != nil })
        #expect(positions.compactMap { $0 } == positions.compactMap { $0 }.sorted())
    }
}
