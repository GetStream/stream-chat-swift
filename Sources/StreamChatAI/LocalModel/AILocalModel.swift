//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A language model on the device, for answering when your AI agent can't: the person is
/// offline, or the agent reached its usage limit.
///
/// `AIOnDeviceModel` is Apple's on-device model. Conform a type of your own to use another.
public protocol AILocalModel: Sendable {
    /// Whether the model can answer now.
    var isAvailable: Bool { get }
    /// Streams the answer to the last of `turns`, the person's question. Each element is the
    /// whole answer so far. Cancelling the iteration stops the model.
    func reply(instructions: String, turns: [AIConversationTurn]) -> AsyncThrowingStream<String, Error>
}

/// One turn of a conversation, for a local model.
public struct AIConversationTurn: Equatable, Sendable {
    public enum Role: Sendable {
        case user
        case assistant
    }

    public var role: Role
    public var text: String

    public init(role: Role, text: String) {
        self.role = role
        self.text = text
    }

    public static func user(_ text: String) -> AIConversationTurn {
        AIConversationTurn(role: .user, text: text)
    }

    public static func assistant(_ text: String) -> AIConversationTurn {
        AIConversationTurn(role: .assistant, text: text)
    }
}

extension AIConversationTurn {
    /// The newest turns that fit `budget` tokens, oldest first, with consecutive turns of one
    /// role merged. The question is always kept. Tokens are estimated at three bytes of UTF-8
    /// each, which overcounts English.
    static func fitting(_ turns: [AIConversationTurn], tokens budget: Int) -> [AIConversationTurn] {
        var merged: [AIConversationTurn] = []
        for turn in turns where !turn.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if merged.last?.role == turn.role {
                merged[merged.count - 1].text += "\n\n" + turn.text
            } else {
                merged.append(turn)
            }
        }
        guard let question = merged.popLast() else { return [] }
        var kept = [question]
        var remaining = budget - question.text.utf8.count / 3
        for turn in merged.reversed() {
            remaining -= turn.text.utf8.count / 3
            guard remaining >= 0 else { break }
            kept.append(turn)
        }
        return kept.reversed()
    }
}
