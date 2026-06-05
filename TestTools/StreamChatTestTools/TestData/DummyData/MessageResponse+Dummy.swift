//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension MessageResponse {
    /// Creates a dummy `MessageResponse` (= `MessageResponse`) with the given `messageId` and `userId` of the author.
    static func dummy(
        type: MessageType? = nil,
        messageId: MessageId = .unique,
        parentId: MessageId? = nil,
        showReplyInChannel: Bool = false,
        quotedMessageId: MessageId? = nil,
        quotedMessage: MessageResponse? = nil,
        threadParticipants: [UserResponse] = [
            UserResponse.dummy(userId: .unique),
            UserResponse.dummy(userId: .unique)
        ],
        attachments: [Attachment] = [
            .dummy(),
            .dummy(),
            .dummy()
        ],
        authorUserId: UserId = .unique,
        text: String = .unique,
        restrictedVisibility: [UserId] = [],
        extraData: [String: RawJSON] = [:],
        latestReactions: [ReactionResponse] = [],
        ownReactions: [ReactionResponse] = [],
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
        reactionScores: [MessageReactionType: Int] = ["like": 1],
        reactionCounts: [MessageReactionType: Int] = ["like": 1],
        reactionGroups: [MessageReactionType: ReactionGroupResponse] = [:],
        translations: [TranslationLanguage: String]? = nil,
        originalLanguage: String? = nil,
        moderation: ModerationV2Response? = nil,
        moderationDetails: ModerationV2Response? = nil,
        mentionedUsers: [UserResponse] = [.dummy(userId: .unique)],
        messageTextUpdatedAt: Date? = nil,
        poll: PollResponseData? = nil,
        draft: DraftResponse? = nil,
        sharedLocation: SharedLocationResponseData? = nil,
        member: ChannelMemberResponse? = nil,
        deletedForMe: Bool? = nil,
        campaignId: String? = nil
    ) -> MessageResponse {
        _ = moderationDetails
        var custom = extraData
        if let campaignId {
            custom[MessageResponse.campaignIdCustomKey] = .string(campaignId)
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
            i18n: [String: String].messageTranslations(translations: translations, originalLanguage: originalLanguage),
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
            pinnedBy: pinnedByUserId.map { UserResponse.dummy(userId: $0) },
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
            user: UserResponse.dummy(userId: authorUserId)
        )
    }

    static func multipleDummies(amount: Int) -> [MessageResponse] {
        var messages: [MessageResponse] = []
        for messageIndex in stride(from: 0, to: amount, by: 1) {
            messages.append(MessageResponse.dummy(messageId: "\(messageIndex)", authorUserId: .unique, createdAt: .unique))
        }
        return messages
    }
}

extension MessageWithChannelResponse {
    static func dummy(
        message: MessageResponse = .dummy(),
        channel: ChannelResponse = .dummy()
    ) -> MessageWithChannelResponse {
        .init(
            attachments: message.attachments,
            channel: channel,
            cid: message.cid,
            command: message.command,
            createdAt: message.createdAt,
            custom: message.custom,
            deletedAt: message.deletedAt,
            deletedForMe: message.deletedForMe,
            deletedReplyCount: message.deletedReplyCount,
            draft: message.draft,
            html: message.html,
            i18n: message.i18n,
            id: message.id,
            imageLabels: message.imageLabels,
            latestReactions: message.latestReactions,
            member: message.member,
            mentionedChannel: message.mentionedChannel,
            mentionedGroupIds: message.mentionedGroupIds,
            mentionedHere: message.mentionedHere,
            mentionedRoles: message.mentionedRoles,
            mentionedUsers: message.mentionedUsers,
            messageTextUpdatedAt: message.messageTextUpdatedAt,
            mml: message.mml,
            moderation: message.moderation,
            ownReactions: message.ownReactions,
            parentId: message.parentId,
            pinExpires: message.pinExpires,
            pinned: message.pinned,
            pinnedAt: message.pinnedAt,
            pinnedBy: message.pinnedBy,
            poll: message.poll,
            pollId: message.pollId,
            quotedMessage: message.quotedMessage,
            quotedMessageId: message.quotedMessageId,
            reactionCounts: message.reactionCounts,
            reactionGroups: message.reactionGroups,
            reactionScores: message.reactionScores,
            reminder: message.reminder,
            replyCount: message.replyCount,
            restrictedVisibility: message.restrictedVisibility,
            shadowed: message.shadowed,
            sharedLocation: message.sharedLocation,
            showInChannel: message.showInChannel,
            silent: message.silent,
            text: message.text,
            threadParticipants: message.threadParticipants,
            type: message.type,
            updatedAt: message.updatedAt,
            user: message.user
        )
    }
}

extension SearchResultMessage {
    static func dummy(
        message: MessageResponse = .dummy(),
        channel: ChannelResponse? = nil
    ) -> SearchResultMessage {
        .init(
            attachments: message.attachments,
            channel: channel,
            cid: message.cid,
            command: message.command,
            createdAt: message.createdAt,
            custom: message.custom,
            deletedAt: message.deletedAt,
            deletedForMe: message.deletedForMe,
            deletedReplyCount: message.deletedReplyCount,
            draft: message.draft,
            html: message.html,
            i18n: message.i18n,
            id: message.id,
            imageLabels: message.imageLabels,
            latestReactions: message.latestReactions,
            member: message.member,
            mentionedChannel: message.mentionedChannel,
            mentionedGroupIds: message.mentionedGroupIds,
            mentionedHere: message.mentionedHere,
            mentionedRoles: message.mentionedRoles,
            mentionedUsers: message.mentionedUsers,
            messageTextUpdatedAt: message.messageTextUpdatedAt,
            mml: message.mml,
            moderation: message.moderation,
            ownReactions: message.ownReactions,
            parentId: message.parentId,
            pinExpires: message.pinExpires,
            pinned: message.pinned,
            pinnedAt: message.pinnedAt,
            pinnedBy: message.pinnedBy,
            poll: message.poll,
            pollId: message.pollId,
            quotedMessage: message.quotedMessage,
            quotedMessageId: message.quotedMessageId,
            reactionCounts: message.reactionCounts,
            reactionGroups: message.reactionGroups,
            reactionScores: message.reactionScores,
            reminder: message.reminder,
            replyCount: message.replyCount,
            restrictedVisibility: message.restrictedVisibility,
            shadowed: message.shadowed,
            sharedLocation: message.sharedLocation,
            showInChannel: message.showInChannel,
            silent: message.silent,
            text: message.text,
            threadParticipants: message.threadParticipants,
            type: message.type,
            updatedAt: message.updatedAt,
            user: message.user
        )
    }
}

extension GetRepliesResponse {
    static func dummy(
        duration: String = "",
        messages: [MessageResponse] = []
    ) -> GetRepliesResponse {
        .init(duration: duration, messages: messages)
    }
}

extension ReminderResponseData {
    static func dummy(
        channelCid: ChannelId = .unique,
        createdAt: Date = .unique,
        messageId: MessageId = .unique,
        remindAt: Date? = .unique,
        updatedAt: Date = .unique,
        userId: UserId = ""
    ) -> ReminderResponseData {
        .init(
            channelCid: channelCid.rawValue,
            createdAt: createdAt,
            messageId: messageId,
            remindAt: remindAt,
            updatedAt: updatedAt,
            userId: userId
        )
    }
}

extension UpdateReminderResponse {
    static func dummy(
        duration: String = "",
        reminder: ReminderResponseData = .dummy()
    ) -> UpdateReminderResponse {
        .init(duration: duration, reminder: reminder)
    }
}

extension QueryRemindersResponse {
    static func dummy(
        duration: String = "",
        next: String? = nil,
        reminders: [ReminderResponseData] = []
    ) -> QueryRemindersResponse {
        .init(duration: duration, next: next, reminders: reminders)
    }
}

extension ReactionGroupResponse {
    static func dummy(
        count: Int = 0,
        firstReactionAt: Date = .unique,
        lastReactionAt: Date = .unique,
        latestReactionsBy: [ReactionGroupUserResponse] = [],
        sumScores: Int = 0
    ) -> ReactionGroupResponse {
        .init(
            count: count,
            firstReactionAt: firstReactionAt,
            lastReactionAt: lastReactionAt,
            latestReactionsBy: latestReactionsBy,
            sumScores: sumScores
        )
    }
}

extension MessageResponse {
    func attachmentIDs(cid: ChannelId) -> [AttachmentId] {
        attachments.enumerated().map { .init(cid: cid, messageId: id, index: $0.offset) }
    }
}

extension ModerationV2Response {
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
            action: action,
            blocklistMatched: blocklistMatched,
            imageHarms: imageHarms,
            originalText: originalText,
            platformCircumvented: platformCircumvented,
            semanticFilterMatched: semanticFilterMatched,
            textHarms: textHarms
        )
    }
}
