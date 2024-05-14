//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A query to fetch information about a thread.
/// To fetch all the replies from a thread and paginate the replies, the `ChatMessageController` should be used instead.
internal struct ThreadQuery: Encodable {
    private enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case watch
        case replyLimit = "reply_limit"
        case participantLimit = "participant_limit"
    }
    
    /// The parent message ID which the thread belongs to.
    internal var messageId: MessageId
    /// A boolean indicating whether to watch for changes in the thread or not.
    internal var watch: Bool = false
    /// The amount of replies fetched from the thread. Default is 2.
    internal var replyLimit: Int = 2
    /// The amount of participants fetched per thread. Default is 100.
    internal var participantLimit: Int = 100

    internal init(messageId: MessageId) {
        self.messageId = messageId
    }
}
