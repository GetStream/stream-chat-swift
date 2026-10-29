//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

// What a row of an ``AIConversationView`` of ``AIMessage``s shows, made by its view factory: a
// person's message, or a reply and the actions under it. A reply with generated UI shows it, in
// its type, after its steps in place of its text.
struct AIConversationRow<Message: AIMessage, Factory: AIConversationViewFactory, Generated: View>: View {
    let entry: AIConversationEntry<Message>
    let factory: Factory
    let approver: AIToolApprover?
    let generated: Generated?

    // Whether the reply's answer is still being written out, which its actions wait for so they
    // do not move down with it. `nil` when its view does not say.
    @State private var isWriting: Bool?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Injected(\.aiAppearance.tokens.layout) private var layout

    var body: some View {
        if let message = entry.message {
            if message.role == .user {
                factory.makeUserMessageView(
                    options: AIUserMessageViewOptions(
                        message: message,
                        text: message.text,
                        attachments: entry.sentAttachments.isEmpty ? message.attachments : entry.sentAttachments
                    )
                )
            } else {
                VStack(alignment: .leading, spacing: layout.spacingXs) {
                    factory.makeAssistantMessageView(
                        options: AIAssistantMessageViewOptions(
                            message: message,
                            text: generated == nil ? message.text : "",
                            isGenerating: message.isGenerating,
                            parts: message.parts,
                            attachments: message.attachments,
                            reasoningText: message.reasoningText(for:),
                            approver: approver
                        )
                    )
                    if let generated {
                        generated
                    }
                    if !message.isGenerating && !message.text.isEmpty && isWriting != true {
                        factory.makeReplyActionsView(
                            options: AIReplyActionsViewOptions(
                                message: message,
                                text: message.text,
                                isLatestReply: entry.isLatestReply
                            )
                        )
                        .transition(.opacity)
                    }
                }
                .onPreferenceChange(AnswerWritingKey.self) { writing in
                    guard writing != isWriting else { return }
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                        isWriting = writing
                    }
                }
            }
        } else if let pending = entry.pending {
            factory.makeUserMessageView(
                options: AIUserMessageViewOptions(message: nil, text: pending.text, attachments: pending.attachments)
            )
        }
    }
}
