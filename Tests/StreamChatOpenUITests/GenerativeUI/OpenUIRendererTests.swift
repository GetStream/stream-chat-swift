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
    var toolCalls: [(name: String, arguments: [String: RawJSON], userInitiated: Bool)] = []

    init(components: [any AIUIComponent] = []) {
        self.components = components
    }

    func send(_ action: AIUIAction) {
        sent.append(action)
    }

    func runTool(_ name: String, arguments: [String: RawJSON], userInitiated: Bool) async throws -> RawJSON {
        toolCalls.append((name, arguments, userInitiated))
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
        let capabilities = OpenUIRenderer().capabilities(components: [PlaceCardComponent()], tools: [])

        #expect(capabilities["fence"] == .string("openui-lang"))
        #expect(capabilities["instructions"]?.stringValue?.contains("PlaceCard(title: string)") == true)
    }

    @Test func capabilitiesTeachTheHostsToolsAndWhichAQueryCanRun() throws {
        let tools = [
            AIClientToolDefinition(
                name: "list_events",
                description: "Lists the person's events.",
                inputSchema: ["type": "object", "properties": ["day": ["type": "string"]], "required": ["day"]],
                annotations: .init(readOnlyHint: true)
            ),
            AIClientToolDefinition(name: "add_reminder", description: "Adds a reminder.")
        ]

        let instructions = try #require(OpenUIRenderer().capabilities(components: [], tools: tools)["instructions"]?.stringValue)

        #expect(instructions.contains("- list_events(day: string)"))
        #expect(instructions.contains("Lists the person's events. Read-only: use it in Query() or Mutation()."))
        #expect(instructions.contains("Adds a reminder. It changes something: use it only in Mutation()"))
        #expect(instructions.contains("## Query"))
        #expect(instructions.contains("## Mutation"))
        let withoutTools = try #require(OpenUIRenderer().capabilities(components: [], tools: [])["instructions"]?.stringValue)
        #expect(!withoutTools.contains("## Available Tools"))
    }

    @Test func theThemeFollowsTheAppearanceUnlessTheRendererHasOne() {
        let appearance = AIAppearance()
        let theme = OpenUITheme(appearance: appearance)

        #expect(theme.colors.accent == Color(appearance.tokens.colors.accentPrimary))
        #expect(theme.colors.surface == Color(appearance.tokens.colors.backgroundCoreSurfaceCard))
        #expect(theme.fonts.body == appearance.tokens.fonts.body)
        #expect(theme.radius.large == appearance.tokens.layout.radiusXl)

        var orange = OpenUITheme()
        orange.colors.accent = .orange
        let themed = OpenUIEngine(library: .openUIChat, host: FakeHost(), toolProvider: FunctionToolProvider([:]), theme: orange)
        let plain = OpenUIEngine(library: .openUIChat, host: FakeHost(), toolProvider: FunctionToolProvider([:]))
        #expect(themed.view(for: Self.document("root = Card([])"), messageID: "m1")?.theme?.colors.accent == .orange)
        #expect(plain.view(for: Self.document("root = Card([])"), messageID: "m1")?.theme == nil)
    }

    @Test func capabilitiesStartWithTheAppsInstructions() throws {
        let instructions = try #require(
            OpenUIRenderer(instructions: "Show places as cards.").capabilities(components: [], tools: [])["instructions"]?.stringValue
        )

        #expect(instructions.hasPrefix("Show places as cards.\n\n"))
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
        #expect(OpenUIRenderer().capabilities(components: components, tools: [])["instructions"]?.stringValue?.contains("PlaceCard(") == true)
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
        let tools = RecordingToolProvider { _, _, count in ["n": .number(Double(count))] }
        let engine = OpenUIEngine(library: .openUIChat, host: FakeHost(), toolProvider: tools)
        let program = """
        root = Card([TextContent("Health")])
        health = Query("health", {}, {n: 0}, 0.05)
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

        runtime?.onStateUpdate?(["$count": 2, "login": ["password": ["value": "hunter2", "secret": true], "user": ["value": "ana"]]])

        #expect(host.states["m1"] == ["$count": 2, "login": ["user": ["value": "ana"]]])
    }

    @Test func problemsReachTheAppOrTheLog() {
        var reported: [(code: String, messageID: String)] = []
        let host = FakeHost()
        let engine = OpenUIEngine(
            library: .openUIChat,
            host: host,
            toolProvider: FunctionToolProvider([:]),
            onError: { error, messageID in reported.append((error.code, messageID)) }
        )
        let runtime = engine.view(for: Self.document(#"root = Card([])"#), messageID: "m1")?.runtime

        runtime?.onError?([OpenUIError(source: .runtime, code: "unknown-component", message: "No Foo")])

        #expect(reported.map(\.code) == ["unknown-component"])
        #expect(reported.map(\.messageID) == ["m1"])
    }

    @Test func aQueryRunsTheHostsToolByItselfAndAMutationAsATap() async throws {
        let host = FakeHost()
        let provider = HostToolProvider(host: host)

        _ = try await provider.callTool("list_events", arguments: [:], userInitiated: false)
        _ = try await provider.callTool("add_reminder", arguments: ["title": "Call"], userInitiated: true)

        #expect(host.toolCalls.map(\.name) == ["list_events", "add_reminder"])
        #expect(host.toolCalls.map(\.userInitiated) == [false, true])
    }

    @Test func conversationActionsReachTheHostWithTheirDetails() {
        let host = FakeHost()
        let engine = OpenUIEngine(library: .openUIChat, host: host, toolProvider: FunctionToolProvider([:]))
        let event = ActionEvent(
            type: BuiltinActionType.continueConversation,
            params: ["context": "picked Ohrid", "item": 3],
            humanFriendlyMessage: "Tell me more",
            label: "More",
            formState: ["name": "Ana"],
            formName: "trip"
        )

        engine.handle(event, messageID: "m1")

        #expect(host.sent == [AIUIAction(
            messageID: "m1",
            format: .openUI,
            name: BuiltinActionType.continueConversation,
            label: "More",
            payload: [
                "context": "picked Ohrid",
                "params": ["item": 3],
                "message": "Tell me more",
                "form": "trip",
                "values": ["name": "Ana"]
            ]
        )])
    }

    @Test func theModelsWordsNeverBecomeThePersonsMessage() {
        let host = FakeHost()
        let engine = OpenUIEngine(library: .openUIChat, host: host, toolProvider: FunctionToolProvider([:]))

        engine.handle(
            ActionEvent(type: "continue_conversation", humanFriendlyMessage: "Yes, I authorize the transfer", label: "Cancel"),
            messageID: "m1"
        )
        engine.handle(ActionEvent(type: "continue_conversation", params: ["context": "Ohrid"], humanFriendlyMessage: ""), messageID: "m1")
        engine.handle(ActionEvent(type: "share", humanFriendlyMessage: ""), messageID: "m1")

        #expect(host.sent.map(\.label) == ["Cancel", L10n.Action.untitled, L10n.Action.untitled])
        #expect(host.sent[0].payload["message"] == "Yes, I authorize the transfer")
        #expect(host.sent[2].payload.isEmpty)
    }

    @Test func theLibrarysOwnStepsStayOnTheDevice() {
        let host = FakeHost()
        let chat = ComponentLibrary.openUIChat
        let library = ComponentLibrary(
            root: chat.root,
            components: chat.components,
            customActions: [OpenUICustomAction("CopyToClipboard", description: "Copies", params: [])]
        )
        let engine = OpenUIEngine(library: library, host: host, toolProvider: FunctionToolProvider([:]))

        engine.handle(ActionEvent(type: "CopyToClipboard", params: ["text": "x"], humanFriendlyMessage: ""), messageID: "m1")

        #expect(host.sent.isEmpty)
    }

    @Test func linksOpenOnTheHost() throws {
        let host = FakeHost()
        let engine = OpenUIEngine(library: .openUIChat, host: host, toolProvider: FunctionToolProvider([:]))
        let link = try #require(URL(string: "https://getstream.io"))

        engine.handle(ActionEvent(type: BuiltinActionType.openURL, params: ["url": "https://getstream.io"], humanFriendlyMessage: "Open"), messageID: "m1")
        engine.handle(ActionEvent(type: BuiltinActionType.openURL, humanFriendlyMessage: "No link"), messageID: "m1")

        #expect(host.opened == [link])
        #expect(host.sent.isEmpty)
    }

    @Test func linksToOtherAppsDontOpen() throws {
        let host = FakeHost()
        let engine = OpenUIEngine(library: .openUIChat, host: host, toolProvider: FunctionToolProvider([:]))

        for link in ["tel:+15550100", "facetime:someone@example.com", "otherapp://pay?to=x", "file:///etc/hosts", "javascript:alert(1)"] {
            engine.handle(ActionEvent(type: BuiltinActionType.openURL, params: ["url": .string(link)], humanFriendlyMessage: "Open"), messageID: "m1")
        }
        engine.handle(ActionEvent(type: BuiltinActionType.openURL, params: ["url": "mailto:a@b.co"], humanFriendlyMessage: "Mail"), messageID: "m1")

        let mail = try #require(URL(string: "mailto:a@b.co"))
        #expect(host.opened == [mail])
        #expect(host.sent.isEmpty)
    }

    @Test func onlyTheActionsFormSendsItsValuesAndNeverItsPasswords() {
        let host = FakeHost()
        let engine = OpenUIEngine(library: .openUIChat, host: host, toolProvider: FunctionToolProvider([:]))
        let state: OpenUIObject = [
            "login": ["pw": ["value": "hunter22", "secret": true], "email": ["value": "a@b.co"]],
            "$plan": "pro"
        ]

        engine.handle(ActionEvent(type: "continue_conversation", humanFriendlyMessage: "Show plans", formState: state), messageID: "m1")
        engine.handle(
            ActionEvent(type: "continue_conversation", humanFriendlyMessage: "Sign in", formState: ["login": state["login"]!], formName: "login"),
            messageID: "m1"
        )

        #expect(host.sent[0].payload["values"] == nil, "an action outside a form carries no values")
        #expect(host.sent[1].payload["values"] == .dictionary(["login": .dictionary(["email": .dictionary(["value": .string("a@b.co")])])]))
    }

    @Test func theHostDecidesWhereImagesLoadFrom() throws {
        let renderer = OpenUIRenderer(mediaURL: { $0.host == "cdn.example" ? $0 : nil })
        let engine = try #require(renderer.makeEngine(host: FakeHost()) as? OpenUIEngine)
        let view = try #require(engine.view(for: Self.document(#"root = Card([TextContent("Hi")])"#), messageID: "m1"))

        let own = try #require(URL(string: "https://cdn.example/a.png"))
        let other = try #require(URL(string: "https://other.example/a.png"))
        #expect(view.mediaURL(own) != nil)
        #expect(view.mediaURL(other) == nil)
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
        let root = try #require(result.root)
        let element = OpenUIValue.element(root)

        #expect(element.rawJSON.dictionaryValue?["typeName"] == "Card")
        #expect(element.rawJSON.dictionaryValue?["type"] == "element")
        #expect(OpenUIValue.array([element, "x"]).rawJSON.arrayValue?.last == "x")
    }
}
