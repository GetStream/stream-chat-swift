//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension MessageWithChannelResponse {
    static func dummy(
        channel: ChannelDetailPayload? = nil,
        message: MessagePayload = .dummy()
    ) -> MessageWithChannelResponse {
        MessageWithChannelResponse(
            attachments: message.attachments,
            channel: channel ?? .dummy(cid: (try? ChannelId(cid: message.cid)) ?? .unique),
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
            mentionedChannelMembers: message.mentionedChannelMembers,
            mentionedGroupIds: message.mentionedGroupIds,
            mentionedGroups: message.mentionedGroups,
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
