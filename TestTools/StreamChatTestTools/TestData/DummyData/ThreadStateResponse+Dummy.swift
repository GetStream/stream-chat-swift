//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension ThreadStateResponse {
    /// Returns dummy thread payload with the given values.
    static func dummy(
        parentMessageId: MessageId,
        parentMessage: MessageResponse? = nil,
        channel: ChannelResponse = .dummy(),
        createdBy: UserResponse = .dummy(userId: .newUniqueId),
        replyCount: Int = 0,
        participantCount: Int = 0,
        activeParticipantCount: Int = 0,
        threadParticipants: [ThreadParticipantOpenAPI] = [],
        lastMessageAt: Date? = nil,
        createdAt: Date = .unique,
        updatedAt: Date? = .unique,
        title: String? = nil,
        latestReplies: [MessageResponse] = [],
        read: [ReadStateResponse] = [],
        draft: DraftResponse? = nil,
        extraData: [String: RawJSON] = [:]
    ) -> Self {
        .init(
            parentMessageId: parentMessageId,
            parentMessage: .dummy(messageId: parentMessageId),
            channel: channel,
            createdBy: createdBy,
            replyCount: replyCount,
            participantCount: participantCount,
            activeParticipantCount: activeParticipantCount,
            threadParticipants: threadParticipants,
            lastMessageAt: lastMessageAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            title: title,
            latestReplies: latestReplies,
            read: read,
            draft: draft,
            extraData: extraData
        )
    }
}

extension ThreadResponse {
    static func dummy(
        parentMessageId: MessageId,
        parentMessage: MessageResponse? = nil,
        channel: ChannelResponse = .dummy(),
        createdBy: UserResponse = .dummy(userId: .newUniqueId),
        replyCount: Int = 0,
        participantCount: Int = 0,
        activeParticipantCount: Int = 0,
        lastMessageAt: Date? = nil,
        createdAt: Date = .unique,
        updatedAt: Date? = .unique,
        title: String? = nil,
        extraData: [String: RawJSON] = [:]
    ) -> ThreadResponse {
        .init(
            parentMessageId: parentMessageId,
            parentMessage: parentMessage ?? .dummy(messageId: parentMessageId),
            channel: channel,
            createdBy: createdBy,
            replyCount: replyCount,
            participantCount: participantCount,
            activeParticipantCount: activeParticipantCount,
            lastMessageAt: lastMessageAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            title: title,
            extraData: extraData
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
            cid: cid,
            parentMessageId: parentMessageId,
            replyCount: replyCount,
            participantCount: participantCount,
            activeParticipantCount: activeParticipantCount,
            lastMessageAt: lastMessageAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            title: title
        )
    }
}
