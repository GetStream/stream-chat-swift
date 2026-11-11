//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// What an ``AIConversation``'s views offer the person to do with its messages, besides copying
/// and sharing a reply. Leave out what your agent or backend doesn't support.
///
/// ```swift
/// AIConversation(transport: transport, actions: [.rate])
/// ```
@available(iOS 15.0, macOS 12.0, *)
public struct AIConversationActions: OptionSet, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) { self.rawValue = rawValue }

    /// Editing the person's latest message, which is then answered again.
    public static let edit = AIConversationActions(rawValue: 1 << 0)
    /// Asking for a new reply in place of the latest.
    public static let regenerate = AIConversationActions(rawValue: 1 << 1)
    /// Rating replies.
    public static let rate = AIConversationActions(rawValue: 1 << 2)

    /// Every action.
    public static let all: AIConversationActions = [.edit, .regenerate, .rate]
}
