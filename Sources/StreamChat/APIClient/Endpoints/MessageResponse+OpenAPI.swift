//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct MessageListPayload: Decodable {
    let messages: [MessageResponse]
}

extension MessageResponse {
    /// The message translations, wrapped for convenient access.
    var translations: MessageTranslations? {
        i18n.map { MessageTranslations(i18n: $0) }
    }
}

extension MessageWithChannelResponse {
    var asMessageResponse: MessageResponse {
        MessageResponse(
            attachments: attachments,
            cid: cid,
            command: command,
            createdAt: createdAt,
            custom: custom,
            deletedAt: deletedAt,
            deletedForMe: deletedForMe,
            deletedReplyCount: deletedReplyCount,
            draft: draft,
            html: html,
            i18n: i18n,
            id: id,
            imageLabels: imageLabels,
            latestReactions: latestReactions,
            member: member,
            mentionedChannel: mentionedChannel,
            mentionedGroupIds: mentionedGroupIds,
            mentionedHere: mentionedHere,
            mentionedRoles: mentionedRoles,
            mentionedUsers: mentionedUsers,
            messageTextUpdatedAt: messageTextUpdatedAt,
            mml: mml,
            moderation: moderation,
            ownReactions: ownReactions,
            parentId: parentId,
            pinExpires: pinExpires,
            pinned: pinned,
            pinnedAt: pinnedAt,
            pinnedBy: pinnedBy,
            poll: poll,
            pollId: pollId,
            quotedMessage: quotedMessage,
            quotedMessageId: quotedMessageId,
            reactionCounts: reactionCounts,
            reactionGroups: reactionGroups,
            reactionScores: reactionScores,
            reminder: reminder,
            replyCount: replyCount,
            restrictedVisibility: restrictedVisibility,
            shadowed: shadowed,
            sharedLocation: sharedLocation,
            showInChannel: showInChannel,
            silent: silent,
            text: text,
            threadParticipants: threadParticipants,
            type: type,
            updatedAt: updatedAt,
            user: user
        )
    }
}

extension SearchResultMessage {
    var asMessageResponse: MessageResponse {
        MessageResponse(
            attachments: attachments,
            cid: cid,
            command: command,
            createdAt: createdAt,
            custom: custom,
            deletedAt: deletedAt,
            deletedForMe: deletedForMe,
            deletedReplyCount: deletedReplyCount,
            draft: draft,
            html: html,
            i18n: i18n,
            id: id,
            imageLabels: imageLabels,
            latestReactions: latestReactions,
            member: member,
            mentionedChannel: mentionedChannel,
            mentionedGroupIds: mentionedGroupIds,
            mentionedHere: mentionedHere,
            mentionedRoles: mentionedRoles,
            mentionedUsers: mentionedUsers,
            messageTextUpdatedAt: messageTextUpdatedAt,
            mml: mml,
            moderation: moderation,
            ownReactions: ownReactions,
            parentId: parentId,
            pinExpires: pinExpires,
            pinned: pinned,
            pinnedAt: pinnedAt,
            pinnedBy: pinnedBy,
            poll: poll,
            pollId: pollId,
            quotedMessage: quotedMessage,
            quotedMessageId: quotedMessageId,
            reactionCounts: reactionCounts,
            reactionGroups: reactionGroups,
            reactionScores: reactionScores,
            reminder: reminder,
            replyCount: replyCount,
            restrictedVisibility: restrictedVisibility,
            shadowed: shadowed,
            sharedLocation: sharedLocation,
            showInChannel: showInChannel,
            silent: silent,
            text: text,
            threadParticipants: threadParticipants,
            type: type,
            updatedAt: updatedAt,
            user: user
        )
    }
}
