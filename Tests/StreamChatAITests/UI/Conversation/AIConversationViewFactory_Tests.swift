//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import SwiftUI
import XCTest

@MainActor
final class AIConversationViewFactory_Tests: XCTestCase {
    private let factory = DefaultAIConversationViewFactory.shared

    func test_replyActions_areEmptyWithoutAChat() {
        let view = factory.makeReplyActionsView(
            options: AIReplyActionsViewOptions(message: ChatMessage.reply("a1"), text: "Here's a plan", isLatestReply: true)
        )

        XCTAssertNil(actionsView(view))
    }

    func test_replyActions_showTheChatsActions() {
        let view = factory.makeReplyActionsView(
            options: AIReplyActionsViewOptions(
                message: ChatMessage.reply("a1"),
                text: "Here's a plan",
                isLatestReply: true,
                actions: AIReplyActions(rating: .positive, onRegenerate: {}, onRate: { _ in })
            )
        )

        let shown = actionsView(view)
        XCTAssertEqual(shown?.text, "Here's a plan")
        XCTAssertEqual(shown?.actions.rating, .positive)
        XCTAssertNotNil(shown?.actions.onRegenerate)
    }

    func test_userMessage_offersToEditOnlyWhenTheChatDoes() {
        let editable = factory.makeUserMessageView(
            options: AIUserMessageViewOptions(message: ChatMessage.user("u1"), text: "Plan Lisbon", attachments: [], onEdit: {})
        )
        let plain = factory.makeUserMessageView(
            options: AIUserMessageViewOptions(message: ChatMessage.user("u1"), text: "Plan Lisbon", attachments: [])
        )

        XCTAssertNotNil((editable as? AIUserMessageView<DefaultAIConversationViewFactory>)?.onEdit)
        XCTAssertNotNil(plain as? AIUserMessageView<DefaultAIConversationViewFactory>)
        XCTAssertNil((plain as? AIUserMessageView<DefaultAIConversationViewFactory>)?.onEdit)
    }

    private func actionsView(_ view: some View) -> AIReplyActionsView? {
        (view as? AIReplyActionsView?) ?? nil
    }
}
