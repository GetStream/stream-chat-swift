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
    /// - Parameter response: a web socket event.
    func updateWatcherCount(event: Event) {
        switch event {
        case .userStartWatching(_, let watcherCount, _, _),
             .userStopWatching(_, let watcherCount, _, _),
             .messageNew(_, let watcherCount, _, _),
             .notificationMessageNew(_, _, _, let watcherCount, _):
            watcherCountAtomic.set(watcherCount)
        default:
            break
        }
    }
}
