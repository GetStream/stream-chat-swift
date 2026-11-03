//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatOpenUI
import SwiftUI
import Testing

/// The customization examples from the README, using only the public API.
@Suite("Custom libraries")
@MainActor
struct CustomLibraryTests {
    static let tripCard = ComponentSchema("TripCard", description: "A trip with its length in days", props: [
        .required("title", .string),
        .optional("days", .number)
    ])
    static let trips = ComponentSchema("Trips", description: "A list of trips", props: [
        .required("items", .array(.component("TripCard")))
    ])

    static let library = ComponentLibrary(root: "Trips", components: [
        OpenUIComponentDefinition(trips) { context in
            VStack(alignment: .leading) { context.render(prop: "items") }
        },
        OpenUIComponentDefinition(tripCard) { context in
            Text("\(context.props.text("title") ?? "") · \(Int(context.props.number("days") ?? 0)) days")
        }
    ])

    @Test func customLibraryParsesAndGeneratesItsPrompt() {
        let result = Self.library.parser.parse("""
        root = Trips([lisbon, porto])
        lisbon = TripCard("Lisbon", 3)
        porto = TripCard("Porto", 2)
        """)
        #expect(result.meta.errors.isEmpty)
        #expect(result.root?.typeName == "Trips")
        #expect(result.root?.props["items"]?.arrayValue?.count == 2)

        let prompt = Self.library.systemPrompt()
        #expect(prompt.contains("TripCard(title: string, days?: number) — A trip with its length in days"))
        #expect(prompt.contains("Trips(items: TripCard[]) — A list of trips"))
    }

    @Test func replacingAViewKeepsTheSchemaAndPrompt() {
        let library = ComponentLibrary.openUIChat.replacingView(of: .callout) { context in
            Label(context.props.text("title") ?? "", systemImage: "info.circle")
        }
        #expect(library.component(named: "Callout")?.schema == ComponentLibrary.openUIChat.component(named: "Callout")?.schema)
        #expect(library.systemPrompt() == ComponentLibrary.openUIChat.systemPrompt())
    }

    @Test func promptListsTools() {
        var options = ComponentLibrary.openUIChat.defaultPromptOptions
        options.tools = [.spec(ToolSpec(
            name: "search_hotels",
            description: "Search hotels in a city",
            inputSchema: ["type": "object", "properties": ["city": ["type": "string"]], "required": ["city"]],
            outputSchema: ["type": "object", "properties": ["hotels": ["type": "array", "items": ["type": "object", "properties": ["name": ["type": "string"]]]]]]
        ))]
        let prompt = ComponentLibrary.openUIChat.systemPrompt(options)
        #expect(prompt.contains("- search_hotels(city: string) → {hotels?: {name?: string}[]}"))
        #expect(prompt.contains("## Query — Live Data Fetching"))
    }
}
