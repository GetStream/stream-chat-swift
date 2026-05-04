//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        let cid = (try? channelPayload.flatMap { try ChannelId(cid: $0.cid) }) ?? .init(type: .messaging, id: "")

        // Map members
        let mappedMembers = members.compactMap { $0.asModel(channelId: cid) }

        // Map latest messages
        let reads = channelReads.map { $0.asModel() }
        let latestMessages = messages.compactMap {
            $0.asModel(cid: cid, currentUserId: currentUserId, channelReads: reads)
        }

        // Map reads
        let mappedReads = channelReads.map { $0.asModel() }

        // Map watchers
        let mappedWatchers = watchers?.map { $0.asModel() } ?? []

        return ChatChannel(
            cid: cid,
            name: channelPayload?.name,
            imageURL: channelPayload?.imageURL,
            lastMessageAt: channelPayload?.lastMessageAt,
            createdAt: channelPayload?.createdAt ?? Date(),
            updatedAt: channelPayload?.updatedAt ?? Date(),
            deletedAt: channelPayload?.deletedAt,
            truncatedAt: channelPayload?.truncatedAt,
            isHidden: hidden ?? false,
            createdBy: channelPayload?.createdBy?.asModel(),
            config: channelPayload?.config?.asChannelConfig ?? .init(),
            filterTags: Set(channelPayload?.filterTags ?? []),
            ownCapabilities: Set(channelPayload?.ownCapabilities?.compactMap { ChannelCapability(rawValue: $0.rawValue) } ?? []),
            isFrozen: channelPayload?.isFrozen ?? false,
            isDisabled: channelPayload?.isDisabled ?? false,
            isBlocked: channelPayload?.isBlocked ?? false,
            lastActiveMembers: Array(mappedMembers),
            membership: membership?.asModel(channelId: cid),
            currentlyTypingUsers: currentlyTypingUsers ?? [],
            lastActiveWatchers: Array(mappedWatchers),
            team: channelPayload?.team,
            unreadCount: unreadCount ?? .noUnread,
            watcherCount: watcherCount ?? 0,
            memberCount: channelPayload?.memberCount ?? 0,
            messageCount: channelPayload?.messageCount,
            reads: mappedReads,
            cooldownDuration: channelPayload?.cooldownDuration ?? 0,
            extraData: channelPayload?.extraData ?? [:],
            latestMessages: latestMessages,
            lastMessageFromCurrentUser: latestMessages.first { $0.isSentByCurrentUser },
            pinnedMessages: pinnedMessages.compactMap {
                $0.asModel(cid: cid, currentUserId: currentUserId, channelReads: reads)
            },
            pendingMessages: (pendingMessages ?? []).compactMap {
                $0.message?.asModel(cid: cid, currentUserId: currentUserId, channelReads: reads)
            },
            muteDetails: nil,
            draftMessage: nil,
            activeLiveLocations: [],
            pushPreference: nil
        )
    }
}

extension MemberPayload {
    /// Converts the MemberPayload to a ChatChannelMember model
    /// - Parameter channelId: The channel ID the member belongs to
    /// - Returns: A ChatChannelMember instance, or nil if user is missing
    func asModel(channelId: ChannelId) -> ChatChannelMember? {
        guard let userPayload = userPayload else { return nil }
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
            memberRole: memberRole ?? .member,
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
            user: user.asUserPayload.asModel(),
            lastDeliveredAt: lastDeliveredAt,
            lastDeliveredMessageId: lastDeliveredMessageId
        )
    }
}
