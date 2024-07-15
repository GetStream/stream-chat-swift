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
            quotedMessage: nil,
            isBounced: false,
            isSilent: false,
            isShadowed: false,
            reactionScores: ["like": 1],
            reactionCounts: ["like": 1],
            reactionGroups: [
                "like": .init(
                    type: "like",
                    sumScores: 1, count: 1,
                    firstReactionAt: .unique,
                    lastReactionAt: .unique
                )
            ],
            author: .mock(id: .unique),
            mentionedUsers: [],
            threadParticipants: [],
            attachments: [],
            latestReplies: [],
            localState: nil,
            isFlaggedByCurrentUser: false,
            latestReactions: [],
            currentUserReactions: [],
            isSentByCurrentUser: false,
            pinDetails: nil,
            translations: nil,
            originalLanguage: nil,
            moderationDetails: nil,
            readBy: [],
            poll: nil,
            textUpdatedAt: nil
        )
    }
}
