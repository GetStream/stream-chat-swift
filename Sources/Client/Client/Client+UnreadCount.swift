//
//  Client+UnreadCount.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 29/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: User Unread Count

extension Client {
    
    func updateUserUnreadCount(with event: Event) {
        var unreadCountsUpdated = false
        var updatedChannelsUnreadCount = 0
        var updatedMssagesUnreadCount = 0
        
        switch event {
        case let .notificationAddedToChannel(_, channelsUnreadCount, messagesUnreadCount, _),
             let .notificationMarkRead(_, channelsUnreadCount, messagesUnreadCount, _, _):
            updatedChannelsUnreadCount = channelsUnreadCount
            updatedMssagesUnreadCount = messagesUnreadCount
            unreadCountsUpdated = true
        case let .messageNew(_, channelsUnreadCount, messagesUnreadCount, _, _, eventType):
            if case .notificationMessageNew = eventType {
                updatedChannelsUnreadCount = channelsUnreadCount
                updatedMssagesUnreadCount = messagesUnreadCount
                unreadCountsUpdated = true
            }
        default:
            break
        }
        
        if unreadCountsUpdated {
            user.channelsUnreadCountAtomic.set(updatedChannelsUnreadCount)
            user.messagesUnreadCountAtomic.set(updatedMssagesUnreadCount)
            onUserUpdate?(user)
        }
    }
    
    // MARK: Channel Unread Count
    
    /// Update the unread count if needed.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - event: an event.
    func updateChannelUnreadCount(channel: Channel, event: Event) {
        let oldUnreadCount = channel.unreadCountAtomic.get(default: 0)
        
        switch event {
        case .notificationMarkRead(_, let unreadCount, _, _, _):
            channel.unreadCountAtomic.set(unreadCount)
            channel.unreadMessageReadAtomic.set(.init(user: .current, lastReadDate: Date()))
            
        case let .messageNew(message, unreadCount, _, _, _, eventType):
            channel.unreadCountAtomic.set(unreadCount)
            
            // A regular new message.
            if case .messageNew = eventType {
                updateUserUnreadCountForChannelUpdate(channelsUnreadCountDiff: oldUnreadCount == 0 ? 1 : 0,
                                                      messagesUnreadCountDiff: unreadCount - oldUnreadCount)
                
                if unreadCount > 0, !message.user.isCurrent, message.mentionedUsers.contains(user) {
                    channel.mentionedUnreadCountAtomic += 1
                }
                
                if message.user.isCurrent {
                    channel.unreadMessageReadAtomic.set(nil)
                } else {
                    channel.unreadMessageReadAtomic.set(.init(user: message.user, lastReadDate: message.created))
                }
            } else { // A notification new message.
                if unreadCount > 0, channel.unreadMessageReadAtomic.get() == nil {
                    channel.unreadMessageReadAtomic.set(.init(user: message.user, lastReadDate: message.created))
                }
            }
            
        case .messageRead(let messageRead, _, _):
            if messageRead.user.isCurrent {
                channel.unreadCountAtomic.set(0)
                channel.mentionedUnreadCountAtomic.set(0)
                channel.unreadMessageReadAtomic.set(nil)
                updateUserUnreadCountForChannelUpdate(channelsUnreadCountDiff: oldUnreadCount > 0 ? -1 : 0,
                                                      messagesUnreadCountDiff: -oldUnreadCount)
            }
            
        default: return
        }
        
        channel.onUpdate?(channel)
    }
    
    private func updateUserUnreadCountForChannelUpdate(channelsUnreadCountDiff: Int, messagesUnreadCountDiff: Int) {
        // Update user unread counts.
        if channelsUnreadCountDiff != 0  {
            user.channelsUnreadCountAtomic += channelsUnreadCountDiff
        }
        
        user.messagesUnreadCountAtomic += messagesUnreadCountDiff
        onUserUpdate?(user)
    }
}

