//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a thread.
public struct ChatThread {
    /// The id of the message which created the thread. It is also the id of the thread.
    public let parentMessageId: MessageId
    /// The parent message which is the root of this thread.
    public let parentMessage: ChatMessage
    /// The channel which this thread belongs to.
    public let channel: ChatChannel
    /// The user who created the thread.
    public let createdBy: ChatUser
    /// The number of replies in the thread.
    public let replyCount: Int
    /// The number of participants in the thread.
    public let participantCount: Int
    /// The participants in the thread.
    public let threadParticipants: [ThreadParticipant]
    /// The date of the last (newest) message in the thread.
    public let lastMessageAt: Date?
    /// The date when the thread was created.
    public let createdAt: Date
    /// The last date when the thread was updated.
    public let updatedAt: Date?
    /// The title of the thread.
    public let title: String?
    /// The latest replies of the thread.
    public let latestReplies: [ChatMessage]
    /// The reads information of the thread.
    public let reads: [ThreadRead]
    /// The custom data of the thread.
    public let extraData: [String: RawJSON]
}
