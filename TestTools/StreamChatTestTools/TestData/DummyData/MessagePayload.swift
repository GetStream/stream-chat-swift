//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension MessagePayload {
    convenience init(
        id: String,
        cid: ChannelId? = nil,
        type: MessageType,
        user: UserPayload,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        text: String,
        command: String? = nil,
        args: String? = nil,
        parentId: String? = nil,
        showReplyInChannel: Bool,
        quotedMessageId: String? = nil,
        quotedMessage: MessagePayload? = nil,
        mentionedUsers: [UserPayload],
        mentionedHere: Bool = false,
        mentionedChannel: Bool = false,
        mentionedGroups: [UserGroup] = [],
        mentionedRoles: [String] = [],
        threadParticipants: [UserPayload] = [],
        replyCount: Int,
        restrictedVisibility: [UserId] = [],
        extraData: [String: RawJSON],
        latestReactions: [MessageReactionPayload] = [],
        ownReactions: [MessageReactionPayload] = [],
        reactionScores: [MessageReactionType: Int],
        reactionCounts: [MessageReactionType: Int],
        reactionGroups: [MessageReactionType: MessageReactionGroupPayload] = [:],
        isSilent: Bool,
        isShadowed: Bool,
        attachments: [MessageAttachmentPayload],
        channel: ChannelDetailPayload? = nil,
        pinned: Bool = false,
        pinnedBy: UserPayload? = nil,
        pinnedAt: Date? = nil,
        pinExpires: Date? = nil,
        translations: [TranslationLanguage: String]? = nil,
        originalLanguage: String? = nil,
        moderation: MessageModerationDetailsPayload? = nil,
        messageTextUpdatedAt: Date? = nil,
        poll: PollPayload? = nil,
        draft: DraftPayload? = nil,
        reminder: ReminderPayload? = nil,
        location: SharedLocation? = nil,
        member: MemberInfoPayload? = nil,
        deletedForMe: Bool? = nil,
        campaignId: String? = nil
    ) {
        var custom = extraData
        if let campaignId {
            custom["created_by_campaign_id"] = .string(campaignId)
        }
        var i18n = translations?.mapKeys { $0.languageCode + "_text" } ?? [:]
        if let originalLanguage {
            i18n["language"] = originalLanguage
        }
        self.init(
            attachments: attachments,
            channel: channel,
            cid: cid?.rawValue ?? "",
            command: command,
            createdAt: createdAt,
            custom: custom,
            deletedAt: deletedAt,
            deletedForMe: deletedForMe,
            deletedReplyCount: 0,
            draft: draft,
            html: "",
            i18n: i18n.isEmpty ? nil : i18n,
            id: id,
            latestReactions: latestReactions,
            member: member,
            mentionedChannel: mentionedChannel,
            mentionedGroups: mentionedGroups,
            mentionedHere: mentionedHere,
            mentionedRoles: mentionedRoles,
            mentionedUsers: mentionedUsers,
            messageTextUpdatedAt: messageTextUpdatedAt,
            moderation: moderation,
            ownReactions: ownReactions,
            parentId: parentId,
            pinExpires: pinExpires,
            pinned: pinned,
            pinnedAt: pinnedAt,
            pinnedBy: pinnedBy,
            poll: poll,
            quotedMessage: quotedMessage,
            quotedMessageId: quotedMessageId,
            reactionCounts: reactionCounts.mapKeys(\.rawValue),
            reactionGroups: reactionGroups.mapKeys(\.rawValue),
            reactionScores: reactionScores.mapKeys(\.rawValue),
            reminder: reminder,
            replyCount: replyCount,
            restrictedVisibility: restrictedVisibility,
            shadowed: isShadowed,
            sharedLocation: location,
            showInChannel: showReplyInChannel,
            silent: isSilent,
            text: text,
            threadParticipants: threadParticipants,
            type: type.rawValue,
            updatedAt: updatedAt,
            user: user
        )
    }

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
        mentionedUsers: [UserPayload] = [.dummy(userId: .unique)],
        mentionedHere: Bool = false,
        mentionedChannel: Bool = false,
        mentionedGroups: [UserGroup] = [],
        mentionedRoles: [String] = [],
        messageTextUpdatedAt: Date? = nil,
        poll: PollPayload? = nil,
        draft: DraftPayload? = nil,
        sharedLocation: SharedLocation? = nil,
        member: MemberInfoPayload? = nil,
        deletedForMe: Bool? = nil,
        campaignId: String? = nil
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
            mentionedHere: mentionedHere,
            mentionedChannel: mentionedChannel,
            mentionedGroups: mentionedGroups,
            mentionedRoles: mentionedRoles,
            threadParticipants: threadParticipants,
            replyCount: .random(in: 0...1000),
            restrictedVisibility: restrictedVisibility,
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
            messageTextUpdatedAt: messageTextUpdatedAt,
            poll: poll,
            draft: draft,
            location: sharedLocation,
            member: member,
            deletedForMe: deletedForMe,
            campaignId: campaignId
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
        blocklistsMatched: [String]? = nil,
        semanticFilterMatched: String? = nil,
        platformCircumvented: Bool? = nil
    ) -> Self {
        .init(
            action: action,
            blocklistsMatched: blocklistsMatched,
            imageHarms: imageHarms,
            originalText: originalText,
            platformCircumvented: platformCircumvented,
            semanticFilterMatched: semanticFilterMatched,
            textHarms: textHarms
        )
    }
}
