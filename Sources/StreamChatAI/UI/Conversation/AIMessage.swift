//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A message ``AIConversationView`` can show by itself: the person's in a bubble with its
/// attachments, and the agent's as its steps, its answer and then its attachments.
///
/// ```swift
/// struct Message: AIMessage {
///     var id: String
///     var role: AIMessageRole
///     var text: String
///     var isGenerating = false
/// }
/// ```
public protocol AIMessage: Identifiable {
    /// Who wrote it.
    var role: AIMessageRole { get }
    /// What it says. A reply's text is Markdown.
    var text: String { get }
    /// Whether the agent is still writing it.
    var isGenerating: Bool { get }
    /// The steps the agent took for it, in order: reasoning, tool calls, and kinds of its own.
    var parts: [AIMessagePart] { get }
    /// What it carries besides its text, such as images and files.
    var attachments: [AIMessageAttachment] { get }
    /// The whole of a reasoning step's thinking when the app has it, such as from live
    /// updates. Without it, the step shows its own excerpt.
    func reasoningText(for step: AIReasoningPart) -> String?
}

public extension AIMessage {
    var isGenerating: Bool { false }
    var parts: [AIMessagePart] { [] }
    var attachments: [AIMessageAttachment] { [] }
    func reasoningText(for step: AIReasoningPart) -> String? { nil }
}

/// Who wrote a message.
public enum AIMessageRole: Hashable, Sendable {
    /// The person using the app. Each of their messages starts a turn.
    case user
    /// The agent.
    case assistant
}

extension AIMessage {
    // A reply the agent has started but that has nothing to show yet.
    var showsNothing: Bool {
        role == .assistant && text.isEmpty && parts.isEmpty && attachments.isEmpty
    }
}
