//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
        threadParticipants: [ThreadParticipant]? = nil,
        lastMessageAt: Date? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        title: String? = nil,
        latestReplies: [ChatMessage]? = nil,
        reads: [ThreadRead]? = nil,
        extraData: [String: RawJSON]? = nil
    ) -> ChatThread {
        .mock(
            parentMessage: parentMessage ?? self.parentMessage,
            channel: channel ?? self.channel,
            createdBy: createdBy ?? self.createdBy,
            replyCount: replyCount ?? self.replyCount,
            participantCount: participantCount ?? self.replyCount,
            threadParticipants: threadParticipants ?? self.threadParticipants,
            lastMessageAt: lastMessageAt ?? self.lastMessageAt,
            createdAt: createdAt ?? self.createdAt,
            updatedAt: updatedAt ?? self.updatedAt,
            title: title ?? self.title,
            latestReplies: latestReplies ?? self.latestReplies,
            reads: reads ?? self.reads,
            extraData: extraData ?? self.extraData
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
