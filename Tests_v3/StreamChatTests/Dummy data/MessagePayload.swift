//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension MessagePayload {
    /// Creates a dummy `MessagePayload` with the given `messageId` and `userId` of the author.
    static func dummy<T: ExtraDataTypes>(
        type: MessageType? = nil,
        messageId: MessageId,
        parentId: MessageId? = nil,
        showReplyInChannel: Bool = false,
        quotedMessageId: MessageId? = nil,
        quotedMessage: MessagePayload<T>? = nil,
        attachments: [AttachmentPayload<T.Attachment>] = [
            .dummy(),
            .dummy(),
            .dummy()
        ],
        authorUserId: UserId,
        text: String = .unique,
        extraData: T.Message = .defaultValue,
        latestReactions: [MessageReactionPayload<T>] = [],
        ownReactions: [MessageReactionPayload<T>] = [],
        deletedAt: Date? = nil,
        channel: ChannelDetailPayload<T>? = nil
    ) -> MessagePayload<T> where T.User == NoExtraData.User {
        .init(
            id: messageId,
            type: type ?? (parentId == nil ? .regular : .reply),
            user: UserPayload.dummy(userId: authorUserId) as UserPayload<T.User>,
            createdAt: .unique,
            updatedAt: .unique,
            deletedAt: deletedAt,
            text: text,
            command: .unique,
            args: .unique,
            parentId: parentId,
            showReplyInChannel: showReplyInChannel,
            quotedMessageId: quotedMessageId,
            quotedMessage: quotedMessage,
            mentionedUsers: [UserPayload.dummy(userId: .unique)],
            replyCount: .random(in: 0...1000),
            extraData: extraData,
            latestReactions: latestReactions,
            ownReactions: ownReactions,
            reactionScores: ["like": 1],
            isSilent: true,
            attachments: attachments,
            channel: channel
        )
    }
}

extension MessagePayload {
    func attachmentIDs(cid: ChannelId) -> [AttachmentId] {
        attachments.enumerated().map { .init(cid: cid, messageId: id, index: $0.offset) }
    }

    func attachments(cid: ChannelId) -> [_ChatMessageAttachment<ExtraData>] {
        attachmentIDs(cid: cid).map { id in
            .init(
                id: id,
                localURL: nil,
                localState: nil,
                title: attachments[id.index].title,
                author: attachments[id.index].author,
                text: attachments[id.index].text,
                type: attachments[id.index].type,
                actions: attachments[id.index].actions,
                url: attachments[id.index].url,
                imageURL: attachments[id.index].imageURL,
                imagePreviewURL: attachments[id.index].imagePreviewURL,
                file: attachments[id.index].file,
                extraData: attachments[id.index].extraData
            )
        }
    }
}
