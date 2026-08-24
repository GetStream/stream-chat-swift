//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension ChatThread {
    static func mock(
        parentMessage: ChatMessage = .mock(),
        channel: ChatChannel = .mock(cid: .unique),
        createdBy: ChatUser = .mock(id: .unique),
        replyCount: Int = 3,
        participantCount: Int = 3,
        activeParticipantCount: Int = 2,
        threadParticipants: [ThreadParticipant] = [],
        lastMessageAt: Date? = .unique,
        createdAt: Date = .unique,
        updatedAt: Date? = .unique,
        title: String? = nil,
        latestReplies: [ChatMessage] = [],
        reads: [ThreadRead] = [],
        extraData: [String: RawJSON] = [:]
    ) -> ChatThread {
        .init(
            parentMessageId: parentMessage.id,
            parentMessage: parentMessage,
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
            reads: reads,
            extraData: extraData
        )
    }

    // Make a clone from existing thread and change it with the provided properties.
    func with(
        parentMessage: ChatMessage? = nil,
        channel: ChatChannel? = nil,
        createdBy: ChatUser? = nil,
        replyCount: Int? = nil,
        participantCount: Int? = nil,
        activeParticipantCount: Int? = nil,
        threadParticipants: [ThreadParticipant]? = nil,
        lastMessageAt: Date? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        title: String? = nil,
        latestReplies: [ChatMessage]? = nil,
        reads: [ThreadRead]? = nil,
        extraData: [String: RawJSON]? = nil
    ) -> ChatThread {
        let parentMsg = parentMessage ?? self.parentMessage
        let ch = channel ?? self.channel
        let creator = createdBy ?? self.createdBy
        let replies = replyCount ?? self.replyCount
        let participants = participantCount ?? self.participantCount
        let activeParticipants = activeParticipantCount ?? self.activeParticipantCount
        let threadParts = threadParticipants ?? self.threadParticipants
        let lastMsg = lastMessageAt ?? self.lastMessageAt
        let created = createdAt ?? self.createdAt
        let updated = updatedAt ?? self.updatedAt
        let threadTitle = title ?? self.title
        let latestMsgs = latestReplies ?? self.latestReplies
        let threadReads = reads ?? self.reads
        let extra = extraData ?? self.extraData

        return .mock(
            parentMessage: parentMsg,
            channel: ch,
            createdBy: creator,
            replyCount: replies,
            participantCount: participants,
            activeParticipantCount: activeParticipants,
            threadParticipants: threadParts,
            lastMessageAt: lastMsg,
            createdAt: created,
            updatedAt: updated,
            title: threadTitle,
            latestReplies: latestMsgs,
            reads: threadReads,
            extraData: extra
        )
    }
}

extension ThreadParticipant {
    static func mock(
        user: ChatUser = .mock(id: .unique),
        threadId: String = .unique,
        createdAt: Date = .unique,
        lastReadAt: Date? = .unique
    ) -> ThreadParticipant {
        .init(
            user: user,
            threadId: threadId,
            createdAt: createdAt,
            lastReadAt: lastReadAt
        )
    }
}

extension ThreadRead {
    static func mock(
        user: ChatUser = .unique,
        lastReadAt: Date? = .unique,
        unreadMessagesCount: Int = 0
    ) -> ThreadRead {
        .init(
            user: user,
            lastReadAt: lastReadAt,
            unreadMessagesCount: unreadMessagesCount
        )
    }
}
