//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
        moderation: MessageModerationDetailsPayload? = nil,
        moderationDetails: MessageModerationDetailsPayload? = nil,
        mentionedUsers: [UserPayload] = [.dummy(userId: .unique)],
        messageTextUpdatedAt: Date? = nil,
        poll: PollPayload? = nil,
        draft: DraftPayload? = nil
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
            moderation: moderation,
            moderationDetails: moderationDetails,
            messageTextUpdatedAt: messageTextUpdatedAt,
            poll: poll,
            draft: draft
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

extension MessageModerationDetailsPayload {
    static func dummy(
        originalText: String,
        action: String,
        textHarms: [String]? = nil,
        imageHarms: [String]? = nil,
        blocklistMatched: String? = nil,
        semanticFilterMatched: String? = nil,
        platformCircumvented: Bool? = nil
    ) -> Self {
        .init(
            originalText: originalText,
            action: action,
            textHarms: textHarms,
            imageHarms: imageHarms,
            blocklistMatched: blocklistMatched,
            semanticFilterMatched: semanticFilterMatched,
            platformCircumvented: platformCircumvented
        )
    }
}
