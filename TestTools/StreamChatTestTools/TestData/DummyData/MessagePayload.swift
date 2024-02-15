//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension Message {
    /// Creates a dummy `MessagePayload` with the given `messageId` and `userId` of the author.
    static func dummy(
        type: MessageType? = nil,
        messageId: MessageId = .unique,
        parentId: MessageId? = nil,
        showReplyInChannel: Bool = false,
        quotedMessageId: MessageId? = nil,
        quotedMessage: Message? = nil,
        threadParticipants: [UserObject] = [
            UserObject.dummy(userId: .unique),
            UserObject.dummy(userId: .unique)
        ],
        attachments: [Attachment] = [
            .dummy(),
            .dummy(),
            .dummy()
        ],
        authorUserId: UserId = .unique,
        text: String = .unique,
        extraData: [String: RawJSON] = [:],
        latestReactions: [Reaction] = [],
        ownReactions: [Reaction] = [],
        createdAt: Date? = .unique,
        deletedAt: Date? = nil,
        updatedAt: Date = .unique,
        channel: ChannelResponse? = nil,
        cid: ChannelId? = nil,
        pinned: Bool = false,
        pinnedByUserId: UserId? = nil,
        pinnedAt: Date? = nil,
        pinExpires: Date? = nil,
        isSilent: Bool = false,
        isShadowed: Bool = false,
        reactionScores: [String: Int] = ["like": 1],
        reactionCounts: [String: Int] = ["like": 1],
        translations: [TranslationLanguage: String]? = nil,
        originalLanguage: String? = nil,
        moderationDetails: MessageModerationDetails? = nil,
        mentionedUsers: [UserObject] = [.dummy(userId: .unique)]
    ) -> Message {
        fatalError()
//        .init(
//            id: messageId,
//            cid: cid,
//            type: type ?? (parentId == nil ? .regular : showReplyInChannel == true ? .regular : .reply),
//            user: UserPayload.dummy(userId: authorUserId) as UserPayload,
//            createdAt: createdAt != nil ? createdAt! : XCTestCase.channelCreatedDate
//                .addingTimeInterval(TimeInterval.random(in: 100...900)),
//            updatedAt: updatedAt,
//            deletedAt: deletedAt,
//            text: text,
//            command: .unique,
//            args: .unique,
//            parentId: parentId,
//            showReplyInChannel: showReplyInChannel,
//            quotedMessageId: quotedMessageId,
//            quotedMessage: quotedMessage,
//            mentionedUsers: mentionedUsers,
//            threadParticipants: threadParticipants,
//            replyCount: .random(in: 0...1000),
//            extraData: extraData,
//            latestReactions: latestReactions,
//            ownReactions: ownReactions,
//            reactionScores: reactionScores,
//            reactionCounts: reactionCounts,
//            isSilent: isSilent,
//            isShadowed: isShadowed,
//            attachments: attachments,
//            channel: channel,
//            pinned: pinned,
//            pinnedBy: pinnedByUserId != nil ? UserPayload.dummy(userId: pinnedByUserId!) as UserPayload : nil,
//            pinnedAt: pinnedAt,
//            pinExpires: pinExpires,
//            translations: translations,
//            originalLanguage: originalLanguage,
//            moderationDetails: moderationDetails
//        )
    }

    static func multipleDummies(amount: Int) -> [Message] {
        var messages: [Message] = []
        for messageIndex in stride(from: 0, to: amount, by: 1) {
            messages.append(Message.dummy(messageId: "\(messageIndex)", authorUserId: .unique, createdAt: .unique))
        }
        return messages
    }
}

extension Message {
    func attachmentIDs(cid: ChannelId) -> [AttachmentId] {
        attachments.enumerated().map { .init(cid: cid, messageId: id, index: $0.offset) }
    }
}
