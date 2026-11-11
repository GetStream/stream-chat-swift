//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Where an ``AIConversation``'s latest exchange with the agent is. It is an open set: compare
/// against the statuses you know.
@available(iOS 15.0, macOS 12.0, *)
public struct AIConversationStatus: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { rawValue = value }
    public var description: String { rawValue }

    /// Nothing is on its way: the agent answered, or the person stopped it.
    public static let ready: AIConversationStatus = "ready"
    /// The person's request is on its way, or the agent is working on it and its reply shows
    /// nothing yet.
    public static let submitted: AIConversationStatus = "submitted"
    /// The agent is writing its reply.
    public static let streaming: AIConversationStatus = "streaming"
    /// The latest request failed, or the agent couldn't answer it. ``AIConversation/retry()``
    /// tries again.
    public static let error: AIConversationStatus = "error"

    /// Whether the agent is answering: the request is submitted, or its reply streaming.
    public var isAnswering: Bool {
        self == .submitted || self == .streaming
    }
}
