//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import StreamCore
import SwiftUI
import XCTest

@MainActor
final class AIUIHost_Tests: XCTestCase {
    final class TestEngine: AIUIEngine {
        weak var host: (any AIUIHosting)?
        var received: [(messageID: String, document: AIUIDocument)] = []
        var shown: [(messageID: String, document: AIUIDocument)] = []

        init(host: any AIUIHosting) {
            self.host = host
        }

        func receive(_ document: AIUIDocument, messageID: String) {
            received.append((messageID, document))
        }

        func view(for document: AIUIDocument, messageID: String) -> Text? {
            shown.append((messageID, document))
            return document.text.map { Text($0) }
        }
    }

    final class TestRenderer: AIUIRenderer {
        let format: AIUIFormat
        let versions: String
        var engines: [TestEngine] = []

        init(format: AIUIFormat = .openUI, versions: String = "1.") {
            self.format = format
            self.versions = versions
        }

        func supports(version: String?) -> Bool {
            version.map { $0.hasPrefix(versions) } ?? true
        }

        func capabilities(components: [any AIUIComponent]) -> [String: RawJSON] {
            ["components": .number(Double(components.count))]
        }

        func makeEngine(host: any AIUIHosting) -> TestEngine {
            let engine = TestEngine(host: host)
            engines.append(engine)
            return engine
        }
    }

    final class Tool: AIClientTool {
        let definition = AIClientToolDefinition(name: "list_events")
        var result = AIClientToolResult.completed(["events": ["Dinner"]])
        var calls: [AIToolCallPart] = []

        func run(_ call: AIToolCallPart) async -> AIClientToolResult {
            calls.append(call)
            return result
        }
    }

    struct PlaceCard: AIUIComponent {
        struct Arguments: Decodable {
            let title: String
        }

        let definition = AIUIComponentDefinition(name: "place_card", description: "A place.", parameters: [.required("title", .string)])

        func body(arguments: Arguments, context: AIUIComponentContext) -> some View {
            Text(arguments.title)
        }
    }

    struct Reply: AIMessage {
        var id: String
        var role: AIMessageRole = .assistant
        var text = ""
        var uiDocument: AIUIDocument?
    }

    private let placeCard = PlaceCard()

    private func document(_ text: String = "root = Card([])", format: AIUIFormat = .openUI, version: String? = nil) -> AIUIDocument {
        AIUIDocument(format: format, version: version, content: .string(text))
    }

    private func shows(_ component: some AIUIComponent, _ arguments: [String: RawJSON], in host: any AIUIHosting) -> Bool {
        let context = AIUIComponentContext(messageID: "m1", isStreaming: true, host: host) { _, _, _ in }
        return component.view(arguments: arguments, context: context) != nil
    }

    func testOnlyAFormatAndVersionARendererReadsShow() {
        let host = AIUIHost { TestRenderer() } send: { _ in }

        XCTAssertTrue(host.canShow(document()))
        XCTAssertTrue(host.canShow(document(version: "1.2.0")))
        XCTAssertFalse(host.canShow(document(version: "2.0.0")))
        XCTAssertFalse(host.canShow(document(format: .a2ui)))
        XCTAssertNil(host.content(for: document(format: .a2ui), messageID: "m1"))
        XCTAssertFalse(AIUIView(host: host, document: document(format: .a2ui), messageID: "m1").canShow)
    }

    func testEachRendererHasOneEngineForTheWholeConversation() throws {
        let renderer = TestRenderer()
        let host = AIUIHost { renderer } send: { _ in }

        XCTAssertNotNil(host.content(for: document("root = Card([a])"), messageID: "m1"))
        XCTAssertNotNil(host.content(for: document("root = Card([b])"), messageID: "m2"))

        XCTAssertEqual(renderer.engines.count, 1)
        let engine = try XCTUnwrap(renderer.engines.first)
        XCTAssertTrue(engine.host === host, "an engine works for the conversation's host")
        XCTAssertEqual(engine.shown.map(\.messageID), ["m1", "m2"])
        XCTAssertEqual(engine.shown.map(\.document.text), ["root = Card([a])", "root = Card([b])"])
    }

    func testRenderersOfOneFormatEachShowTheVersionsTheyRead() {
        let first = TestRenderer()
        let second = TestRenderer(versions: "2.")
        let host = AIUIHost {
            first
            second
        } send: { _ in }

        guard case .first = host.content(for: document("root = Card([a])", version: "1.0.0"), messageID: "m1"),
              case .second = host.content(for: document("root = Card([b])", version: "2.0.0"), messageID: "m2"),
              case .first = host.content(for: document("root = Card([c])"), messageID: "m3")
        else { return XCTFail("the first renderer that reads a version shows it, as its own view") }

        XCTAssertEqual(first.engines.count, 1)
        XCTAssertEqual(second.engines.count, 1, "each renderer has an engine of its own")
        XCTAssertEqual(first.engines.first?.shown.map(\.messageID), ["m1", "m3"])
        XCTAssertEqual(second.engines.first?.shown.map(\.messageID), ["m2"])
    }

    func testRenderersAreAskedInTheOrderTheyAreListed() {
        let openUI = TestRenderer(format: .openUI)
        let a2ui = TestRenderer(format: .a2ui)
        let cards = TestRenderer(format: "cards")
        let host = AIUIHost {
            openUI
            a2ui
            cards
        } send: { _ in }

        XCTAssertNotNil(host.content(for: document(format: "cards"), messageID: "m1"))
        XCTAssertNotNil(host.content(for: document(format: .a2ui), messageID: "m2"))
        XCTAssertNotNil(host.content(for: document(format: "cards"), messageID: "m3"))

        XCTAssertEqual(host.renderers.all.map(\.format), [.openUI, .a2ui, "cards"])
        XCTAssertTrue(openUI.engines.isEmpty, "an engine is made the first time its renderer shows something")
        XCTAssertEqual(a2ui.engines.first?.shown.map(\.messageID), ["m2"])
        XCTAssertEqual(cards.engines.count, 1)
        XCTAssertEqual(cards.engines.first?.shown.map(\.messageID), ["m1", "m3"])
    }

    func testAReplysTextShowsWhenItsUIShowsNothing() {
        let host = AIUIHost { TestRenderer() } send: { _ in }
        let nothing = AIUIDocument(format: .openUI, content: .array([]))

        XCTAssertTrue(host.canShow(nothing), "a renderer reads the format")
        XCTAssertNil(host.content(for: nothing, messageID: "m1"), "but shows nothing of its own for the reply, so its text shows")
        XCTAssertFalse(AIUIView(host: host, document: nothing, messageID: "m1").canShow)
        XCTAssertNotNil(host.content(for: document(), messageID: "m2"))
        XCTAssertTrue(AIUIView(host: host, document: document(), messageID: "m2").canShow)
    }

    func testEnginesReceiveEachReplysUIOldestFirstWhetherOrNotItShows() throws {
        let openUI = TestRenderer()
        let a2ui = TestRenderer(format: .a2ui)
        let host = AIUIHost {
            openUI
            a2ui
        } send: { _ in }
        var replies = [
            Reply(id: "q1", role: .user, uiDocument: document("root = Card([q])")),
            Reply(id: "a1", uiDocument: document("root = Card([a])")),
            Reply(id: "a2", text: "Ohrid it is"),
            Reply(id: "a3", uiDocument: document("{}", format: .a2ui)),
            Reply(id: "a4", uiDocument: document("root = Card([b])")),
            Reply(id: "a5", uiDocument: document(format: "cards"))
        ]

        host.receive(replies)

        let engine = try XCTUnwrap(openUI.engines.first)
        XCTAssertEqual(engine.received.map(\.messageID), ["a1", "a4"], "a person's message carries no UI of the agent's")
        XCTAssertEqual(a2ui.engines.first?.received.map(\.messageID), ["a3"], "each goes to the renderer that reads it")
        XCTAssertTrue(engine.shown.isEmpty, "no reply's view is asked for")

        replies[1].uiDocument = document("root = Card([a, c])")
        replies.append(Reply(id: "a6", uiDocument: document("root = Card([d])")))
        host.receive(replies)
        host.receive(replies)

        XCTAssertEqual(engine.received.map(\.messageID), ["a1", "a4", "a1", "a6"], "only what changed or arrived comes again")
        XCTAssertEqual(engine.received.suffix(2).map(\.document.text), ["root = Card([a, c])", "root = Card([d])"])
        XCTAssertEqual(openUI.engines.count, 1, "the engine that shows the replies is the one that receives them")
    }

    func testAConversationGivesEveryReplysUIToTheEnginesBeforeItsRowsShow() throws {
        let renderer = TestRenderer()
        let host = AIUIHost { renderer } send: { _ in }
        let replies = (0..<80).map { Reply(id: "a\($0)", uiDocument: document("root = Card([t\($0)])")) }

        _ = AIConversationView(messages: replies, ui: host).content(AIPendingMessageTracker())

        let engine = try XCTUnwrap(renderer.engines.first)
        XCTAssertEqual(engine.received.map(\.messageID), replies.map(\.id), "rows only show the replies on screen")
        XCTAssertTrue(engine.shown.isEmpty)
    }

    func testWhatThePersonDoesGoesToTheAgent() async {
        var sent: [AIUIAction] = []
        let host = AIUIHost { TestRenderer() } send: { sent.append($0) }
        let action = AIUIAction(messageID: "m1", format: .openUI, name: "ask_about", label: "Tell me more about Ohrid")

        host.send(action)
        for _ in 0..<10 { await Task.yield() }

        XCTAssertEqual(sent, [action])
    }

    func testTheUIRunsTheAppsTools() async throws {
        let tool = Tool()
        let host = AIUIHost(tools: [tool]) { TestRenderer() } send: { _ in }

        let output = try await host.runTool("list_events", arguments: ["day": .string("2026-11-14")])

        XCTAssertEqual(output, .dictionary(["events": .array([.string("Dinner")])]))
        XCTAssertEqual(tool.calls.first?.executor, .client)
        struct Arguments: Decodable { let day: String }
        XCTAssertEqual(try tool.calls.first?.decodeArguments(as: Arguments.self).day, "2026-11-14")

        tool.result = .failed("Calendar not shared")
        do {
            _ = try await host.runTool("list_events")
            XCTFail("a failed tool throws")
        } catch {
            XCTAssertEqual(error.localizedDescription, "Calendar not shared")
        }
        do {
            _ = try await host.runTool("send_email")
            XCTFail("an unknown tool throws")
        } catch {}
    }

    func testAComponentShowsOnlyForArgumentsThatFitItsParameters() throws {
        let host = AIUIHost(components: [placeCard]) { TestRenderer() } send: { _ in }
        let component = try XCTUnwrap(host.component(named: "place_card"))

        XCTAssertTrue(shows(component, ["title": .string("Ohrid")], in: host))
        XCTAssertFalse(shows(component, [:], in: host), "arguments still streaming in show nothing")
        XCTAssertNil(host.component(named: "trip_map"))
    }

    func testAComponentTellsTheAgentWhatThePersonDidTheWayItsRendererDoes() {
        var emitted: [(event: String, label: String, payload: [String: RawJSON])] = []
        let host = AIUIHost(components: [placeCard]) { TestRenderer() } send: { _ in }
        let context = AIUIComponentContext(messageID: "m1", isStreaming: false, host: host) { event, label, payload in
            emitted.append((event, label, payload))
        }

        context.emit("ask_about", label: "Tell me more about Ohrid", payload: ["title": .string("Ohrid")])
        context.emit("select_place", label: "Tell me more about Kaneo")

        XCTAssertEqual(emitted.map(\.event), ["ask_about", "select_place"])
        XCTAssertEqual(emitted.map(\.label), ["Tell me more about Ohrid", "Tell me more about Kaneo"])
        XCTAssertEqual(emitted.map(\.payload), [["title": .string("Ohrid")], [:]])
        XCTAssertEqual(context.messageID, "m1")
        XCTAssertEqual(placeCard.name, "place_card")
    }

    func testAReplysStateIsKeptWhileTheHostIs() {
        let host = AIUIHost { TestRenderer() } send: { _ in }

        host.setState(.dictionary(["pace": .string("packed")]), for: "m1")

        XCTAssertEqual(host.state(for: "m1"), .dictionary(["pace": .string("packed")]))
        XCTAssertNil(host.state(for: "m2"))
        host.setState(nil, for: "m1")
        XCTAssertNil(host.state(for: "m1"))
    }

    func testCapabilitiesListEachFormatAndTheAppsComponents() throws {
        let host = AIUIHost(components: [placeCard]) { TestRenderer() } send: { _ in }

        let capabilities = host.capabilities

        XCTAssertEqual(capabilities["v"], .number(1))
        XCTAssertEqual(capabilities["renderers"], .array([.dictionary(["format": .string("openui"), "components": .number(1)])]))
        let component = try XCTUnwrap(capabilities["components"]?.arrayValue?.first?.dictionaryValue)
        XCTAssertEqual(component["name"], .string("place_card"))
        XCTAssertEqual(component["parameters"]?.dictionaryValue?["required"], .array([.string("title")]))
    }
}
