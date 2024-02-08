//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct EmptyResponse: Decodable {}

extension StreamChatChannelStateResponse {
    var toResponseFields: StreamChatChannelStateResponseFields {
        StreamChatChannelStateResponseFields(
            members: members,
            messages: messages,
            pinnedMessages: pinnedMessages,
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

extension StreamChatSearchResultMessage {
    var toMessage: StreamChatMessage {
        StreamChatMessage(
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

extension StreamChatUserResponse {
    var toUser: StreamChatUserObject {
        StreamChatUserObject(
            id: id,
            banExpires: banExpires,
            banned: banned,
            createdAt: createdAt,
            deactivatedAt: deactivatedAt,
            deletedAt: deletedAt,
            invisible: invisible,
            language: language,
            lastActive: lastActive,
            online: online,
            revokeTokensIssuedBefore: revokeTokensIssuedBefore,
            role: role,
            updatedAt: updatedAt,
            teams: teams,
            custom: custom,
            pushNotifications: pushNotifications
        )
    }
}
