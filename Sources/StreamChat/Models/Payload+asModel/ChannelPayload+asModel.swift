//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension ChannelPayload {
    /// Converts the ChannelPayload to a ChatChannel model
    /// - Returns: A ChatChannel instance
    func asModel(
        currentUserId: UserId?,
        currentlyTypingUsers: Set<ChatUser>?,
        unreadCount: ChannelUnreadCount?
    ) -> ChatChannel {
        let channelPayload = channel

        // Map members
        let mappedMembers = members.compactMap { $0.asModel(channelId: channelPayload.cid) }

        // Map latest messages
        let reads = channelReads.map { $0.asModel() }
        let latestMessages = messages.compactMap {
            $0.asModel(cid: channel.cid, currentUserId: currentUserId, channelReads: reads)
        }

        // Map reads
        let mappedReads = channelReads.map { $0.asModel() }

        // Map watchers
        let mappedWatchers = watchers?.map { $0.asModel() } ?? []

        return ChatChannel(
            cid: channelPayload.cid,
            name: channelPayload.name,
            imageURL: channelPayload.imageURL,
            lastMessageAt: channelPayload.lastMessageAt,
            createdAt: channelPayload.createdAt,
            updatedAt: channelPayload.updatedAt,
            deletedAt: channelPayload.deletedAt,
            truncatedAt: channelPayload.truncatedAt,
            isHidden: isHidden ?? false,
            createdBy: channelPayload.createdBy?.asModel(),
            config: channelPayload.config,
            ownCapabilities: Set(channelPayload.ownCapabilities?.compactMap { ChannelCapability(rawValue: $0) } ?? []),
            isFrozen: channelPayload.isFrozen,
            isDisabled: channelPayload.isDisabled,
            isBlocked: channelPayload.isBlocked ?? false,
            lastActiveMembers: Array(mappedMembers),
            membership: membership?.asModel(channelId: channelPayload.cid),
            currentlyTypingUsers: currentlyTypingUsers ?? [],
            lastActiveWatchers: Array(mappedWatchers),
            team: channelPayload.team,
            unreadCount: unreadCount ?? .noUnread,
            watcherCount: watcherCount ?? 0,
            memberCount: channelPayload.memberCount,
            reads: mappedReads,
            cooldownDuration: channelPayload.cooldownDuration,
            extraData: channelPayload.extraData,
            latestMessages: latestMessages,
            lastMessageFromCurrentUser: latestMessages.first { $0.isSentByCurrentUser },
            pinnedMessages: pinnedMessages.compactMap {
                $0.asModel(cid: channelPayload.cid, currentUserId: currentUserId, channelReads: reads)
            },
            pendingMessages: (pendingMessages ?? []).compactMap {
                $0.asModel(cid: channelPayload.cid, currentUserId: currentUserId, channelReads: reads)
            },
            muteDetails: nil,
            previewMessage: latestMessages.first,
            draftMessage: nil,
            activeLiveLocations: []
        )
    }
}

extension ChannelDetailPayload {
    func asModel() -> ChatChannel {
        ChatChannel(
            cid: cid,
            name: name,
            imageURL: imageURL,
            lastMessageAt: lastMessageAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            truncatedAt: truncatedAt,
            isHidden: false,
            createdBy: createdBy?.asModel(),
            config: config,
            ownCapabilities: Set(ownCapabilities?.compactMap { ChannelCapability(rawValue: $0) } ?? []),
            isFrozen: isFrozen,
            isDisabled: isDisabled,
            isBlocked: isBlocked ?? false,
            lastActiveMembers: members?.compactMap { $0.asModel(channelId: cid) } ?? [],
            membership: nil,
            currentlyTypingUsers: [],
            lastActiveWatchers: [],
            team: team,
            unreadCount: ChannelUnreadCount(messages: 0, mentions: 0),
            watcherCount: 0,
            memberCount: memberCount,
            reads: [],
            cooldownDuration: cooldownDuration,
            extraData: extraData,
            latestMessages: [],
            lastMessageFromCurrentUser: nil,
            pinnedMessages: [],
            pendingMessages: [],
            muteDetails: nil,
            previewMessage: nil,
            draftMessage: nil,
            activeLiveLocations: []
        )
    }
}

extension MemberPayload {
    /// Converts the MemberPayload to a ChatChannelMember model
    /// - Parameter channelId: The channel ID the member belongs to
    /// - Returns: A ChatChannelMember instance, or nil if user is missing
    func asModel(channelId: ChannelId) -> ChatChannelMember? {
        guard let userPayload = user else { return nil }
        let user = userPayload.asModel()

        return ChatChannelMember(
            id: user.id,
            name: user.name,
            imageURL: user.imageURL,
            isOnline: user.isOnline,
            isBanned: user.isBanned,
            isFlaggedByCurrentUser: user.isFlaggedByCurrentUser,
            userRole: user.userRole,
            teamsRole: user.teamsRole,
            userCreatedAt: user.userCreatedAt,
            userUpdatedAt: user.userUpdatedAt,
            deactivatedAt: user.userDeactivatedAt,
            lastActiveAt: user.lastActiveAt,
            teams: user.teams,
            language: user.language,
            extraData: user.extraData,
            memberRole: MemberRole(rawValue: role?.rawValue ?? "member"),
            memberCreatedAt: createdAt,
            memberUpdatedAt: updatedAt,
            isInvited: isInvited ?? false,
            inviteAcceptedAt: inviteAcceptedAt,
            inviteRejectedAt: inviteRejectedAt,
            archivedAt: archivedAt,
            pinnedAt: pinnedAt,
            isBannedFromChannel: isBanned ?? false,
            banExpiresAt: banExpiresAt,
            isShadowBannedFromChannel: isShadowBanned ?? false,
            notificationsMuted: notificationsMuted,
            avgResponseTime: user.avgResponseTime,
            memberExtraData: extraData ?? [:]
        )
    }
}

extension ChannelReadPayload {
    /// Converts the ChannelReadPayload to a ChatChannelRead model
    /// - Returns: A ChatChannelRead instance
    func asModel() -> ChatChannelRead {
        ChatChannelRead(
            lastReadAt: lastReadAt,
            lastReadMessageId: lastReadMessageId,
            unreadMessagesCount: unreadMessagesCount,
            user: user.asModel()
        )
    }
}
