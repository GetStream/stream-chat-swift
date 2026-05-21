//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A middleware which updates a channel's read events as websocket events arrive.
struct ChannelReadUpdaterMiddleware: EventMiddleware {
    private var newProcessedMessageIds: () -> Set<MessageId>

    init(newProcessedMessageIds: @escaping () -> Set<MessageId>) {
        self.newProcessedMessageIds = newProcessedMessageIds
    }

    func handle(event: Event, session: DatabaseSession) -> Event? {
        switch event {
        case let event as MessageNewEventDTO:
            incrementUnreadCountIfNeeded(
                for: event.cid,
                message: event.message,
                session: session
            )

        case let event as NotificationMessageNewEventDTO:
            incrementUnreadCountIfNeeded(
                for: event.channel.cid,
                message: event.message,
                session: session
            )

        case let event as MessageDeletedEventDTO:
            decrementUnreadCountIfNeeded(
                event: event,
                session: session
            )

        case let event as MessageReadEventDTO:
            if isThreadReadEvent(eventPayload: event.payload) {
                break
            }
            resetChannelRead(
                for: event.cid,
                userId: event.user.id,
                lastReadAt: event.createdAt,
                session: session
            )

        case let event as NotificationMarkReadEventDTO:
            if isThreadReadEvent(eventPayload: event.payload) {
                break
            }
            resetChannelRead(
                for: event.cid,
                userId: event.user.id,
                lastReadAt: event.createdAt,
                session: session
            )
            updateLastReadMessage(
                for: event.cid,
                userId: event.user.id,
                lastReadMessageId: event.lastReadMessageId,
                lastReadAt: event.createdAt,
                session: session
            )

        case let event as NotificationMarkUnreadEventDTO:
            markChannelAsUnread(
                for: event.cid,
                userId: event.user.id,
                from: event.firstUnreadMessageId,
                lastReadMessageId: event.lastReadMessageId,
                lastReadAt: event.lastReadAt,
                unreadMessages: event.unreadMessagesCount,
                session: session
            )

        case let event as NotificationMarkAllReadEventDTO:
            session.loadChannelReads(for: event.user.id).forEach { read in
                read.lastReadAt = event.createdAt.bridgeDate
                read.unreadMessageCount = 0
            }

        case let event as ChannelUpdatedEventDTO:
            adjustUnreadChannelCountsForGroupChange(event: event, session: session)

        default:
            break
        }

        return event
    }

    /// Adjusts the current user's per-group unread-channel counts when a `ChannelUpdatedEvent`
    /// moves a channel between groups.
    ///
    /// Earlier middlewares in the chain (`EventDataProcessorMiddleware`) have already overwritten
    /// `channelDTO.extraData` with the new payload, so the old group can no longer be read off the
    /// channel directly. We recover it from `channelDTO.queries` — `ChannelListLinker` re-links
    /// the channel into the new group's query *after* the middleware chain finishes, so at this
    /// point the channel is still linked to whichever grouped query represented its previous group.
    ///
    /// The `"all"` bucket is intentionally skipped on both sides — its count is driven by the
    /// server's `unread_channels` field, not by per-channel deltas.
    ///
    /// Channel updated events are not carrying unread group counts.
    private func adjustUnreadChannelCountsForGroupChange(
        event: ChannelUpdatedEventDTO,
        session: DatabaseSession
    ) {
        guard let channelDTO = session.channel(cid: event.channel.cid) else { return }
        guard let knownGroupKeys = session.currentUser?.unreadChannelCountsByGroup?.keys,
              !knownGroupKeys.isEmpty else { return }

        let groupedFilterHashes = channelDTO.queries
            .map(\.filterHash)
            .filter { knownGroupKeys.contains($0) }
        guard !groupedFilterHashes.isEmpty else { return }

        let oldGroup = groupedFilterHashes.first { $0 != GroupedChannelKey.all }
        let newGroup = event.channel.extraData[GroupedChannelKey.extraData]?.stringValue?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard oldGroup != newGroup else { return }
        guard channelDTO.currentUserUnreadMessagesCount > 0 else { return }

        if let oldGroup, oldGroup != GroupedChannelKey.all {
            session.adjustUnreadChannelCount(forGroup: oldGroup, by: -1)
        }
        if let newGroup, !newGroup.isEmpty, newGroup != GroupedChannelKey.all {
            session.adjustUnreadChannelCount(forGroup: newGroup, by: 1)
        }
    }

    private func isThreadReadEvent(eventPayload: EventPayload) -> Bool {
        eventPayload.threadDetails != nil || eventPayload.threadPartial != nil
    }

    private func resetChannelRead(
        for cid: ChannelId,
        userId: UserId,
        lastReadAt: Date,
        session: DatabaseSession
    ) {
        session.markChannelAsRead(cid: cid, userId: userId, at: lastReadAt)
    }

    private func updateLastReadMessage(
        for cid: ChannelId,
        userId: UserId,
        lastReadMessageId: MessageId?,
        lastReadAt: Date,
        session: DatabaseSession
    ) {
        guard let read = session.loadChannelRead(cid: cid, userId: userId) else { return }
        read.lastReadMessageId = lastReadMessageId
    }

    private func markChannelAsUnread(
        for cid: ChannelId,
        userId: UserId,
        from messageId: MessageId,
        lastReadMessageId: MessageId?,
        lastReadAt: Date,
        unreadMessages: Int,
        session: DatabaseSession
    ) {
        session.markChannelAsUnread(
            for: cid,
            userId: userId,
            from: .messageId(messageId),
            lastReadMessageId: lastReadMessageId,
            lastReadAt: lastReadAt,
            unreadMessagesCount: unreadMessages
        )
    }

    private func incrementUnreadCountIfNeeded(
        for cid: ChannelId,
        message: MessagePayload,
        session: DatabaseSession
    ) {
        guard let currentUser = session.currentUser else {
            return log.error("Current user is missing", subsystems: .webSocket)
        }

        // If the message exists in the database before processing the current batch of events, it means it was
        // already processed and we don't have to increase the unread count
        guard newProcessedMessageIds().contains(message.id) else {
            return log.debug("Not incrementing count for \(message.id) as this message has already been processed")
        }

        guard let channelRead = session.loadOrCreateChannelRead(cid: cid, userId: currentUser.user.id) else {
            return log.error("Channel read is missing", subsystems: .webSocket)
        }

        if let skipReason = unreadCountUpdateSkippingReason(
            currentUser: currentUser,
            channelRead: channelRead,
            message: message
        ) {
            return log.debug(
                "Message \(message.id) does not increment unread counts for channel \(cid): \(skipReason)",
                subsystems: .webSocket
            )
        }

        log.debug(
            "Message \(message.id) increments unread counts for channel \(cid)",
            subsystems: .webSocket
        )

        channelRead.unreadMessageCount += 1
    }

    private func decrementUnreadCountIfNeeded(
        event: MessageDeletedEventDTO,
        session: DatabaseSession
    ) {
        guard let currentUser = session.currentUser else {
            return log.error("Current user is missing", subsystems: .webSocket)
        }

        guard let channelRead = session.loadOrCreateChannelRead(cid: event.cid, userId: currentUser.user.id) else {
            return log.error("Channel read is missing", subsystems: .webSocket)
        }

        if let skipReason = !event.hardDelete
            ? .messageIsSoftDeleted
            : unreadCountUpdateSkippingReason(
                currentUser: currentUser,
                channelRead: channelRead,
                message: event.message
            ) {
            return log.debug(
                "Message \(event.message.id) does not decrement unread coutns for \(event.message.user.id): \(skipReason)",
                subsystems: .webSocket
            )
        }

        log.debug(
            "Message \(event.message.id) decrements unread counts for channel \(event.cid)",
            subsystems: .webSocket
        )

        channelRead.unreadMessageCount = max(0, channelRead.unreadMessageCount - 1)
    }

    private func unreadCountUpdateSkippingReason(
        currentUser: CurrentUserDTO,
        channelRead: ChannelReadDTO,
        message: MessagePayload
    ) -> UnreadSkippingReason? {
        if let mute = channelRead.channel.mute {
            guard let expiredDate = mute.expiresAt, expiredDate.bridgeDate <= Date() else {
                return .channelIsMuted
            }
        }

        if message.user.id == currentUser.user.id {
            return .messageIsOwn
        }

        if currentUser.mutedUsers.contains(where: { message.user.id == $0.id }) {
            return .authorIsMuted
        }

        if message.isSilent {
            return .messageIsSilent
        }

        if message.parentId != nil && !message.showReplyInChannel {
            return .messageIsThreadReply
        }

        if message.isShadowed {
            return .messageIsShadowed
        }

        if message.createdAt <= channelRead.lastReadAt.bridgeDate {
            return .messageIsSeen
        }

        return nil
    }
}

private enum UnreadSkippingReason: CustomStringConvertible {
    case channelIsMuted
    case authorIsMuted
    case messageIsOwn
    case messageIsSilent
    case messageIsThreadReply
    case messageIsShadowed
    case messageIsSeen
    case messageIsSoftDeleted

    var description: String {
        switch self {
        case .channelIsMuted:
            return "Channel is muted"
        case .messageIsOwn:
            return "Own messages do not affect unread counts"
        case .authorIsMuted:
            return "Message author is muted"
        case .messageIsSilent:
            return "Silent messages do not affect unread counts"
        case .messageIsThreadReply:
            return "Thread replies do not affect unread counts"
        case .messageIsShadowed:
            return "Shadowed messages do not affect unread counts"
        case .messageIsSeen:
            return "Seen messages do not affect unread counts"
        case .messageIsSoftDeleted:
            return "Soft-deleted messages do not affect unread counts"
        }
    }
}
