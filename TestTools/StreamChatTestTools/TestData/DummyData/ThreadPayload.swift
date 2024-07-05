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
        read: [ThreadReadPayload] = [],
        extraData: [String: RawJSON] = [:]
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
            read: read,
            extraData: extraData
        )
    }
}

extension ThreadPartialPayload {
    static func dummy(
        parentMessageId: MessageId,
        parentMessage: MessagePayload? = nil,
        channel: ChannelDetailPayload = .dummy(),
        createdBy: UserPayload = .dummy(userId: .newUniqueId),
        replyCount: Int = 0,
        participantCount: Int = 0,
        lastMessageAt: Date? = nil,
        createdAt: Date = .unique,
        updatedAt: Date? = .unique,
        title: String? = nil,
        extraData: [String: RawJSON] = [:]
    ) -> ThreadPartialPayload {
        .init(
            parentMessageId: parentMessageId,
            parentMessage: parentMessage ?? .dummy(messageId: parentMessageId),
            channel: channel,
            createdBy: createdBy,
            replyCount: replyCount,
            participantCount: participantCount,
            lastMessageAt: lastMessageAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            title: title,
            extraData: extraData
        )
    }
}

extension ThreadDetailsPayload {
    static func dummy(
        parentMessageId: MessageId,
        cid: ChannelId = .unique,
        replyCount: Int = 0,
        participantCount: Int = 0,
        lastMessageAt: Date? = nil,
        createdAt: Date = .unique,
        updatedAt: Date = .unique,
        title: String? = nil
    ) -> ThreadDetailsPayload {
        .init(
            cid: cid,
            parentMessageId: parentMessageId,
            replyCount: replyCount,
            participantCount: participantCount,
            lastMessageAt: lastMessageAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            title: title
        )
    }
}
