//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// A reply of the agent: the steps it took, then its answer, written out as it arrives, and
/// then its attachments.
///
/// Reasoning shows with ``StreamingReasoningView``, open while the model thinks, and other
/// steps with ``AIMessagePartView``, which asks this person about a tool call that waits for
/// their approval.
///
/// ```swift
/// AIAssistantMessageView(text: reply.text, isGenerating: reply.isGenerating, parts: reply.parts)
/// ```
public struct AIAssistantMessageView<Factory: AIConversationViewFactory>: View {
    var viewFactory: Factory
    var text: String
    var isGenerating: Bool
    var parts: [AIMessagePart]
    var attachments: [AIMessageAttachment]
    var approver: AIToolApprover?
    var reasoningText: (AIReasoningPart) -> String?

    // Whether the answer is shown as still being written, which is what types it out. A fast
    // reply's text can arrive in the same update that finishes it, and only what arrives
    // while the answer is being written is typed, so it is written until the text reaches it.
    @State private var writing: Bool

    @Injected(\.aiAppearance.tokens.layout) private var layout

    /// - Parameters:
    ///   - viewFactory: The views of the attachments, and the one that asks for a tool call's
    ///     sign-in.
    ///   - text: The answer, in Markdown.
    ///   - isGenerating: Whether the agent is still writing it.
    ///   - parts: The steps the agent took, in order.
    ///   - attachments: What the agent sent with it, such as images and files.
    ///   - approver: Who answers tool calls' questions and sign-ins on this device, to ask them.
    ///   - reasoningText: The whole of a reasoning step's thinking, when the app has it.
    public init(
        viewFactory: Factory = DefaultAIConversationViewFactory.shared,
        text: String,
        isGenerating: Bool = false,
        parts: [AIMessagePart] = [],
        attachments: [AIMessageAttachment] = [],
        approver: AIToolApprover? = nil,
        reasoningText: @escaping (AIReasoningPart) -> String? = { _ in nil }
    ) {
        self.viewFactory = viewFactory
        self.text = text
        self.isGenerating = isGenerating
        self.parts = parts
        self.attachments = attachments
        self.approver = approver
        self.reasoningText = reasoningText
        _writing = State(initialValue: isGenerating)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: layout.spacingXs) {
            if !parts.isEmpty {
                AIMessagePartsView(parts: parts) { part in
                    if let step = part.reasoning {
                        StreamingReasoningView(part: step, text: reasoningText(step))
                    } else {
                        AIMessagePartView(viewFactory: viewFactory, part: part, approver: approver)
                    }
                }
            }
            if !text.isEmpty {
                StreamingMessageView(content: text, isGenerating: writing)
            }
            ForEach(attachments.indices, id: \.self) { index in
                viewFactory.makeAttachmentView(
                    options: AIMessageAttachmentViewOptions(attachment: attachments[index], role: .assistant)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transformPreference(AnswerWritingKey.self) { answerWriting in
            answerWriting = (answerWriting ?? false) || isGenerating || writing
        }
        .task(id: isGenerating) {
            guard !isGenerating else {
                writing = true
                return
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
            guard !Task.isCancelled else { return }
            writing = false
        }
    }
}
