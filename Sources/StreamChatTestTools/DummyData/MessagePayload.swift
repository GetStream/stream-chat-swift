//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension MessagePayload {
    /// Creates a dummy `MessagePayload` with the given `messageId` and `userId` of the author.
    static func dummy<T: ExtraDataTypes>(
        type: MessageType? = nil,
        messageId: MessageId,
        parentId: MessageId? = nil,
        showReplyInChannel: Bool = false,
        quotedMessageId: MessageId? = nil,
        quotedMessage: MessagePayload<T>? = nil,
        attachments: [MessageAttachmentPayload] = [
            .dummy(),
            .dummy(),
            .dummy()
        ],
        authorUserId: UserId,
        text: String = .unique,
        extraData: T.Message = .defaultValue,
        latestReactions: [MessageReactionPayload<T>] = [],
        ownReactions: [MessageReactionPayload<T>] = [],
        createdAt: Date? = nil,
        deletedAt: Date? = nil,
        updatedAt: Date = .unique,
        channel: ChannelDetailPayload<T>? = nil,
        pinned: Bool = false,
        pinnedByUserId: UserId? = nil,
        pinnedAt: Date? = nil,
        pinExpires: Date? = nil
    ) -> MessagePayload<T> where T.User == NoExtraData {
        .init(
            id: messageId,
            type: type ?? (parentId == nil ? .regular : .reply),
            user: UserPayload.dummy(userId: authorUserId) as UserPayload<T.User>,
            createdAt: createdAt != nil ? createdAt! : XCTestCase.channelCreatedDate
                .addingTimeInterval(TimeInterval.random(in: 100...900)),
            updatedAt: updatedAt,
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
            channel: channel,
            pinned: pinned,
            pinnedBy: pinnedByUserId != nil ? UserPayload.dummy(userId: pinnedByUserId!) as UserPayload<T.User> : nil,
            pinnedAt: pinnedAt,
            pinExpires: pinExpires
        )
    }
}

extension MessagePayload {
    func attachmentIDs(cid: ChannelId) -> [AttachmentId] {
        attachments.enumerated().map { .init(cid: cid, messageId: id, index: $0.offset) }
    }
}
