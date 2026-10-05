//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

typealias ThreadListPayload = QueryThreadsResponse
typealias ThreadPartialPayload = ThreadResponse
typealias ThreadPartialUpdateRequest = UpdateThreadPartialRequest
typealias ThreadPartialUpdateResponse = UpdateThreadPartialResponse
typealias ThreadPayload = ThreadStateResponse
typealias ThreadPayloadResponse = GetThreadResponse
typealias ThreadReadPayload = ReadStateResponse

extension ThreadListPayload {
    convenience init(threads: [ThreadPayload], next: String?) {
        self.init(next: next, prev: nil, threads: threads)
    }
}

extension ThreadReadPayload {
    convenience init(user: UserPayload, lastReadAt: Date, unreadMessagesCount: Int) {
        self.init(lastRead: lastReadAt, unreadMessages: unreadMessagesCount, user: user)
    }
}

extension ThreadPayload {
    /// Returns dummy thread payload with the given values.
    static func dummy(
        parentMessageId: MessageId,
        parentMessage: MessagePayload? = nil,
        channel: ChannelDetailPayload = .dummy(),
        createdBy: UserPayload = .dummy(userId: .newUniqueId),
        replyCount: Int = 0,
        participantCount: Int = 0,
        activeParticipantCount: Int = 0,
        threadParticipants: [ThreadParticipantPayload] = [],
        lastMessageAt: Date? = nil,
        createdAt: Date = .unique,
        updatedAt: Date = .unique,
        title: String = "",
        latestReplies: [MessagePayload] = [],
        read: [ThreadReadPayload] = [],
        draft: DraftPayload? = nil,
        extraData: [String: RawJSON] = [:]
    ) -> Self {
        .init(
            activeParticipantCount: activeParticipantCount,
            channel: channel,
            channelCid: channel.cid.rawValue,
            createdAt: createdAt,
            createdBy: createdBy,
            createdByUserId: createdBy.id,
            custom: extraData,
            draft: draft,
            lastMessageAt: lastMessageAt,
            latestReplies: latestReplies,
            parentMessage: parentMessage ?? .dummy(messageId: parentMessageId, cid: channel.cid),
            parentMessageId: parentMessageId,
            participantCount: participantCount,
            read: read,
            replyCount: replyCount,
            threadParticipants: threadParticipants,
            title: title,
            updatedAt: updatedAt
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
        activeParticipantCount: Int = 0,
        lastMessageAt: Date? = nil,
        createdAt: Date = .unique,
        updatedAt: Date = .unique,
        title: String = "",
        extraData: [String: RawJSON] = [:]
    ) -> ThreadPartialPayload {
        .init(
            activeParticipantCount: activeParticipantCount,
            channel: channel,
            channelCid: channel.cid.rawValue,
            createdAt: createdAt,
            createdBy: createdBy,
            createdByUserId: createdBy.id,
            custom: extraData,
            lastMessageAt: lastMessageAt,
            parentMessage: parentMessage ?? .dummy(messageId: parentMessageId, cid: channel.cid),
            parentMessageId: parentMessageId,
            participantCount: participantCount,
            replyCount: replyCount,
            title: title,
            updatedAt: updatedAt
        )
    }
}
