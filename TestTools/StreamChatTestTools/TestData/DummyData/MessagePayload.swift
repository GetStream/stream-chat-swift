//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension MessagePayload {
    /// Creates a dummy `MessagePayload` with the given `messageId` and `userId` of the author.
    static func dummy(
        type: MessageType? = nil,
        messageId: MessageId = .unique,
        parentId: MessageId? = nil,
        showReplyInChannel: Bool = false,
        quotedMessageId: MessageId? = nil,
        quotedMessage: MessagePayload? = nil,
        threadParticipants: [UserPayload] = [
            UserPayload.dummy(userId: .unique),
            UserPayload.dummy(userId: .unique)
        ],
        attachments: [MessageAttachmentPayload] = [
            .dummy(),
            .dummy(),
            .dummy()
        ],
        authorUserId: UserId = .unique,
        text: String = .unique,
        extraData: [String: RawJSON] = [:],
        latestReactions: [MessageReactionPayload] = [],
        ownReactions: [MessageReactionPayload] = [],
        createdAt: Date? = .unique,
        deletedAt: Date? = nil,
        updatedAt: Date = .unique,
        channel: ChannelDetailPayload? = nil,
        cid: ChannelId? = nil,
        pinned: Bool = false,
        pinnedByUserId: UserId? = nil,
        pinnedAt: Date? = nil,
        pinExpires: Date? = nil,
        isSilent: Bool = false,
        isShadowed: Bool = false,
        reactionScores: [MessageReactionType: Int] = ["like": 1],
        reactionCounts: [MessageReactionType: Int] = ["like": 1],
        reactionGroups: [MessageReactionType: MessageReactionGroupPayload] = [:],
        translations: [TranslationLanguage: String]? = nil,
        originalLanguage: String? = nil,
        moderationDetails: MessageModerationDetailsPayload? = nil,
        mentionedUsers: [UserPayload] = [.dummy(userId: .unique)],
        messageTextUpdatedAt: Date? = nil,
        poll: PollPayload? = nil
    ) -> MessagePayload {
        .init(
            id: messageId,
            cid: cid,
            type: type ?? (parentId == nil ? .regular : showReplyInChannel == true ? .regular : .reply),
            user: UserPayload.dummy(userId: authorUserId) as UserPayload,
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
            mentionedUsers: mentionedUsers,
            threadParticipants: threadParticipants,
            replyCount: .random(in: 0...1000),
            extraData: extraData,
            latestReactions: latestReactions,
            ownReactions: ownReactions,
            reactionScores: reactionScores,
            reactionCounts: reactionCounts,
            reactionGroups: reactionGroups,
            isSilent: isSilent,
            isShadowed: isShadowed,
            attachments: attachments,
            channel: channel,
            pinned: pinned,
            pinnedBy: pinnedByUserId != nil ? UserPayload.dummy(userId: pinnedByUserId!) as UserPayload : nil,
            pinnedAt: pinnedAt,
            pinExpires: pinExpires,
            translations: translations,
            originalLanguage: originalLanguage,
            moderationDetails: moderationDetails,
            messageTextUpdatedAt: messageTextUpdatedAt,
            poll: poll
        )
    }

    static func multipleDummies(amount: Int) -> [MessagePayload] {
        var messages: [MessagePayload] = []
        for messageIndex in stride(from: 0, to: amount, by: 1) {
            messages.append(MessagePayload.dummy(messageId: "\(messageIndex)", authorUserId: .unique, createdAt: .unique))
        }
        return messages
    }
}

extension MessagePayload {
    func attachmentIDs(cid: ChannelId) -> [AttachmentId] {
        attachments.enumerated().map { .init(cid: cid, messageId: id, index: $0.offset) }
    }
}
