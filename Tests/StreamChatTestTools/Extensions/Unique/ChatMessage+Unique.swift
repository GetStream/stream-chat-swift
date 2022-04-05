//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
            isSilent: false,
            isShadowed: false,
            reactionScores: ["like": 1],
            reactionCounts: ["like": 1],
            author: { .mock(id: .unique) },
            mentionedUsers: { [] },
            threadParticipants: { [] },
            attachments: { [] },
            latestReplies: { [] },
            localState: nil,
            isFlaggedByCurrentUser: false,
            latestReactions: { [] },
            currentUserReactions: { [] },
            isSentByCurrentUser: false,
            pinDetails: nil,
            translations: nil,
            underlyingContext: nil
        )
    }
}
