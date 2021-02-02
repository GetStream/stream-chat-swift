//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension _ChatMessage {
    /// Creates a new `_ChatMessage` object from the provided data.
    static func mock(
        id: MessageId,
        text: String,
        type: MessageType = .reply,
        author: _ChatUser<ExtraData.User>,
        command: String? = nil,
        createdAt: Date = .init(),
        locallyCreatedAt: Date? = nil,
        updatedAt: Date = .init(),
        deletedAt: Date? = nil,
        arguments: String? = nil,
        parentMessageId: MessageId? = nil,
        quotedMessageId: MessageId? = nil,
        showReplyInChannel: Bool = false,
        replyCount: Int = 0,
        extraData: ExtraData.Message = .defaultValue,
        isSilent: Bool = false,
        reactionScores: [MessageReactionType: Int] = [:],
        mentionedUsers: Set<_ChatUser<ExtraData.User>> = [],
        threadParticipants: Set<UserId> = [],
        attachments: [_ChatMessageAttachment<ExtraData>] = [],
        latestReplies: [_ChatMessage<ExtraData>] = [],
        localState: LocalMessageState? = nil,
        isFlaggedByCurrentUser: Bool = false,
        latestReactions: Set<_ChatMessageReaction<ExtraData>> = [],
        currentUserReactions: Set<_ChatMessageReaction<ExtraData>> = [],
        isSentByCurrentUser: Bool = false
    ) -> Self {
        .init(
            id: id,
            text: text,
            type: type,
            command: command,
            createdAt: createdAt,
            locallyCreatedAt: locallyCreatedAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            arguments: arguments,
            parentMessageId: parentMessageId,
            showReplyInChannel: showReplyInChannel,
            replyCount: replyCount,
            extraData: extraData,
            quotedMessageId: quotedMessageId,
            isSilent: isSilent,
            reactionScores: reactionScores,
            author: author,
            mentionedUsers: mentionedUsers,
            threadParticipants: threadParticipants,
            attachments: attachments,
            latestReplies: latestReplies,
            localState: localState,
            isFlaggedByCurrentUser: isFlaggedByCurrentUser,
            latestReactions: latestReactions,
            currentUserReactions: currentUserReactions,
            isSentByCurrentUser: isSentByCurrentUser
        )
    }
}
