//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A message ``AIConversationView`` can show by itself: the person's in a bubble with its
/// attachments, and the agent's as its steps, its answer and then its attachments. A message of
/// another role shows as the agent's.
///
/// ```swift
/// struct Message: AIMessage {
///     var id: String
///     var role: AIMessageRole
///     var text: String
///     var isGenerating = false
/// }
/// ```
public protocol AIMessage: Identifiable, Sendable {
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
    /// updates. Without it, the step shows its own excerpt. It is read each time the
    /// conversation updates, so look it up rather than work it out.
    func reasoningText(for step: AIReasoningPart) -> String?
}

public extension AIMessage {
    var isGenerating: Bool { false }
    var parts: [AIMessagePart] { [] }
    var attachments: [AIMessageAttachment] { [] }
    func reasoningText(for step: AIReasoningPart) -> String? { nil }
}

/// Who wrote a message. It is an open set: compare against the roles you know.
public struct AIMessageRole: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { rawValue = value }
    public var description: String { rawValue }

    /// The person using the app. Each of their messages starts a turn.
    public static let user: AIMessageRole = "user"
    /// The agent.
    public static let assistant: AIMessageRole = "assistant"
}

extension AIMessage {
    // A reply the agent has started but that has nothing to show yet.
    var showsNothing: Bool {
        role != .user && text.isEmpty && parts.isEmpty && attachments.isEmpty
    }
}
