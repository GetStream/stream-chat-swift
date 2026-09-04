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
        typingUsers: Set<TypingUser>?,
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
            truncatedBy: channelPayload.truncatedBy?.asModel(),
            isHidden: isHidden ?? false,
            createdBy: channelPayload.createdBy?.asModel(),
            config: channelPayload.config,
            filterTags: Set(channelPayload.filterTags ?? []),
            ownCapabilities: Set(channelPayload.ownCapabilities ?? []),
            isFrozen: channelPayload.frozen,
            isDisabled: channelPayload.disabled,
            isBlocked: channelPayload.blocked ?? false,
            lastActiveMembers: Array(mappedMembers),
            membership: membership?.asModel(channelId: channelPayload.cid),
            typingUsers: typingUsers ?? currentlyTypingUsers?.asTypingUsers ?? [],
            lastActiveWatchers: Array(mappedWatchers),
            team: channelPayload.team,
            isAutoTranslationEnabled: channelPayload.autoTranslationEnabled ?? false,
            autoTranslationLanguages: TranslationLanguage.languages(fromCommaSeparated: channelPayload.autoTranslationLanguage),
            unreadCount: unreadCount ?? .noUnread,
            watcherCount: watcherCount ?? 0,
            memberCount: channelPayload.memberCount ?? 0,
            messageCount: channelPayload.messageCount,
            reads: mappedReads,
            cooldownDuration: channelPayload.cooldown ?? 0,
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
            draftMessage: nil,
            activeLiveLocations: [],
            pushPreference: pushPreference
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
            memberRole: channelRole.map(MemberRole.init(rawChannelValue:)) ?? .member,
            memberStatus: status.map(MemberStatus.init(rawValue:)),
            memberCreatedAt: createdAt,
            memberUpdatedAt: updatedAt,
            memberDeletedAt: deletedAt,
            isInvited: invited ?? false,
            inviteAcceptedAt: inviteAcceptedAt,
            inviteRejectedAt: inviteRejectedAt,
            archivedAt: archivedAt,
            pinnedAt: pinnedAt,
            isBannedFromChannel: banned ?? false,
            banExpiresAt: banExpires,
            isShadowBannedFromChannel: shadowBanned ?? false,
            notificationsMuted: notificationsMuted ?? false,
            avgResponseTime: user.avgResponseTime,
            memberExtraData: custom
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
            user: user.asModel(),
            lastDeliveredAt: lastDeliveredAt,
            lastDeliveredMessageId: lastDeliveredMessageId
        )
    }
}
