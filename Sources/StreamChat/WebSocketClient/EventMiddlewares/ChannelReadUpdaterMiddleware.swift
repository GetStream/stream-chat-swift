//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A middleware which updates a channel's read events as websocket events arrive.
struct ChannelReadUpdaterMiddleware: EventMiddleware {
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
            resetChannelRead(for: event.cid, userId: event.user.id, lastReadAt: event.createdAt, session: session)

        case let event as NotificationMarkReadEventDTO:
            resetChannelRead(for: event.cid, userId: event.user.id, lastReadAt: event.createdAt, session: session)

        case let event as NotificationMarkAllReadEventDTO:
            session.loadChannelReads(for: event.user.id).forEach { read in
                read.lastReadAt = event.createdAt.bridgeDate
                read.unreadMessageCount = 0
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
    
    private func incrementUnreadCountIfNeeded(
        for cid: ChannelId,
        message: MessagePayload,
        session: DatabaseSession
    ) {
        guard let currentUser = session.currentUser else {
            return log.error("Current user is missing", subsystems: .webSocket)
        }
        
        guard let channelRead = session.loadChannelRead(cid: cid, userId: currentUser.user.id) else {
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
        
        guard let channelRead = session.loadChannelRead(cid: event.cid, userId: currentUser.user.id) else {
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
