//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatAI
@testable import StreamChatOpenUI
import SwiftUI
import Testing

@MainActor
final class FakeHost: AIUIHosting {
    var components: [any AIUIComponent]
    var sent: [AIUIAction] = []
    var opened: [URL] = []
    var states: [String: RawJSON] = [:]
    var toolResult: RawJSON = .nil
    var toolCalls: [(name: String, arguments: [String: RawJSON])] = []

    init(components: [any AIUIComponent] = []) {
        self.components = components
    }

    func send(_ action: AIUIAction) {
        sent.append(action)
    }

    func runTool(_ name: String, arguments: [String: RawJSON]) async throws -> RawJSON {
        toolCalls.append((name, arguments))
        return toolResult
    }

    func open(_ url: URL) {
        opened.append(url)
    }

    func state(for messageID: String) -> RawJSON? {
        states[messageID]
    }

    func setState(_ state: RawJSON?, for messageID: String) {
        states[messageID] = state
    }
}

@MainActor
final class ComponentRecorder {
    var titles: [String] = []
    var contexts: [AIUIComponentContext] = []
}

struct PlaceCardComponent: AIUIComponent {
    struct Arguments: Decodable {
        let title: String
    }

    var name = "place_card"
    var recorder = ComponentRecorder()

    var definition: AIUIComponentDefinition {
        AIUIComponentDefinition(
            name: name,
            description: "A place.",
            parameters: [.required("title", .string)],
            events: [.init(name: "ask_about", description: "The person asks about the place.")]
        )
    }

    func body(arguments: Arguments, context: AIUIComponentContext) -> some View {
        recorder.titles.append(arguments.title)
        recorder.contexts.append(context)
        return Text(arguments.title)
    }
}

@MainActor
@Suite("OpenUI renderer for StreamChatAI")
struct OpenUIRendererTests {
    static func document(_ program: String, isStreaming: Bool = false) -> AIUIDocument {
        AIUIDocument(format: .openUI, isStreaming: isStreaming, content: .string(program))
    }

    @Test func capabilitiesTeachTheAppComponents() {
        let capabilities = OpenUIRenderer().capabilities(components: [PlaceCardComponent()])

        #expect(capabilities["fence"] == .string("openui-lang"))
        #expect(capabilities["instructions"]?.stringValue?.contains("PlaceCard(title: string)") == true)
    }

    @Test func componentsThatClashOrCannotBeReadAreLeftOut() {
        let components: [any AIUIComponent] = [
            PlaceCardComponent(),
            PlaceCardComponent(name: "card"),
            PlaceCardComponent(name: ""),
            PlaceCardComponent(name: "place-card")
        ]

        let placeable = OpenUIRenderer.placeableSchemas(of: components, in: .openUIChat)

        #expect(placeable.map(\.schema.name) == ["PlaceCard"])
        #expect(OpenUIRenderer().capabilities(components: components)["instructions"]?.stringValue?.contains("PlaceCard(") == true)
    }

    @Test func engineAddsTheAppComponentsAndKeepsTheLibrarysOwn() {
        let host = FakeHost(components: [PlaceCardComponent(), PlaceCardComponent(name: "card")])

        let engine = OpenUIEngine(library: .openUIChat, host: host, toolProvider: FunctionToolProvider([:]))

        #expect(engine.library.component(named: "PlaceCard")?.renderer != nil)
        #expect(engine.library.root == "Card")
        #expect(engine.library.components.count == ComponentLibrary.openUIChat.components.count + 1)
    }

    @Test func aDocumentThatIsNotAProgramShowsNothing() {
        let engine = OpenUIEngine(library: .openUIChat, host: FakeHost(), toolProvider: FunctionToolProvider([:]))

        #expect(engine.view(for: AIUIDocument(format: .openUI, content: ["root": "x"]), messageID: "m1") == nil)
        #expect(engine.runtimes.isEmpty)
    }

    @Test func eachReplyKeepsItsRuntime() {
        let engine = OpenUIEngine(library: .openUIChat, host: FakeHost(), toolProvider: FunctionToolProvider([:]))
        let program = #"root = Card([TextContent("Hi")])"#

        let first = engine.view(for: Self.document(program, isStreaming: true), messageID: "m1")
        let again = engine.view(for: Self.document(program), messageID: "m1")
        _ = engine.view(for: Self.document(program), messageID: "m2")

        #expect(first?.runtime === again?.runtime)
        #expect(again?.isStreaming == false)
        #expect(engine.runtimes.count == 2)
        #expect(first?.runtime.root?.typeName == "Card")
    }

    @Test func aReplyThatLeavesTheConversationStopsItsRuntime() async {
        let tools = RecordingToolProvider(minimumRefreshInterval: 0.01) { _, _, count in ["n": .number(Double(count))] }
        let engine = OpenUIEngine(library: .openUIChat, host: FakeHost(), toolProvider: tools)
        let program = """
        root = Card([TextContent("Health")])
        health = Query("health", {}, {n: 0}, 0.01)
        """
        _ = engine.view(for: Self.document(program), messageID: "m1")
        _ = engine.view(for: Self.document(program), messageID: "m2")
        #expect(await waitUntil { tools.calls.count >= 4 })

        engine.remove(messageID: "m1")
        engine.remove(messageID: "m2")
        let calls = tools.calls.count
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(engine.runtimes.isEmpty)
        #expect(tools.calls.count <= calls + 2, "the replies' queries stop refreshing")
    }

    @Test func aReplyStartsFromTheStateTheHostKept() {
        let host = FakeHost()
        host.states["m1"] = ["$name": "Ana"]
        let engine = OpenUIEngine(library: .openUIChat, host: host, toolProvider: FunctionToolProvider([:]))

        let view = engine.view(for: Self.document(#"root = Card([TextContent($name)])\#n$name = "Bo""#), messageID: "m1")

        #expect(view?.runtime.store.get("$name") == "Ana")
    }

    @Test func stateChangesReachTheHost() {
        let host = FakeHost()
        let engine = OpenUIEngine(library: .openUIChat, host: host, toolProvider: FunctionToolProvider([:]))
        let runtime = engine.view(for: Self.document(#"root = Card([])"#), messageID: "m1")?.runtime

        runtime?.onStateUpdate?(["$count": 2])

        #expect(host.states["m1"] == ["$count": 2])
    }

    @Test func conversationActionsReachTheHostWithTheirDetails() {
        let host = FakeHost()
        let engine = OpenUIEngine(library: .openUIChat, host: host, toolProvider: FunctionToolProvider([:]))
        let event = ActionEvent(
            type: BuiltinActionType.continueConversation,
            params: ["context": "picked Ohrid", "item": 3],
            humanFriendlyMessage: "Tell me more",
            formState: ["name": "Ana"],
            formName: "trip"
        )

        engine.handle(event, messageID: "m1")

        #expect(host.sent == [AIUIAction(
            messageID: "m1",
            format: .openUI,
            name: BuiltinActionType.continueConversation,
            label: "Tell me more",
            payload: ["context": "picked Ohrid", "params": ["item": 3], "form": "trip", "values": ["name": "Ana"]]
        )])
    }

    @Test func anActionWithoutALabelIsNamedByItsContextOrType() {
        let host = FakeHost()
        let engine = OpenUIEngine(library: .openUIChat, host: host, toolProvider: FunctionToolProvider([:]))

        engine.handle(ActionEvent(type: "continue_conversation", params: ["context": "Ohrid"], humanFriendlyMessage: ""), messageID: "m1")
        engine.handle(ActionEvent(type: "share", humanFriendlyMessage: ""), messageID: "m1")

        #expect(host.sent.map(\.label) == ["Ohrid", "share"])
        #expect(host.sent[1].payload.isEmpty)
    }

    @Test func linksOpenOnTheHost() throws {
        let host = FakeHost()
        let engine = OpenUIEngine(library: .openUIChat, host: host, toolProvider: FunctionToolProvider([:]))

        engine.handle(ActionEvent(type: BuiltinActionType.openURL, params: ["url": "https://getstream.io"], humanFriendlyMessage: "Open"), messageID: "m1")
        engine.handle(ActionEvent(type: BuiltinActionType.openURL, humanFriendlyMessage: "No link"), messageID: "m1")

        #expect(host.opened == [try #require(URL(string: "https://getstream.io"))])
        #expect(host.sent.isEmpty)
    }

    @Test func linksToOtherAppsDontOpen() throws {
        let host = FakeHost()
        let engine = OpenUIEngine(library: .openUIChat, host: host, toolProvider: FunctionToolProvider([:]))

        for link in ["tel:+15550100", "facetime:someone@example.com", "otherapp://pay?to=x", "file:///etc/hosts", "javascript:alert(1)"] {
            engine.handle(ActionEvent(type: BuiltinActionType.openURL, params: ["url": .string(link)], humanFriendlyMessage: "Open"), messageID: "m1")
        }
        engine.handle(ActionEvent(type: BuiltinActionType.openURL, params: ["url": "mailto:a@b.co"], humanFriendlyMessage: "Mail"), messageID: "m1")

        #expect(host.opened == [try #require(URL(string: "mailto:a@b.co"))])
        #expect(host.sent.isEmpty)
    }

    @Test func actionsAfterTheConversationClosedAreDropped() {
        var host: FakeHost? = FakeHost()
        let engine = OpenUIEngine(library: .openUIChat, host: host!, toolProvider: FunctionToolProvider([:]))
        host = nil

        engine.handle(ActionEvent(type: "continue_conversation", humanFriendlyMessage: "Hi"), messageID: "m1")

        #expect(host == nil)
    }

    @Test func appComponentsShowTheirArgumentsAndTellTheHostWhatThePersonDid() throws {
        let component = PlaceCardComponent()
        let host = FakeHost(components: [component])
        let engine = OpenUIRenderer().makeEngine(host: host)

        let view = try #require(engine.view(for: Self.document(#"root = Card([PlaceCard("Ohrid")])"#), messageID: "m1"))
        RenderingTests.render(view)
        let context = try #require(component.recorder.contexts.last)
        context.emit("ask_about", label: "Tell me more about Ohrid", payload: ["detail": "lake"])

        #expect(component.recorder.titles.last == "Ohrid")
        #expect(context.messageID == "m1")
        #expect(host.sent.last == AIUIAction(
            messageID: "m1",
            format: .openUI,
            name: "ask_about",
            label: "Tell me more about Ohrid",
            payload: ["detail": "lake", "component": "place_card"]
        ))
    }

    @Test func queriesRunTheHostsTools() async throws {
        let host = FakeHost()
        host.toolResult = ["rows": [1]]
        let provider = HostToolProvider(host: host)

        let value = try await provider.callTool("list_events", arguments: ["day": "today"])

        #expect(value == ["rows": [1]])
        #expect(host.toolCalls.map(\.name) == ["list_events"])
        #expect(host.toolCalls.first?.arguments == ["day": "today"])
    }

    @Test func queriesAfterTheConversationClosedFail() async {
        let provider = HostToolProvider(host: nil)

        await #expect(throws: ConversationClosedError.self) {
            try await provider.callTool("list_events", arguments: [:])
        }
        #expect(ConversationClosedError(toolName: "list_events").errorDescription == "list_events can't run: the conversation was closed.")
    }

    @Test func valuesConvertToAndFromRawJSON() {
        let value: OpenUIValue = ["name": "Ana", "age": 3, "admin": false, "tags": ["a", .null], "nothing": .null]
        let raw: RawJSON = ["name": "Ana", "age": 3, "admin": false, "tags": ["a", .nil], "nothing": .nil]

        #expect(value.rawJSON == raw)
        #expect(raw.openUIValue.rawJSON == raw)
        #expect(OpenUIObject(rawJSON: ["x": 1]) == ["x": 1])
    }

    @Test func componentsAndExpressionsBecomePlainJSON() throws {
        let result = ComponentLibrary.openUIChat.parser.parse(#"root = Card([TextContent("Hi")])"#)
        let element = OpenUIValue.element(try #require(result.root))

        #expect(element.rawJSON.dictionaryValue?["typeName"] == "Card")
        #expect(element.rawJSON.dictionaryValue?["type"] == "element")
        #expect(OpenUIValue.array([element, "x"]).rawJSON.arrayValue?.last == "x")
    }
}
