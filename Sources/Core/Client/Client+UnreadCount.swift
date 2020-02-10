//
//  Client+UnreadCount.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 10/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient

// MARK: Unread Count

public extension Client {
    
    /// Observe an unread count of messages nd channels.
    func unreadCount(_ onNext: @escaping Client.Completion<UnreadCount>) -> Subscription {
        rx.unreadCount.bind(to: onNext)
    }
    
    /// Observe an unread count of messages and mentioned messages for a given channel.
    /// - Note: Be sure the current user is a member of the channel.
    /// - Note: 100 is the maximum unread count of messages.
    /// - Parameter channel: a channel.
    func channelUnreadCount(_ channel: Channel, _ onNext: @escaping Client.Completion<ChannelUnreadCount> ) -> Subscription {
        rx.channelUnreadCount(channel).bind(to: onNext)
    }
}
