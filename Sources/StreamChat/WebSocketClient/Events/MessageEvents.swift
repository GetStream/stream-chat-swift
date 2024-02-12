//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

// Triggered when the current user creates a new message and is pending to be sent.
public struct NewMessagePendingEvent: Event {
    public var message: ChatMessage
}

// Triggered when a message failed being sent.
public struct NewMessageErrorEvent: Event {
    public let messageId: MessageId
    public let error: Error
}
