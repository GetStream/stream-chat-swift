//
//  Client+Events.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient

// MARK: Unread Count

public extension Client {
    
    /// Observe an unread count of messages nd channels.
    /// - Parameter onNext: an unread count observable block.
    func unreadCount(_ onNext: @escaping Client.Completion<UnreadCount>) -> AutoCancellingSubscription {
        rx.unreadCount.bind(to: onNext)
    }
    
    /// Observe an unread count of messages and mentioned messages for a given channel.
    /// - Note: Be sure the current user is a member of the channel.
    /// - Note: 100 is the maximum unread count of messages.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - onNext: a channel unread count observable block.
    func channelUnreadCount(_ channel: Channel, _ onNext: @escaping Client.Completion<ChannelUnreadCount> ) -> AutoCancellingSubscription {
        rx.channelUnreadCount(channel).bind(to: onNext)
    }
}

// MARK: Watcher Count

public extension Client {
    /// Observe a watcher count of users for a given channel.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - onNext: a watcher count observable block.
    func watcherCount(channel: Channel, _ onNext: @escaping Client.Completion<Int>) -> AutoCancellingSubscription {
        rx.watcherCount(channel: channel).bind(to: onNext)
    }
}
