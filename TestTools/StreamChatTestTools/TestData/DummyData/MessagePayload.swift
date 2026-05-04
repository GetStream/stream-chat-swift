//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension MessagePayload {
    /// Creates a dummy `MessagePayload` (= `MessageResponse`) with the given `messageId` and `userId` of the author.
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
        restrictedVisibility: [UserId] = [],
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
        draft: DraftPayload? = nil,
        sharedLocation: SharedLocationPayload? = nil,
        member: ChannelMemberResponse? = nil,
        deletedForMe: Bool? = nil,
        campaignId: String? = nil
    ) -> MessagePayload {
        _ = moderationDetails
        var custom = extraData
        if let campaignId {
            custom[MessagePayloadsCodingKeys.campaignId.rawValue] = .string(campaignId)
        }
        let resolvedType = type ?? (parentId == nil ? .regular : showReplyInChannel == true ? .regular : .reply)
        return MessageResponse(
            attachments: attachments,
            cid: cid?.rawValue ?? channel?.cid ?? "",
            command: .unique,
            createdAt: createdAt ?? XCTestCase.channelCreatedDate.addingTimeInterval(TimeInterval.random(in: 100...900)),
            custom: custom,
            deletedAt: deletedAt,
            deletedForMe: deletedForMe,
            deletedReplyCount: 0,
            draft: draft,
            html: "",
            i18n: MessageTranslationsPayload.messageTranslations(translations: translations, originalLanguage: originalLanguage),
            id: messageId,
            latestReactions: latestReactions,
            member: member,
            mentionedChannel: false,
            mentionedHere: false,
            mentionedUsers: mentionedUsers,
            messageTextUpdatedAt: messageTextUpdatedAt,
            moderation: moderation ?? moderationDetails,
            ownReactions: ownReactions,
            parentId: parentId,
            pinExpires: pinExpires,
            pinned: pinned,
            pinnedAt: pinnedAt,
            pinnedBy: pinnedByUserId.map { UserPayload.dummy(userId: $0) },
            poll: poll,
            pollId: poll?.id,
            quotedMessage: quotedMessage,
            quotedMessageId: quotedMessageId,
            reactionCounts: reactionCounts.mapKeys(\.rawValue),
            reactionGroups: reactionGroups.mapKeys(\.rawValue),
            reactionScores: reactionScores.mapKeys(\.rawValue),
            replyCount: .random(in: 0...1000),
            restrictedVisibility: restrictedVisibility,
            shadowed: isShadowed,
            sharedLocation: sharedLocation,
            showInChannel: showReplyInChannel,
            silent: isSilent,
            text: text,
            threadParticipants: threadParticipants,
            type: resolvedType.rawValue,
            updatedAt: updatedAt,
            user: UserPayload.dummy(userId: authorUserId)
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
