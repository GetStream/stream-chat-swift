//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension MessagePayload {
    /// Creates a dummy `MessagePayload` with the given `messageId` and `userId` of the author.
    static func dummy<T: ExtraDataTypes>(
        messageId: MessageId,
        parentId: MessageId? = nil,
        showReplyInChannel: Bool = false,
        attachments: [AttachmentPayload<T.Attachment>] = [],
        authorUserId: UserId,
        text: String = .unique,
        extraData: T.Message = .defaultValue,
        latestReactions: [MessageReactionPayload<T>] = [],
        ownReactions: [MessageReactionPayload<T>] = [],
        deletedAt: Date? = nil
    ) -> MessagePayload<T> where T.User == DefaultExtraData.User {
        .init(
            id: messageId,
            type: parentId == nil ? .regular : .reply,
            user: UserPayload.dummy(userId: authorUserId) as UserPayload<T.User>,
            createdAt: .unique,
            updatedAt: .unique,
            deletedAt: deletedAt,
            text: text,
            command: .unique,
            args: .unique,
            parentId: parentId,
            showReplyInChannel: showReplyInChannel,
            mentionedUsers: [UserPayload.dummy(userId: .unique)],
            replyCount: .random(in: 0...1000),
            extraData: extraData,
            latestReactions: latestReactions,
            ownReactions: ownReactions,
            reactionScores: ["like": 1],
            isSilent: true,
            attachments: attachments
        )
    }
}
