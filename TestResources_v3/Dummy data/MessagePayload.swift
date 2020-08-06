//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatClient_v3

extension MessagePayload {
    /// Creates a dummy `MessagePayload` with the given `messageId` and `userId` of the author.
    static func dummy(messageId: MessageId, authorUserId: UserId) -> MessagePayload<DefaultDataTypes> {
        .init(id: messageId,
              type: .regular,
              user: UserPayload<NameAndImageExtraData>.dummy(userId: authorUserId),
              createdAt: .unique,
              updatedAt: .unique,
              deletedAt: nil,
              text: .unique,
              command: nil,
              args: nil,
              parentId: nil,
              showReplyInChannel: false,
              mentionedUsers: [],
              replyCount: 0,
              extraData: NoExtraData(),
              reactionScores: ["like": 1],
              isSilent: false)
    }
}
