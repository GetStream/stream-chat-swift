//
//  Client+WatcherCount.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 07/02/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: Watcher Count

extension Channel {
    
    /// Update the unread count if needed.
    /// - Parameter clientEvent: a client event.
    func updateWatcherCount(event: ClientEvent) {
        if case .notificationMessageNew(_, _, _, let watcherCount, _) = event {
            watcherCountAtomic.set(watcherCount)
        }
    }
    
    /// Update the unread count if needed.
    /// - Parameter channelEvent: a channel event.
    func updateWatcherCount(channelEvent: ChannelEvent) {
        switch channelEvent {
        case .userStartWatching(_, let watcherCount, _, _),
             .userStopWatching(_, let watcherCount, _, _),
             .messageNew(_, let watcherCount, _, _):
            watcherCountAtomic.set(watcherCount)
        default:
            break
        }
    }
}
