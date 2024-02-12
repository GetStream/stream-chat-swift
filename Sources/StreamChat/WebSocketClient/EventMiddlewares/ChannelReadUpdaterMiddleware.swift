//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
        case let event as MessageNewEvent:
            if let cid = try? ChannelId(cid: event.cid), let message = event.message {
                incrementUnreadCountIfNeeded(
                    for: cid,
                    message: message,
                    session: session
                )
            }

        case let event as NotificationNewMessageEvent:
            if let cid = try? ChannelId(cid: event.cid) {
                incrementUnreadCountIfNeeded(
                    for: cid,
                    message: event.message,
                    session: session
                )
            }

        case let event as MessageDeletedEvent:
            decrementUnreadCountIfNeeded(
                event: event,
                session: session
            )

        case let event as MessageReadEvent:
            if let cid = try? ChannelId(cid: event.cid),
               let userId = event.user?.id {
                resetChannelRead(
                    for: cid,
                    userId: userId,
                    lastReadAt: event.createdAt,
                    session: session
                )
            }

        case let event as NotificationMarkReadEvent:
            if event.channel == nil, let userId = event.user?.id {
                session.loadChannelReads(for: userId).forEach { read in
                    read.lastReadAt = event.createdAt.bridgeDate
                    read.unreadMessageCount = 0
                }
            } else if let cid = try? ChannelId(cid: event.cid),
                      let userId = event.user?.id {
                resetChannelRead(
                    for: cid,
                    userId: userId,
                    lastReadAt: event.createdAt,
                    session: session
                )
                updateLastReadMessage(
                    for: cid,
                    userId: userId,
                    lastReadMessageId: nil, // TODO: check why it's not available.
                    lastReadAt: event.createdAt,
                    session: session
                )
            }

        case let event as NotificationMarkUnreadEvent:
            if let cid = try? ChannelId(cid: event.cid),
               let userId = event.user?.id {
                markChannelAsUnread(
                    for: cid,
                    userId: userId,
                    from: event.firstUnreadMessageId,
                    lastReadMessageId: event.lastReadMessageId,
                    lastReadAt: event.lastReadAt,
                    unreadMessages: event.unreadMessages,
                    session: session
                )
            }

        default:
            break
        }

        return event
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
            from: messageId,
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
    
    private func incrementUnreadCountIfNeeded(
        for cid: ChannelId,
        message: Message,
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
        event: MessageDeletedEvent,
        session: DatabaseSession
    ) {
        guard let currentUser = session.currentUser else {
            return log.error("Current user is missing", subsystems: .webSocket)
        }

        guard let cid = try? ChannelId(cid: event.cid),
              let channelRead = session.loadOrCreateChannelRead(cid: cid, userId: currentUser.user.id) else {
            return log.error("Channel read is missing", subsystems: .webSocket)
        }
        
        guard let message = event.message else {
            return log.error("Message is missing", subsystems: .webSocket)
        }

        if let skipReason = !event.hardDelete
            ? .messageIsSoftDeleted
            : unreadCountUpdateSkippingReason(
                currentUser: currentUser,
                channelRead: channelRead,
                message: message
            ) {
            return log.debug(
                "Message \(message.id) does not decrement unread coutns for \(message.user?.id ?? ""): \(skipReason)",
                subsystems: .webSocket
            )
        }

        log.debug(
            "Message \(message.id) decrements unread counts for channel \(event.cid)",
            subsystems: .webSocket
        )

        channelRead.unreadMessageCount = max(0, channelRead.unreadMessageCount - 1)
    }

    private func unreadCountUpdateSkippingReason(
        currentUser: CurrentUserDTO,
        channelRead: ChannelReadDTO,
        message: MessagePayload
    ) -> UnreadSkippingReason? {
        if channelRead.channel.mute != nil {
            return .channelIsMuted
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

        if message.type == .system {
            return .messageIsSystem
        }

        if message.createdAt <= channelRead.lastReadAt.bridgeDate {
            return .messageIsSeen
        }

        return nil
    }
    
    private func unreadCountUpdateSkippingReason(
        currentUser: CurrentUserDTO,
        channelRead: ChannelReadDTO,
        message: Message
    ) -> UnreadSkippingReason? {
        if channelRead.channel.mute != nil {
            return .channelIsMuted
        }

        if message.user?.id == currentUser.user.id {
            return .messageIsOwn
        }

        if currentUser.mutedUsers.contains(where: { message.user?.id == $0.id }) {
            return .authorIsMuted
        }

        if message.silent {
            return .messageIsSilent
        }

        if message.parentId != nil && !(message.showInChannel ?? false) {
            return .messageIsThreadReply
        }

        // TODO: check this.
        if message.type == "system" {
            return .messageIsSystem
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
    case messageIsSystem
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
        case .messageIsSystem:
            return "System messages do not affect unread counts"
        case .messageIsSeen:
            return "Seen messages do not affect unread counts"
        case .messageIsSoftDeleted:
            return "Soft-deleted messages do not affect unread counts"
        }
    }
}
