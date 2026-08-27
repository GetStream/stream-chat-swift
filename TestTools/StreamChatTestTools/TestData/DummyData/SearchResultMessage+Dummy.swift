//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import StreamCore

extension SearchResultMessage {
    /// The search endpoint is the only one returning a message with an embedded channel, so this is
    /// deliberately minimal — just enough to exercise the search save path.
    static func dummy(
        messageId: MessageId = .unique,
        text: String = .unique,
        authorUserId: UserId = .unique,
        cid: ChannelId = .unique,
        channel: ChannelDetailPayload? = nil,
        createdAt: Date = .unique,
        updatedAt: Date = .unique,
        extraData: [String: RawJSON] = [:]
    ) -> SearchResultMessage {
        SearchResultMessage(
            attachments: [],
            channel: channel,
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: extraData,
            deletedReplyCount: 0,
            html: "",
            id: messageId,
            latestReactions: [],
            mentionedChannel: false,
            mentionedHere: false,
            mentionedUsers: [],
            ownReactions: [],
            pinned: false,
            reactionScores: [:],
            replyCount: 0,
            restrictedVisibility: [],
            shadowed: false,
            silent: false,
            text: text,
            type: MessageType.regular.rawValue,
            updatedAt: updatedAt,
            user: .dummy(userId: authorUserId)
        )
    }

    static func boxed(
        messageId: MessageId = .unique,
        text: String = .unique,
        cid: ChannelId = .unique,
        channel: ChannelDetailPayload? = nil,
        createdAt: Date = .unique
    ) -> SearchResultMessage.Boxed {
        SearchResultMessage.Boxed(
            message: .dummy(
                messageId: messageId,
                text: text,
                cid: cid,
                channel: channel,
                createdAt: createdAt
            )
        )
    }
}
