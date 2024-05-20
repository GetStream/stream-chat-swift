//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension ThreadPayload {
    /// Returns dummy thread payload with the given values.
    static func dummy(
        parentMessageId: MessageId,
        parentMessage: MessagePayload? = nil,
        channel: ChannelDetailPayload = .dummy(),
        createdBy: UserPayload = .dummy(userId: .newUniqueId),
        replyCount: Int = 0,
        participantCount: Int = 0,
        threadParticipants: [ThreadParticipantPayload] = [],
        lastMessageAt: Date? = nil,
        createdAt: Date = .unique,
        updatedAt: Date? = .unique,
        title: String? = nil,
        latestReplies: [MessagePayload] = [],
        read: [ThreadReadPayload] = []
    ) -> Self {
        .init(
            parentMessageId: parentMessageId,
            parentMessage: .dummy(messageId: parentMessageId),
            channel: channel,
            createdBy: createdBy,
            replyCount: replyCount,
            participantCount: participantCount,
            threadParticipants: threadParticipants,
            lastMessageAt: lastMessageAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            title: title,
            latestReplies: latestReplies,
            read: read
        )
    }
}
