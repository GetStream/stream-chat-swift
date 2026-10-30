//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import SwiftUI
import XCTest

@MainActor
final class AIConversationEntryView_Tests: XCTestCase {
    private struct Message: AIMessage {
        var id: String
        var role: AIMessageRole = .assistant
        var text = "Lisbon it is"
        var isGenerating = true
        var parts: [AIMessagePart] = AIMessagePart.parts(from: [
            ("ai_reasoning", Data(#"{"id":"r1","status":"completed","preview":"Planning"}"#.utf8))
        ])
        var attachments: [AIMessageAttachment] = []
        var thinking: String?
        var uiDocument: AIUIDocument?

        func reasoningText(for step: AIReasoningPart) -> String? {
            thinking
        }
    }

    private final class RecordingFactory: AIConversationViewFactory {
        var answers: [String: String] = [:]
        var repliesWithActions: Set<String> = []

        func makeAssistantMessageView(options: AIAssistantMessageViewOptions) -> some View {
            answers[String(describing: options.message.id)] = options.text
            return EmptyView()
        }

        func makeReplyActionsView(options: AIReplyActionsViewOptions) -> some View {
            repliesWithActions.insert(String(describing: options.message.id))
            return EmptyView()
        }
    }

    func test_equal_whenTheMessageShowsTheSame() {
        XCTAssertEqual(view(Message(id: "a1")), view(Message(id: "a1")))
    }

    func test_notEqual_whenTheAnswerGrows() {
        XCTAssertNotEqual(view(Message(id: "a1")), view(Message(id: "a1", text: "Lisbon it is, for two")))
    }

    func test_notEqual_whenTheReasoningGrows() {
        XCTAssertNotEqual(
            view(Message(id: "a1", thinking: "Planning")),
            view(Message(id: "a1", thinking: "Planning a weekend")),
            "the whole of the thinking is not part of the message, but shows in it"
        )
    }

    func test_equal_whenTheAttachmentsAreMadeAgain() {
        let chart = URL(string: "https://example.com/chart.png")!
        XCTAssertEqual(
            view(Message(id: "a1", attachments: [.image(chart)])),
            view(Message(id: "a1", attachments: [.image(chart)])),
            "apps make a message's attachments each time they are read"
        )
    }

    func test_notEqual_whenAnAttachmentArrives() {
        XCTAssertNotEqual(
            view(Message(id: "a1")),
            view(Message(id: "a1", attachments: [.file(URL(string: "https://example.com/plan.pdf")!)]))
        )
    }

    func test_notEqual_whenTheReplyFinishes() {
        XCTAssertNotEqual(view(Message(id: "a1")), view(Message(id: "a1", isGenerating: false)))
    }

    func test_notEqual_whenThePersonCanSignInAnotherWay() {
        let approver = AIToolApprover(userID: "u_1", clientID: "ios-1") { _, _ in }
        var signingIn = approver
        signingIn.authorizer = AIToolAuthorizer(callbackScheme: "com.example.app") { _ in }
        var elsewhere = approver
        elsewhere.authorizer = AIToolAuthorizer(callbackScheme: "com.example.other") { _ in }

        XCTAssertNotEqual(view(Message(id: "a1"), approver: approver), view(Message(id: "a1"), approver: signingIn))
        XCTAssertNotEqual(view(Message(id: "a1"), approver: signingIn), view(Message(id: "a1"), approver: elsewhere))
        XCTAssertEqual(view(Message(id: "a1"), approver: signingIn), view(Message(id: "a1"), approver: signingIn))
    }

    func test_notEqual_whenTheReplysUIGrows() {
        XCTAssertNotEqual(
            view(Message(id: "a1", uiDocument: ui("root = Card([])"))),
            view(Message(id: "a1", uiDocument: ui("root = Card([title])")))
        )
        XCTAssertEqual(
            view(Message(id: "a1", uiDocument: ui("root = Card([title])"))),
            view(Message(id: "a1", uiDocument: ui("root = Card([title])")))
        )
    }

    func test_uiRow_notEqual_whenItsHostChanges() {
        let host = AIUIHost { AIUIHost_Tests.TestRenderer() } send: { _ in }
        let reply = Message(id: "a1", uiDocument: ui("root = Card([])"))

        XCTAssertEqual(row(reply, host: host), row(reply, host: host))
        XCTAssertNotEqual(row(reply, host: host), row(reply, host: AIUIHost { AIUIHost_Tests.TestRenderer() } send: { _ in }))
        XCTAssertNotEqual(row(reply, host: host), row(reply, host: noHost))
        XCTAssertNotEqual(
            row(reply, host: host),
            row(Message(id: "a1", uiDocument: ui("root = Card([title])")), host: host)
        )
    }

    func test_uiRow_showsTheReplysUI_whenItsHostReadsIt() {
        let host = AIUIHost { AIUIHost_Tests.TestRenderer() } send: { _ in }
        let reply = Message(id: "a1", uiDocument: ui("root = Card([])"))

        XCTAssertNotNil(row(reply, host: host).generated)
        XCTAssertNil(row(reply, host: noHost).generated, "without a host the reply shows its text")
        XCTAssertNil(row(Message(id: "a2"), host: host).generated, "a reply without UI shows its text")
        XCTAssertNil(
            row(Message(id: "a3", uiDocument: AIUIDocument(format: .a2ui, content: .string("{}"))), host: host).generated,
            "nor does UI no renderer of the host reads"
        )
        XCTAssertNil(row(Message(id: "q1", role: .user, uiDocument: ui("root = Card([])")), host: host).generated)
    }

    func test_uiRow_showsTheReplysActions_onceItsUIIsWrittenOut() throws {
        guard #available(iOS 16, *) else { throw XCTSkip("Rows render with ImageRenderer") }
        let factory = RecordingFactory()
        let host = AIUIHost { AIUIHost_Tests.TestRenderer() } send: { _ in }
        let finished = AIUIDocument(format: .openUI, content: .string("root = Card([title])"))

        render(row(Message(id: "a1", text: "", isGenerating: false, uiDocument: finished), host: host, factory: factory))
        render(row(Message(id: "a2", text: "", isGenerating: true, uiDocument: ui("root = Card([])")), host: host, factory: factory))
        render(row(Message(id: "a3", text: "", isGenerating: false), host: host, factory: factory))
        render(row(Message(id: "a4", isGenerating: false), host: host, factory: factory))

        XCTAssertEqual(factory.repliesWithActions, ["a1", "a4"], "a finished reply has actions, whether it answers in UI or in text")
        XCTAssertEqual(factory.answers["a1"], "", "the reply's UI shows in place of its text")
        XCTAssertEqual(factory.answers["a4"], "Lisbon it is")
    }

    private let noHost: AIUIHost<AIUIHost_Tests.TestRenderer>? = nil

    private func ui(_ program: String) -> AIUIDocument {
        AIUIDocument(format: .openUI, isStreaming: true, content: .string(program))
    }

    private func view(
        _ message: Message,
        approver: AIToolApprover? = nil
    ) -> AIConversationEntryView<Message, DefaultAIConversationViewFactory> {
        AIConversationEntryView(
            entry: AIConversationEntry(id: AnyHashable(message.id), message: message, sentAttachments: []),
            factory: .shared,
            approver: approver
        )
    }

    private func row<Renderers: AIUIRenderers>(
        _ message: Message,
        host: AIUIHost<Renderers>?
    ) -> AIUIConversationEntryView<Message, DefaultAIConversationViewFactory, Renderers> {
        row(message, host: host, factory: .shared)
    }

    private func row<Renderers: AIUIRenderers, Factory: AIConversationViewFactory>(
        _ message: Message,
        host: AIUIHost<Renderers>?,
        factory: Factory
    ) -> AIUIConversationEntryView<Message, Factory, Renderers> {
        AIUIConversationEntryView(
            entry: AIConversationEntry(id: AnyHashable(message.id), message: message, sentAttachments: []),
            factory: factory,
            approver: nil,
            host: host
        )
    }

    @available(iOS 16, *)
    private func render(_ view: some View) {
        _ = ImageRenderer(content: view.frame(width: 320, height: 480)).uiImage
    }
}
