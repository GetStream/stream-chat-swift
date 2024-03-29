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
        mentionedUsers: [UserObject] = [.dummy(userId: .unique)],
        messageTextUpdatedAt: Date? = nil,
        command: String? = nil
    ) -> Message {
        .init(
            cid: (cid ?? ChannelId.unique).rawValue,
            createdAt: createdAt ?? .unique,
            deletedReplyCount: 0,
            html: "",
            id: messageId,
            pinned: pinned,
            replyCount: 0,
            shadowed: isShadowed,
            silent: isSilent,
            text: text,
            type: type?.rawValue ?? "regular",
            updatedAt: updatedAt,
            attachments: attachments,
            latestReactions: latestReactions,
            mentionedUsers: mentionedUsers,
            ownReactions: ownReactions,
            custom: extraData,
            reactionCounts: reactionCounts,
            reactionScores: reactionScores,
            command: command,
            deletedAt: deletedAt,
            parentId: parentId,
            pinExpires: pinExpires,
            pinnedAt: pinnedAt,
            quotedMessageId: quotedMessageId,
            showInChannel: showReplyInChannel,
            threadParticipants: threadParticipants,
            i18n: translations?.mapKeys(\.languageCode),
            pinnedBy: pinnedByUserId != nil ? .dummy(userId: pinnedByUserId!) : nil,
            quotedMessage: quotedMessage,
            user: .dummy(userId: authorUserId)
        )
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

extension MessageResponse {
    /// Creates a dummy `MessagePayload` with the given `messageId` and `userId` of the author.
    static func dummy(
        type: MessageType? = nil,
        messageId: MessageId = .unique,
        parentId: MessageId? = nil,
        showReplyInChannel: Bool = false,
        quotedMessageId: MessageId? = nil,
        quotedMessage: Message? = nil,
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
        mentionedUsers: [UserResponse] = [.dummy(userId: .unique)],
        messageTextUpdatedAt: Date? = nil,
        command: String? = nil
    ) -> MessageResponse {
        .init(
            cid: (cid ?? ChannelId.unique).rawValue,
            createdAt: createdAt ?? .unique,
            deletedReplyCount: 0,
            html: "",
            id: messageId,
            pinned: pinned,
            replyCount: 0,
            shadowed: isShadowed,
            silent: isSilent,
            text: text,
            type: type?.rawValue ?? "regular",
            updatedAt: updatedAt,
            attachments: attachments,
            latestReactions: latestReactions,
            mentionedUsers: mentionedUsers,
            ownReactions: ownReactions,
            custom: extraData,
            reactionCounts: reactionCounts,
            reactionScores: reactionScores,
            user: .dummy(userId: authorUserId),
            command: command,
            deletedAt: deletedAt,
            parentId: parentId,
            pinExpires: pinExpires,
            pinnedAt: pinnedAt,
            quotedMessageId: quotedMessageId,
            showInChannel: showReplyInChannel,
            threadParticipants: threadParticipants,
            i18n: translations?.mapKeys(\.languageCode),
            pinnedBy: pinnedByUserId != nil ? .dummy(userId: pinnedByUserId!) : nil,
            quotedMessage: quotedMessage
        )
    }

    static func multipleDummies(amount: Int) -> [Message] {
        var messages: [Message] = []
        for messageIndex in stride(from: 0, to: amount, by: 1) {
            messages.append(Message.dummy(messageId: "\(messageIndex)", authorUserId: .unique, createdAt: .unique))
        }
        return messages
    }
}

extension MessageWithChannelResponse {
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
        channel: ChannelResponse,
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
        mentionedUsers: [UserObject] = [.dummy(userId: .unique)],
        messageTextUpdatedAt: Date? = nil,
        command: String? = nil
    ) -> MessageWithChannelResponse {
        .init(
            cid: (cid ?? ChannelId.unique).rawValue,
            createdAt: createdAt ?? .unique,
            deletedReplyCount: 0,
            html: "",
            id: messageId,
            pinned: pinned,
            replyCount: 0,
            shadowed: isShadowed,
            silent: isSilent,
            text: text,
            type: type?.rawValue ?? "regular",
            updatedAt: updatedAt,
            attachments: attachments,
            latestReactions: latestReactions,
            mentionedUsers: [],//mentionedUsers,
            ownReactions: ownReactions, 
            channel: channel,
            custom: extraData,
            reactionCounts: reactionCounts,
            reactionScores: reactionScores,
            user: .dummy(userId: authorUserId),
            command: command,
            deletedAt: deletedAt,
            parentId: parentId,
            pinExpires: pinExpires,
            pinnedAt: pinnedAt,
            quotedMessageId: quotedMessageId,
            showInChannel: showReplyInChannel,
            threadParticipants: [],//threadParticipants, TODO: fix
            i18n: translations?.mapKeys(\.languageCode),
            pinnedBy: nil,//pinnedByUserId != nil ? .dummy(userId: pinnedByUserId!) : nil,
            quotedMessage: quotedMessage
        )
    }

    static func multipleDummies(amount: Int) -> [Message] {
        var messages: [Message] = []
        for messageIndex in stride(from: 0, to: amount, by: 1) {
            messages.append(Message.dummy(messageId: "\(messageIndex)", authorUserId: .unique, createdAt: .unique))
        }
        return messages
    }

}
