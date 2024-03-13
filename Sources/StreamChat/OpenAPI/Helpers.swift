//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct EmptyResponse: Decodable {}

extension ChannelStateResponse {
    var toResponseFields: ChannelStateResponseFields {
        ChannelStateResponseFields(
            members: members,
            messages: messages,
            pinnedMessages: pinnedMessages,
            threads: threads,
            hidden: hidden,
            hideMessagesBefore: hideMessagesBefore,
            watcherCount: watcherCount,
            pendingMessages: pendingMessages,
            read: read,
            watchers: watchers,
            channel: channel,
            membership: membership
        )
    }
}

extension SearchResultMessage {
    var toMessage: Message {
        Message(
            cid: cid,
            createdAt: createdAt,
            deletedReplyCount: deletedReplyCount,
            html: html,
            id: id,
            pinned: pinned,
            replyCount: replyCount,
            shadowed: shadowed,
            silent: silent,
            text: text,
            type: type,
            updatedAt: updatedAt,
            attachments: attachments,
            latestReactions: latestReactions,
            mentionedUsers: mentionedUsers,
            ownReactions: ownReactions,
            custom: custom,
            reactionCounts: reactionCounts,
            reactionScores: reactionScores,
            beforeMessageSendFailed: beforeMessageSendFailed,
            command: command,
            deletedAt: deletedAt,
            mml: mml,
            parentId: parentId,
            pinExpires: pinExpires,
            pinnedAt: pinnedAt,
            quotedMessageId: quotedMessageId,
            showInChannel: showInChannel,
            threadParticipants: threadParticipants,
            i18n: i18n,
            imageLabels: imageLabels,
            pinnedBy: pinnedBy,
            quotedMessage: quotedMessage,
            user: user
        )
    }
}

extension UserResponse {
    var toUser: UserObject {
        UserObject(
            id: id,
            banExpires: nil,
            banned: banned,
            createdAt: createdAt,
            deactivatedAt: nil,
            deletedAt: deletedAt,
            invisible: false,
            language: language,
            lastActive: nil,
            online: online,
            revokeTokensIssuedBefore: nil,
            role: nil,
            updatedAt: updatedAt,
            teams: nil,
            custom: custom,
            pushNotifications: nil
        )
    }
}

extension MessageResponse {
    var toMessage: Message {
        Message(
            cid: cid,
            createdAt: createdAt,
            deletedReplyCount: deletedReplyCount,
            html: html,
            id: id,
            pinned: pinned,
            replyCount: replyCount,
            shadowed: shadowed,
            silent: silent,
            text: text,
            type: type,
            updatedAt: updatedAt,
            attachments: attachments,
            latestReactions: latestReactions,
            mentionedUsers: mentionedUsers.map(\.toUser),
            ownReactions: ownReactions,
            custom: custom ?? [:],
            reactionCounts: reactionCounts,
            reactionScores: reactionScores,
            command: command,
            deletedAt: deletedAt,
            mml: mml,
            parentId: parentId,
            pinExpires: pinExpires,
            pinnedAt: pinnedAt,
            quotedMessageId: quotedMessageId,
            showInChannel: showInChannel,
            threadParticipants: threadParticipants?.compactMap { $0 }.map(\.toUser),
            i18n: i18n,
            imageLabels: imageLabels,
            pinnedBy: pinnedBy?.toUser,
            quotedMessage: quotedMessage,
            user: user.toUser
        )
    }
}

extension MessageWithChannelResponse {
    var toMessage: Message {
        Message(
            cid: cid,
            createdAt: createdAt,
            deletedReplyCount: deletedReplyCount,
            html: html,
            id: id,
            pinned: pinned,
            replyCount: replyCount,
            shadowed: shadowed,
            silent: silent,
            text: text,
            type: type,
            updatedAt: updatedAt,
            attachments: attachments,
            latestReactions: latestReactions,
            mentionedUsers: mentionedUsers.map(\.toUser),
            ownReactions: ownReactions,
            custom: custom,
            reactionCounts: reactionCounts,
            reactionScores: reactionScores,
            command: command,
            deletedAt: deletedAt,
            mml: mml,
            parentId: parentId,
            pinExpires: pinExpires,
            pinnedAt: pinnedAt,
            quotedMessageId: quotedMessageId,
            showInChannel: showInChannel,
            threadParticipants: threadParticipants?.compactMap { $0 }.map(\.toUser),
            i18n: i18n,
            imageLabels: imageLabels,
            pinnedBy: pinnedBy?.toUser,
            quotedMessage: quotedMessage,
            user: user.toUser
        )
    }
}

extension QueryUserResult {
    var toUser: UserObject {
        UserObject(
            id: id,
            banExpires: nil,
            banned: banned,
            createdAt: createdAt,
            deactivatedAt: nil,
            deletedAt: deletedAt,
            invisible: false,
            language: language,
            lastActive: nil,
            online: online,
            revokeTokensIssuedBefore: revokeTokensIssuedBefore,
            role: nil,
            updatedAt: updatedAt,
            teams: nil,
            custom: custom,
            pushNotifications: nil
        )
    }
}

public extension UserObject {
    var toChatUser: ChatUser {
        ChatUser(
            id: id,
            name: custom?["name"]?.stringValue,
            imageURL: URL(string: custom?["image"]?.stringValue ?? ""),
            isOnline: online ?? false,
            isBanned: banned ?? false,
            isFlaggedByCurrentUser: false, // TODO: how we handle this.
            userRole: UserRole(rawValue: role ?? "user"),
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActive,
            teams: Set(teams ?? []),
            language: TranslationLanguage(languageCode: language ?? "en"),
            extraData: custom ?? [:]
        )
    }
}

extension ChannelConfig {
    static let `default` = ChannelConfig(
        automod: "",
        automodBehavior: "",
        connectEvents: false,
        createdAt: Date(),
        customEvents: false,
        markMessagesPending: false,
        maxMessageLength: 0,
        messageRetention: "",
        mutes: false,
        name: "",
        pushNotifications: false,
        quotes: false,
        reactions: false,
        readEvents: false,
        reminders: false,
        replies: false,
        search: false,
        typingEvents: false,
        updatedAt: Date(),
        uploads: false,
        urlEnrichment: false,
        commands: []
    )
}
