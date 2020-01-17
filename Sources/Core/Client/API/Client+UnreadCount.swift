//
//  Client+UnreadCount.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 10/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: Unread Count

extension Client {
    
    /// Observe an unread count of messages in the channel.
    /// - Note: Be sure the current user is a member of the channel.
    /// - Note: 100 is the maximum unread count of messages.
    /// - Parameter onNext: a completion block with `UnreadCount`.
    /// - Returns: a subscription.
    public func unreadCount(_ onNext: @escaping Client.Completion<UnreadCount>) -> Subscription {
        return rx.unreadCount.asObservable().bind(to: onNext)
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
