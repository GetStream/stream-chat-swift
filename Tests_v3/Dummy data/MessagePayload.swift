//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatClient

extension MessagePayload {
    /// Creates a dummy `MessagePayload` with the given `messageId` and `userId` of the author.
    static func dummy<T: ExtraDataTypes>(
        messageId: MessageId,
        authorUserId: UserId,
        text: String = .unique,
        extraData: T.Message = .defaultValue
    ) -> MessagePayload<T> where T.User == NameAndImageExtraData {
        .init(
            id: messageId,
            type: .regular,
            user: UserPayload.dummy(userId: authorUserId) as UserPayload<T.User>,
            createdAt: .unique,
            updatedAt: .unique,
            deletedAt: .unique,
            text: text,
            command: .unique,
            args: .unique,
            parentId: .unique,
            showReplyInChannel: true,
            mentionedUsers: [UserPayload.dummy(userId: .unique)],
            replyCount: .random(in: 0...1000),
            extraData: extraData,
            reactionScores: ["like": 1],
            isSilent: true
        )
    }
}
