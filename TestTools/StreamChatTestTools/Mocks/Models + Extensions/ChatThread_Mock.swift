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
