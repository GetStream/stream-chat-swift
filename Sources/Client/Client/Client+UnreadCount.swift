//
//  Client+UnreadCount.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 29/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

extension Client {
    
    // MARK: User Unread Count

    func updateUserUnreadCount(with event: Event) {
        switch event {
        case let .notificationAddedToChannel(_, channelsUnreadCount, messagesUnreadCount, _),
             let .messageNew(_, channelsUnreadCount, messagesUnreadCount, _, _, _),
             let .notificationMarkRead(_, channelsUnreadCount, messagesUnreadCount, _, _):
            user.channelsUnreadCountAtomic.set(channelsUnreadCount)
            user.messagesUnreadCountAtomic.set(messagesUnreadCount)
            userDidUpdate?(user)
        default:
            break
        }
    }
    
    // MARK: Channel Unread Count
    
    func updateChannelsUnreadCount(with event: Event) {
        channels.flush()
        
        channels.forEach { weakChannel in
            if let channel = weakChannel.value {
                updateChannelUnreadCount(channel: channel, event: event)
            }
        }
    }

    /// Update the unread count if needed.
    ///
    /// - Parameter response: a web socket event.
    /// - Returns: true, if unread count was updated.
    @discardableResult
    func updateChannelUnreadCount(channel: Channel, event: Event) -> Bool {
        let oldUnreadCount = channel.unreadCountAtomic.get(default: 0)
        
        guard let cid = event.cid, cid == channel.cid else {
            if case .notificationMarkRead(let notificationChannel, let unreadCount, _, _, _) = event,
                notificationChannel?.cid == channel.cid {
                channel.unreadCountAtomic.set(unreadCount)
                channel.didUpdate?(channel)
                return true
            }
            
            return false
        }
        
        if case .messageNew(let message, let unreadCount, _, _, _, _) = event {
            channel.unreadCountAtomic.set(unreadCount)
            updateUserUnreadCountForChannelUpdate(channels: oldUnreadCount == 0 ? 1 : 0, messages: unreadCount - oldUnreadCount)
            
            if message.user != user, message.mentionedUsers.contains(user) {
                channel.mentionedUnreadCountAtomic += 1
            }
            
            channel.didUpdate?(channel)
            return true
        }
        
        if case .messageRead(let messageRead, _, _) = event, messageRead.user.isCurrent {
            channel.unreadCountAtomic.set(0)
            channel.mentionedUnreadCountAtomic.set(0)
            channel.didUpdate?(channel)
            updateUserUnreadCountForChannelUpdate(channels: oldUnreadCount > 0 ? -1 : 0, messages: -oldUnreadCount)
            return true
        }
        
        return false
    }
    
    private func updateUserUnreadCountForChannelUpdate(channels: Int, messages: Int) {
        // Update user unread counts.
        if channels != 0  {
            user.channelsUnreadCountAtomic += channels
        }
        
        user.messagesUnreadCountAtomic += messages
        userDidUpdate?(user)
    }
}

