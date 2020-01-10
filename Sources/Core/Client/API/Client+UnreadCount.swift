//
//  Client+UnreadCount.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 10/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: Unread Count

/// A tuple for unread counts of channels and messages.
public typealias UnreadCount = (channels: Int, messages: Int)

extension Client {
    
    /// Observe an unread count of messages in the channel.
    ///
    /// - Note: Be sure the current user is a member of the channel.
    /// - Note: 100 is the maximum unread count of messages.
    public func unreadCount(_ completion: @escaping ClientCompletion<UnreadCount>) -> Subscription {
        return rx.unreadCount.asObservable().bind(to: completion)
    }
    
    func updateUnreadCount(_ response: WebSocket.Response) -> Bool {
        switch response.event {
        case .notificationMarkRead(_, let messagesUnreadCount, let channelsUnreadCount, _),
             .messageNew(_, let messagesUnreadCount, let channelsUnreadCount, _, _):
            unreadCountAtomic.set((channelsUnreadCount, messagesUnreadCount))
            return true
        default:
            return false
        }
    }
}
