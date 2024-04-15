//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a thread.
internal struct ChatThread {
    /// The id of the message which created the thread. It is also the id of the thread.
    internal let parentMessageId: MessageId
    /// The parent message which is the root of this thread.
    internal let parentMessage: ChatMessage
    /// The channel which this thread belongs to.
    internal let channel: ChatChannel
    /// The user who created the thread.
    internal let createdBy: ChatUser
    /// The number of replies in the thread.
    internal let replyCount: Int
    /// The number of participants in the thread.
    internal let participantCount: Int
    /// The participants in the thread.
    internal let threadParticipants: [ThreadParticipant]
    /// The date of the last (newest) message in the thread.
    internal let lastMessageAt: Date?
    /// The date when the thread was created.
    internal let createdAt: Date
    /// The last date when the thread was updated.
    internal let updatedAt: Date?
    /// The title of the thread.
    internal let title: String
    /// The latest replies of the thread.
    internal let latestReplies: [ChatMessage]
    /// The reads information of the thread.
    internal let reads: [ThreadRead]
}
