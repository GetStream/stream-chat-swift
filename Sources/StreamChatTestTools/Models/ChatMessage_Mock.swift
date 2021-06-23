//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension _ChatMessage {
    /// Creates a new `_ChatMessage` object from the provided data.
    static func mock(
        id: MessageId,
        cid: ChannelId,
        text: String,
        type: MessageType = .reply,
        author: _ChatUser<ExtraData.User>,
        command: String? = nil,
        createdAt: Date = Date(timeIntervalSince1970: 113),
        locallyCreatedAt: Date? = nil,
        updatedAt: Date = Date(timeIntervalSince1970: 774),
        deletedAt: Date? = nil,
        arguments: String? = nil,
        parentMessageId: MessageId? = nil,
        quotedMessage: _ChatMessage<ExtraData>? = nil,
        showReplyInChannel: Bool = false,
        replyCount: Int = 0,
        extraData: ExtraData.Message = .defaultValue,
        isSilent: Bool = false,
        reactionScores: [MessageReactionType: Int] = [:],
        mentionedUsers: Set<_ChatUser<ExtraData.User>> = [],
        threadParticipants: Set<_ChatUser<ExtraData.User>> = [],
        attachments: [AnyChatMessageAttachment] = [],
        latestReplies: [_ChatMessage<ExtraData>] = [],
        localState: LocalMessageState? = nil,
        isFlaggedByCurrentUser: Bool = false,
        latestReactions: Set<_ChatMessageReaction<ExtraData>> = [],
        currentUserReactions: Set<_ChatMessageReaction<ExtraData>> = [],
        isSentByCurrentUser: Bool = false,
        pinDetails: _MessagePinDetails<ExtraData>? = nil,
        attachmentCounts: [AttachmentType: Int] = [:]
    ) -> Self {
        .init(
            id: id,
            cid: cid,
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
            quotedMessage: { quotedMessage },
            isSilent: isSilent,
            reactionScores: reactionScores,
            author: { author },
            mentionedUsers: { mentionedUsers },
            threadParticipants: { threadParticipants },
            attachments: { attachments },
            latestReplies: { latestReplies },
            localState: localState,
            isFlaggedByCurrentUser: isFlaggedByCurrentUser,
            latestReactions: { latestReactions },
            currentUserReactions: { currentUserReactions },
            isSentByCurrentUser: isSentByCurrentUser,
            pinDetails: pinDetails,
            attachmentCounts: { attachmentCounts },
            underlyingContext: nil
        )
    }
}
