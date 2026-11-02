//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The agent said it couldn't answer, such as with an ``AIAgentActivity`` in the error state.
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
        return L10n.Chat.agentError
    }
}
