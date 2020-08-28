//
//  Client+UnreadCount.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 29/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: User Unread Count
//
// To get global user unread count:
//   1. Get the latest values from me on connect.
//   2. Listing notifications for new values:
//     - `.messageNew`
//     - `.notificationMessageNew`
//     - `.notificationMarkRead`
//     - `.notificationAddedToChannel`
//     - `.notificationMarkAllRead`: 0 values

extension Client {
    func updateUserUnreadCount(event: Event) {
        var updatedUnreadCount = UnreadCount.noUnread
        
        switch event {
        case .notificationMarkAllRead:
            break
            
        case .notificationAddedToChannel(_, let unreadCount, _),
             .notificationMarkRead(_, _, let unreadCount, _),
             .notificationMessageNew(_, _, let unreadCount, _, _):
            updatedUnreadCount = unreadCount
            
        case let .messageNew(message, unreadCount, _, _, _)
            // Skip updating global unread count when the message is: reply, silent or from the current user.
            // Skip updating for `unreadCount` with zero values, because it could be from a channel with read disabled.
            where !message.isReply && !message.isSilent && unreadCount != .noUnread && !message.user.isCurrent:
            updatedUnreadCount = unreadCount
            
        default:
            return
        }
        
        unreadCountAtomic.set(updatedUnreadCount)
    }
}

// MARK: Channel Unread Count
//
// The channel should be watched.
//   1. Make query options to `[.watch, .state]` and set the pagination to `.limit(1)`.
//   2. Use unread count values for `.messageNew` event.
//   3. Set to 0 for the unread count with `.notificationMarkRead` or `.notificationMarkAllRead`.

extension Client {
    func updateChannelsForWatcherAndUnreadCount(event: Event) {
        if case .notificationMarkAllRead(let messageRead, _) = event {
            watchingChannelsAtomic.get().forEach {
                $0.value.forEach {
                    if let channel = $0.value {
                        channel.resetUnreadCount(messageRead: messageRead)
                    }
                }
            }
            
            return
        }
        
        guard let eventCid = event.cid, let watchingChannels = watchingChannelsAtomic[eventCid] else {
            return
        }
        
        // Update watching channels for unread count and watcher count.
        watchingChannels.forEach {
            if let channel = $0.value {
                channel.updateWatcherCount(event: event)
                
                if channel.readEventsEnabled {
                    channel.updateUnreadCount(event: event)
                }
            }
        }
    }
}

extension Client {
    // Update unread and watcher counts for all channels with the same cid.
    func refreshWatchingChannels(with channel: Channel) {
        guard let weakWatchingChannels = watchingChannelsAtomic.get()[channel.cid], !weakWatchingChannels.isEmpty else {
            watchingChannelsAtomic.add(channel, key: channel.cid)
            return
        }
        
        var weakChannels = weakWatchingChannels
        weakChannels.append(WeakRef(channel))
        
        // Update unread count.
        // Find the max unread count.
        let maxUnreadCount: ChannelUnreadCount = weakChannels.reduce(.noUnread) { result, weakChannel in
            if let channel = weakChannel.value, channel.unreadCount.messages > result.messages {
                return channel.unreadCount
            }
            
            return result
        }
        
        weakChannels.forEach { $0.value?.unreadCountAtomic.set(maxUnreadCount) }
        
        // Update watchers count.
        weakChannels.forEach { $0.value?.watcherCountAtomic.set(channel.watcherCount) }
        
        // Update members count.
        weakChannels.forEach { $0.value?.memberCountAtomic.set(channel.memberCount) }
        
        watchingChannelsAtomic.update { watchingChannels in
            var watchingChannels = watchingChannels
            watchingChannels[channel.cid] = weakChannels
            return watchingChannels
        }
    }
}
