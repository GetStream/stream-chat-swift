//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The agent couldn't answer: it said so, such as with an ``AIAgentActivity`` in the error state,
/// or its reply didn't start in time.
@available(iOS 15.0, macOS 12.0, *)
public struct AIAgentError: LocalizedError, Hashable, Sendable {
    /// What the agent said about it, if anything.
    public let message: String?

    public init(message: String? = nil) {
        self.message = message
    }

    public var errorDescription: String? {
        if let message, !message.isEmpty {
            return message
        }
        return L10n.Conversation.agentError
    }
}
