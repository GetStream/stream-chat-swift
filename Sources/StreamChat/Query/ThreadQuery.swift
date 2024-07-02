//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A query to fetch information about a thread.
/// To fetch all the replies from a thread and paginate the replies, the `ChatMessageController` should be used instead.
public struct ThreadQuery: Encodable {
    private enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case watch
        case replyLimit = "reply_limit"
        case participantLimit = "participant_limit"
    }
    
    /// The parent message ID which the thread belongs to.
    public var messageId: MessageId
    /// A boolean indicating whether to watch for changes in the thread or not.
    public var watch: Bool
    /// The amount of replies fetched from the thread. Default is 3.
    public var replyLimit: Int
    /// The amount of participants fetched per thread. Default is 10.
    public var participantLimit: Int

    public init(
        messageId: MessageId,
        watch: Bool = false,
        replyLimit: Int = 3,
        participantLimit: Int = 10
    ) {
        self.messageId = messageId
        self.watch = watch
        self.replyLimit = replyLimit
        self.participantLimit = participantLimit
    }
}
