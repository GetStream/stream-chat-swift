//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension ChatMessage {
    static var unique: ChatMessage {
        .init(
            id: .unique,
            cid: .unique,
            text: "",
            type: .regular,
            command: nil,
            createdAt: Date(),
            locallyCreatedAt: nil,
            updatedAt: Date(),
            deletedAt: nil,
            arguments: nil,
            parentMessageId: nil,
            showReplyInChannel: true,
            replyCount: 2,
            extraData: [:],
            quotedMessage: { nil },
            isBounced: false,
            isSilent: false,
            isShadowed: false,
            reactionScores: ["like": 1],
            reactionCounts: ["like": 1],
            author: { .mock(id: .unique) },
            mentionedUsers: { [] },
            threadParticipants: { [] },
            threadParticipantsCount: { 0 },
            attachments: { [] },
            latestReplies: { [] },
            localState: nil,
            isFlaggedByCurrentUser: false,
            latestReactions: { [] },
            currentUserReactions: { [] },
            currentUserReactionsCount: { 0 },
            isSentByCurrentUser: false,
            pinDetails: nil,
            translations: nil,
            originalLanguage: nil,
            moderationDetails: nil,
            readBy: { [] },
            readByCount: { 0 },
            underlyingContext: nil,
            textUpdatedAt: nil
        )
    }
}
