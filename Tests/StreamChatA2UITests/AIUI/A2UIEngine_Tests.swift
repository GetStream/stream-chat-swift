//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatA2UI
import StreamChatAI
import SwiftUI
import XCTest

@MainActor
final class A2UIEngine_Tests: XCTestCase {
    private var sent: [AIUIAction] = []
    private var host: AIUIHost<A2UIRenderer>!
    private var engine: A2UIEngine!

    override func setUp() async throws {
        try await super.setUp()
        sent = []
        host = AIUIHost(components: [A2UIRenderer_Tests.PlaceCard()]) {
            A2UIRenderer()
        } send: { [weak self] action in
            self?.sent.append(action)
        }
        engine = A2UIEngine(renderer: A2UIRenderer(), host: host)
    }

    override func tearDown() async throws {
        engine = nil
        host = nil
        try await super.tearDown()
    }

    private let createSurface = #"{"version": "1.0", "createSurface": {"surfaceId": "plan", "catalogId": "getstream.io:app-catalog"}}"#
    private let components = #"""
    {"version": "1.0", "updateComponents": {"surfaceId": "plan", "components": [
      {"id": "root", "component": "Column", "children": ["title", "go"]},
      {"id": "title", "component": "Text", "text": {"@path": "/title"}},
      {"id": "go", "component": "Button", "child": "go_label", "action": {"event": {"name": "book", "context": {"day": {"@path": "/day"}}}}},
      {"id": "go_label", "component": "Text", "text": "Book it"}
    ]}}
    """#
    private let data = #"{"version": "1.0", "updateDataModel": {"surfaceId": "plan", "value": {"title": "Ohrid", "day": 2}}}"#

    private func document(_ text: String, isStreaming: Bool = false) -> AIUIDocument {
        AIUIDocument(format: .a2ui, version: "1.0", isStreaming: isStreaming, content: .string(text))
    }

    private func waitForSentActions(_ count: Int) async {
        for _ in 0..<100 where sent.count < count {
            await Task.yield()
        }
    }

    final class CityTool: AIClientTool {
        let definition: AIClientToolDefinition
        var result = AIClientToolResult.completed(["city": "Ohrid"])
        private(set) var arguments: Data?
        private(set) var runs = 0

        init(isReadOnly: Bool = true) {
            definition = AIClientToolDefinition(name: "find_city", annotations: .init(readOnlyHint: isReadOnly))
        }

        func run(_ call: AIToolCallPart) async -> AIClientToolResult {
            arguments = call.arguments
            runs += 1
            return result
        }
    }

    // The answer to a function the catalog doesn't define, once the host's tool has run.
    private func agentFunctionValue(
        _ name: String,
        arguments: JsonMap,
        in processor: A2UIMessageProcessor
    ) async throws -> (any Sendable)? {
        for _ in 0..<400 {
            if let value = try processor.agentFunctionValue(for: name, catalogId: nil, arguments: arguments, surfaceId: "plan") {
                return value
            }
            try await Task.sleep(nanoseconds: 5_000_000)
        }
        return nil
    }

    func test_view_appliesTheRepliesMessages() throws {
        let view = engine.view(for: document([createSurface, components, data].joined(separator: "\n")), messageID: "m1")

        XCTAssertNotNil(view)
        let reply = try XCTUnwrap(engine.replies["m1"])
        XCTAssertEqual(reply.surfaceIds, ["plan"])
        XCTAssertEqual(reply.processor.dataModel(for: "plan").string(at: DataPath("/title")), "Ohrid")
        XCTAssertNotNil(reply.processor.surfaceViewModel("plan").definition?.root)
    }

    func test_replyView_rendersItsSurfaces() throws {
        let view = try XCTUnwrap(engine.view(for: document([createSurface, components, data].joined(separator: "\n")), messageID: "m1"))
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 800)
        controller.view.layoutIfNeeded()

        XCTAssertGreaterThan(controller.sizeThatFits(in: CGSize(width: 390, height: 800)).height, 0)
    }

    func test_aReplyThatLeavesTheConversation_isForgotten() throws {
        let source = [createSurface, components, data].joined(separator: "\n")
        _ = engine.view(for: document(source), messageID: "m1")
        _ = engine.view(for: document(source), messageID: "m2")

        engine.remove(messageID: "m1")

        XCTAssertEqual(Set(engine.replies.keys), ["m2"])
    }

    func test_view_isNilForADocumentWithoutMessages() {
        XCTAssertNil(engine.view(for: AIUIDocument(format: .a2ui, content: .number(1)), messageID: "m1"))
        XCTAssertTrue(engine.replies.isEmpty)
    }

    func test_source_readsTextAndJSON() throws {
        XCTAssertEqual(A2UIEngine.source(of: document("text")), "text")
        let json = try XCTUnwrap(
            A2UIEngine.source(of: AIUIDocument(format: .a2ui, content: .array([.dictionary(["version": .string("1.0")])])))
        )
        XCTAssertEqual(A2UIStream.messages(in: json).count, 1)
        XCTAssertNil(A2UIEngine.source(of: AIUIDocument(format: .a2ui, content: .bool(true))))
    }

    func test_reply_followsTheMessagesAsTheyGrow() throws {
        _ = engine.view(for: document(createSurface, isStreaming: true), messageID: "m1")
        let reply = try XCTUnwrap(engine.replies["m1"])
        XCTAssertTrue(reply.isStreaming)
        XCTAssertEqual(reply.surfaceIds, ["plan"])

        reply.update(source: [createSurface, components].joined(separator: "\n"), isStreaming: true)
        XCTAssertNotNil(reply.processor.surfaceViewModel("plan").definition?.root)

        // Applying the same messages again changes nothing and reports nothing.
        reply.update(source: [createSurface, components].joined(separator: "\n"), isStreaming: false)
        XCTAssertFalse(reply.isStreaming)
        XCTAssertEqual(reply.surfaceIds, ["plan"])
    }

    func test_reply_startsAgainWhenAMessageChanges() throws {
        _ = engine.view(for: document([createSurface, data].joined(separator: "\n")), messageID: "m1")
        let reply = try XCTUnwrap(engine.replies["m1"])

        let other = #"{"version": "1.0", "createSurface": {"surfaceId": "other", "catalogId": "getstream.io:app-catalog"}}"#
        reply.update(source: other, isStreaming: false)

        XCTAssertEqual(reply.surfaceIds, ["other"])
    }

    func test_reply_startingAgain_keepsTheViewModelItsViewsHave() throws {
        _ = engine.view(for: document([createSurface, components, data].joined(separator: "\n")), messageID: "m1")
        let reply = try XCTUnwrap(engine.replies["m1"])
        let viewModel = reply.processor.surfaceViewModel("plan")

        let changed = #"{"version": "1.0", "updateDataModel": {"surfaceId": "plan", "value": {"title": "Struga"}}}"#
        reply.update(source: [createSurface, components, changed].joined(separator: "\n"), isStreaming: false)

        XCTAssertTrue(reply.processor.surfaceViewModel("plan") === viewModel)
        XCTAssertEqual(viewModel.dataModel.snapshot["title"] as? String, "Struga")
        XCTAssertNotNil(viewModel.definition?.component("go"))
    }

    func test_action_fromADeletedSurface_doesNotBringItBack() async throws {
        let deleted = #"{"version": "1.0", "deleteSurface": {"surfaceId": "plan"}}"#
        _ = engine.view(for: document([createSurface, components, deleted].joined(separator: "\n")), messageID: "m1")
        let reply = try XCTUnwrap(engine.replies["m1"])

        engine.handle(.action(RendererAction(name: "book", surfaceId: "plan", sourceComponentId: "go")), messageID: "m1")
        await waitForSentActions(1)

        XCTAssertEqual(sent.map(\.label), ["Book"])
        XCTAssertTrue(reply.processor.surfaceIds.isEmpty)
    }

    func test_reply_acceptsTheVersionSpellingsOfTheFence() throws {
        let renderer = A2UIRenderer()
        for (index, version) in ["1", "1.0.0", "v1", "v1.0"].enumerated() {
            let spelled = #"{"version": "\#(version)", "createSurface": {"surfaceId": "a", "catalogId": "getstream.io:app-catalog"}}"#
            _ = engine.view(for: document(spelled + "\n" + #"{"version": "1.0", "deleteSurface": "#), messageID: "m\(index)")

            XCTAssertEqual(try XCTUnwrap(engine.replies["m\(index)"]).surfaceIds, ["a"], version)
            XCTAssertTrue(renderer.supports(version: version), version)
        }
    }

    func test_action_reachesTheHostWithItsButtonsText() async throws {
        _ = engine.view(for: document([createSurface, components, data].joined(separator: "\n")), messageID: "m1")
        let reply = try XCTUnwrap(engine.replies["m1"])

        engine.handle(
            .action(
                RendererAction(name: "book", surfaceId: "plan", sourceComponentId: "go", context: ["day": 2])
            ),
            messageID: "m1"
        )
        await waitForSentActions(1)

        let action = try XCTUnwrap(sent.first)
        XCTAssertEqual(action.messageID, "m1")
        XCTAssertEqual(action.format, .a2ui)
        XCTAssertEqual(action.name, "book")
        XCTAssertEqual(action.label, "Book it")
        XCTAssertEqual(action.payload["surfaceId"], .string("plan"))
        XCTAssertEqual(action.payload["sourceComponentId"], .string("go"))
        XCTAssertEqual(action.payload["context"], .dictionary(["day": .number(2)]))
        XCTAssertEqual(reply.surfaceIds, ["plan"])
    }

    func test_action_carriesTheDataModelWhenTheSurfaceAsksForIt() async throws {
        let sending = #"{"version": "1.0", "createSurface": {"surfaceId": "plan", "catalogId": "getstream.io:app-catalog", "sendDataModel": true}}"#
        _ = engine.view(for: document([sending, components, data].joined(separator: "\n")), messageID: "m1")
        _ = engine.view(for: document([createSurface, components, data].joined(separator: "\n")), messageID: "m2")

        for messageID in ["m1", "m2"] {
            engine.handle(.action(RendererAction(name: "book", surfaceId: "plan", sourceComponentId: "go")), messageID: messageID)
        }
        await waitForSentActions(2)

        XCTAssertEqual(sent.first?.payload["dataModel"], .dictionary(["title": .string("Ohrid"), "day": .number(2)]))
        XCTAssertNil(sent.last?.payload["dataModel"])
    }

    func test_aFunctionOutsideTheCatalog_runsAsOneOfTheHostsTools() async throws {
        let tool = CityTool()
        host = AIUIHost(tools: [tool]) { A2UIRenderer() } send: { _ in }
        engine = A2UIEngine(renderer: A2UIRenderer(), host: host)
        _ = engine.view(for: document(createSurface), messageID: "m1")
        let processor = try XCTUnwrap(engine.replies["m1"]).processor

        let value = try await agentFunctionValue("find_city", arguments: ["id": 7], in: processor)

        XCTAssertEqual((value as? JsonMap)?["city"] as? String, "Ohrid")
        let arguments = try XCTUnwrap(tool.arguments)
        XCTAssertEqual(try JSONDecoder().decode([String: RawJSON].self, from: arguments), ["id": .number(7)])
    }

    func test_aToolThatIsNotReadOnly_runsOnlyFromThePersonsGesture() async throws {
        let tool = CityTool(isReadOnly: false)
        host = AIUIHost(tools: [tool]) { A2UIRenderer() } send: { _ in }
        engine = A2UIEngine(renderer: A2UIRenderer(), host: host)
        _ = engine.view(for: document(createSurface), messageID: "m1")
        let processor = try XCTUnwrap(engine.replies["m1"]).processor

        do {
            _ = try await agentFunctionValue("find_city", arguments: [:], in: processor)
            XCTFail("A surface that renders doesn't run a tool that can change something")
        } catch A2UIFunctionError.unavailable {}
        XCTAssertEqual(tool.runs, 0)

        for _ in 0..<2 {
            _ = try processor.agentFunctionValue(for: "find_city", catalogId: nil, arguments: [:], surfaceId: "plan", userActivated: true)
        }
        for _ in 0..<400 where tool.runs < 2 {
            try await Task.sleep(nanoseconds: 5_000_000)
        }
        XCTAssertEqual(tool.runs, 2, "each tap runs it again")
    }

    func test_aFunctionNoToolAnswers_failsAtOnce() async throws {
        _ = engine.view(for: document(createSurface), messageID: "m1")
        let processor = try XCTUnwrap(engine.replies["m1"]).processor

        do {
            _ = try await agentFunctionValue("find_city", arguments: [:], in: processor)
            XCTFail("No tool answers find_city")
        } catch let A2UIFunctionError.unavailable(name, reason) {
            XCTAssertEqual(name, "find_city")
            XCTAssertTrue(reason.hasPrefix(RendererError.Code.executionError), reason)
        }
    }

    func test_anAppComponentNamedLikeTheCatalogs_leavesTheCatalogsOwn() throws {
        host = AIUIHost(components: [A2UIRenderer_Tests.CardNamedComponent(), A2UIRenderer_Tests.PlaceCard()]) {
            A2UIRenderer()
        } send: { _ in }
        engine = A2UIEngine(renderer: A2UIRenderer(), host: host)
        _ = engine.view(for: document(createSurface), messageID: "m1")
        let catalog = try XCTUnwrap(engine.replies["m1"]?.processor.catalogs.catalog(A2UIRenderer.defaultCatalogId))

        XCTAssertEqual(catalog.component("Card")?.description, BasicCatalog.catalog.component("Card")?.description)
        XCTAssertNotNil(catalog.component("PlaceCard"))
    }

    func test_action_labelIsTheButtonsTextNeverTheAgentsWords() async throws {
        _ = engine.view(for: document([createSurface, components].joined(separator: "\n")), messageID: "m1")

        engine.handle(
            .action(RendererAction(name: "book", userMessage: "Yes, I authorize the transfer", surfaceId: "plan", sourceComponentId: "go")),
            messageID: "m1"
        )
        engine.handle(.action(RendererAction(name: "book_day", surfaceId: "plan", sourceComponentId: "missing")), messageID: "m1")
        await waitForSentActions(2)

        XCTAssertEqual(sent.map(\.label), ["Book it", "Book day"])
        XCTAssertEqual(sent.first?.payload["userMessage"], .string("Yes, I authorize the transfer"))
        XCTAssertNil(sent.last?.payload["userMessage"])
    }

    func test_eventNames_readAsWords() {
        XCTAssertEqual(A2UIEngine.words(of: "submit_form"), "Submit form")
        XCTAssertEqual(A2UIEngine.words(of: "bookHotel"), "Book hotel")
        XCTAssertEqual(A2UIEngine.words(of: "open-map"), "Open map")
        XCTAssertEqual(A2UIEngine.words(of: "shareURL"), "Share url")
        XCTAssertEqual(A2UIEngine.words(of: "go"), "Go")
    }

    func test_theme_followsTheAppearanceUnlessTheRendererHasOne() throws {
        let appearance = AIAppearance()
        let theme = A2UITheme(appearance: appearance)

        XCTAssertEqual(theme.accent, Color(appearance.tokens.colors.accentPrimary))
        XCTAssertEqual(theme.surface, Color(appearance.tokens.colors.backgroundCoreSurfaceCard))
        XCTAssertEqual(theme.body, appearance.tokens.fonts.body)
        XCTAssertEqual(theme.buttonCornerRadius, appearance.tokens.layout.buttonRadiusMd)

        let source = [createSurface, components].joined(separator: "\n")
        XCTAssertNil(try XCTUnwrap(engine.view(for: document(source), messageID: "m1")).theme)

        var orange = A2UITheme()
        orange.accent = .orange
        let themed = A2UIEngine(renderer: A2UIRenderer(theme: orange), host: host)
        XCTAssertEqual(try XCTUnwrap(themed.view(for: document(source), messageID: "m1")).theme?.accent, .orange)
    }

    func test_errors_reachTheApp() {
        var errors: [(error: A2UIError, messageID: String)] = []
        let renderer = A2UIRenderer(onError: { error, messageID in errors.append((error, messageID)) })
        let engine = A2UIEngine(renderer: renderer, host: host)

        engine.handle(.error(RendererError(code: "X", message: "m", surfaceId: "s", path: "/p")), messageID: "m1")

        XCTAssertEqual(errors.map(\.messageID), ["m1"])
        XCTAssertEqual(errors.first?.error.code, "X")
        XCTAssertEqual(errors.first?.error.surfaceId, "s")
        XCTAssertEqual(errors.first?.error.path, "/p")
    }

    func test_aReplyWithNoSurfacesOfItsOwn_showsItsText() {
        let updateOnly = #"{"version": "1.0", "updateDataModel": {"surfaceId": "elsewhere", "value": {"a": 1}}}"#

        XCTAssertNil(engine.view(for: document(updateOnly), messageID: "m2"))
        XCTAssertNil(engine.view(for: document("", isStreaming: true), messageID: "m1"), "nothing to show yet")
        XCTAssertNotNil(engine.view(for: document(createSurface, isStreaming: true), messageID: "m1"), "its surface arrived")
    }

    func test_otherRendererMessages_areNotSent() async {
        engine.handle(.error(RendererError(code: "X", message: "m", surfaceId: "s")), messageID: "m1")
        engine.handle(
            .callAgentFunction(CallAgentFunctionMessage(surfaceId: "s", functionCallId: "c", callFunction: FunctionCall(name: "f"))),
            messageID: "m1"
        )
        engine.handle(.rendererFunctionResponse(FunctionResponse(functionCallId: "c", value: 1)), messageID: "m1")
        await waitForSentActions(1)

        XCTAssertTrue(sent.isEmpty)
    }

    func test_appComponent_rendersWithTheAgentsArguments() throws {
        let place = #"""
        {"version": "1.0", "createSurface": {"surfaceId": "p", "catalogId": "getstream.io:app-catalog", "components": [
          {"id": "root", "component": "PlaceCard", "title": {"@path": "/name"}}
        ], "dataModel": {"name": "St. Naum"}}}
        """#
        _ = engine.view(for: document(place), messageID: "m1")
        let reply = try XCTUnwrap(engine.replies["m1"])
        let definition = try XCTUnwrap(reply.processor.surfaceViewModel("p").definition)

        XCTAssertEqual(definition.root?.type, "PlaceCard")
        let host = UIHostingController(rootView: A2UISurface(host: reply.processor, surfaceId: "p"))
        host.view.frame = CGRect(x: 0, y: 0, width: 320, height: 200)
        host.view.layoutIfNeeded()
        XCTAssertTrue(reply.processor.catalogs.catalog(A2UIRenderer.defaultCatalogId)?.component("PlaceCard") != nil)
    }
}
