//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a message reminder.
public struct MessageReminder {
    /// A unique identifier of the reminder, based on the message ID.
    public let id: String
    
    /// The date when the user should be reminded about this message.
    /// If nil, this is a bookmark type reminder without a notification.
    public let remindAt: Date?
    
    /// The message that has been marked for reminder.
    public let message: ChatMessage
    
    /// The channel where the message belongs to.
    public let channel: ChatChannel

    /// Date when the reminder was created on the server.
    public let createdAt: Date
    
    /// A date when the reminder was updated last time.
    public let updatedAt: Date
    
    init(
        id: String,
        remindAt: Date?,
        message: ChatMessage,
        channel: ChatChannel,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.remindAt = remindAt
        self.message = message
        self.channel = channel
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension MessageReminder: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
