//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
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

        func reasoningText(for step: AIReasoningPart) -> String? {
            thinking
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

    private func view(_ message: Message) -> AIConversationEntryView<Message, DefaultAIConversationViewFactory> {
        AIConversationEntryView(
            entry: AIConversationEntry(id: AnyHashable(message.id), content: .message(message), sentAttachments: []),
            factory: .shared,
            approver: nil
        )
    }
}
