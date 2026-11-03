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

    func test_reply_acceptsTheVersionSpellingsOfTheFence() throws {
        let spelled = #"{"version": "1", "createSurface": {"surfaceId": "a", "catalogId": "getstream.io:app-catalog"}}"#
        _ = engine.view(for: document(spelled + "\n" + #"{"version": "1.0", "deleteSurface": "#), messageID: "m1")

        XCTAssertEqual(try XCTUnwrap(engine.replies["m1"]).surfaceIds, ["a"])
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

    func test_action_labelPrefersTheUserMessageThenTheName() async throws {
        _ = engine.view(for: document(createSurface), messageID: "m1")

        engine.handle(
            .action(RendererAction(name: "book", userMessage: "Book day 2", surfaceId: "plan", sourceComponentId: "go")),
            messageID: "m1"
        )
        engine.handle(.action(RendererAction(name: "book", surfaceId: "plan", sourceComponentId: "missing")), messageID: "m1")
        await waitForSentActions(2)

        XCTAssertEqual(sent.map(\.label), ["Book day 2", "book"])
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
