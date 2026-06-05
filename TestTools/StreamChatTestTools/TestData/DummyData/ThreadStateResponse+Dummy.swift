//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension GetThreadResponse {
    static func dummy(
        duration: String = "",
        thread: ThreadStateResponse = .dummy()
    ) -> GetThreadResponse {
        .init(duration: duration, thread: thread)
    }
}

extension ThreadStateResponse {
    /// Returns dummy thread payload with the given values.
    static func dummy(
        activeParticipantCount: Int = 0,
        channel: ChannelResponse = .dummy(),
        channelCid: String? = nil,
        createdAt: Date = .unique,
        createdBy: UserResponse = .dummy(userId: .newUniqueId),
        createdByUserId: String? = nil,
        custom: [String: RawJSON] = [:],
        deletedAt: Date? = nil,
        draft: DraftResponse? = nil,
        lastMessageAt: Date? = nil,
        latestReplies: [MessageResponse] = [],
        parentMessage: MessageResponse? = nil,
        parentMessageId: MessageId = .unique,
        participantCount: Int = 0,
        read: [ReadStateResponse] = [],
        replyCount: Int = 0,
        threadParticipants: [ThreadParticipantPayload] = [],
        title: String = "",
        updatedAt: Date = .unique
    ) -> Self {
        .init(
            activeParticipantCount: activeParticipantCount,
            channel: channel,
            channelCid: channelCid ?? channel.cid,
            createdAt: createdAt,
            createdBy: createdBy,
            createdByUserId: createdByUserId ?? createdBy.id,
            custom: custom,
            deletedAt: deletedAt,
            draft: draft,
            lastMessageAt: lastMessageAt,
            latestReplies: latestReplies,
            parentMessage: parentMessage,
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

extension ThreadResponse {
    static func dummy(
        activeParticipantCount: Int = 0,
        channel: ChannelResponse = .dummy(),
        channelCid: String? = nil,
        createdAt: Date = .unique,
        createdBy: UserResponse = .dummy(userId: .newUniqueId),
        createdByUserId: String? = nil,
        custom: [String: RawJSON] = [:],
        deletedAt: Date? = nil,
        lastMessageAt: Date? = nil,
        parentMessage: MessageResponse? = nil,
        parentMessageId: MessageId = .unique,
        participantCount: Int = 0,
        replyCount: Int = 0,
        threadParticipants: [ThreadParticipantPayload]? = nil,
        title: String = "",
        updatedAt: Date = .unique
    ) -> ThreadResponse {
        .init(
            activeParticipantCount: activeParticipantCount,
            channel: channel,
            channelCid: channelCid ?? channel.cid,
            createdAt: createdAt,
            createdBy: createdBy,
            createdByUserId: createdByUserId ?? createdBy.id,
            custom: custom,
            deletedAt: deletedAt,
            lastMessageAt: lastMessageAt,
            parentMessage: parentMessage,
            parentMessageId: parentMessageId,
            participantCount: participantCount,
            replyCount: replyCount,
            threadParticipants: threadParticipants,
            title: title,
            updatedAt: updatedAt
        )
    }
}

extension ThreadResponse {
    static func dummy(
        parentMessageId: MessageId,
        cid: ChannelId = .unique,
        replyCount: Int = 0,
        participantCount: Int = 0,
        activeParticipantCount: Int = 0,
        lastMessageAt: Date? = nil,
        createdAt: Date = .unique,
        updatedAt: Date = .unique,
        title: String? = nil
    ) -> ThreadResponse {
        .init(
            activeParticipantCount: activeParticipantCount,
            channel: nil,
            channelCid: cid.rawValue,
            createdAt: createdAt,
            createdBy: nil,
            createdByUserId: "",
            custom: [:],
            deletedAt: nil,
            lastMessageAt: lastMessageAt,
            parentMessage: nil,
            parentMessageId: parentMessageId,
            participantCount: participantCount,
            replyCount: replyCount,
            threadParticipants: nil,
            title: title ?? "",
            updatedAt: updatedAt
        )
    }
}
