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
