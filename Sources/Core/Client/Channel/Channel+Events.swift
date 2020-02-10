//
//  Channel+Events.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 10/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient

public extension Channel {
    
    /// Observe events with a given event type and channel.
    /// - Parameter eventType: an event type.
    /// - Returns: an observable channel events.
    func onEvent(eventType: EventType, _ onNext: @escaping Client.Completion<StreamChatClient.Event>) -> Subscription {
        rx.onEvent(eventType: eventType).bind(to: onNext)
    }
    
    /// Observe events with a given event types and channel.
    /// - Parameter eventTypes: event types.
    /// - Returns: an observable channel events.
    func onEvent(eventTypes: [EventType] = [], _ onNext: @escaping Client.Completion<StreamChatClient.Event>) -> Subscription {
        rx.onEvent(eventTypes: eventTypes).bind(to: onNext)
    }
    
    // MARK: - Unread Count
    
    /// An observable channel unread count.
    func unreadCount(_ onNext: @escaping Client.Completion<ChannelUnreadCount>) -> Subscription {
        rx.unreadCount.bind(to: onNext)
    }
    
    /// An observable channel isUnread state.
    func isUnread(_ onNext: @escaping Client.Completion<Bool>) -> Subscription {
        rx.isUnread.bind(to: onNext)
    }
    
    // MARK: - Users Presence
    
    /// Online users in the channel.
    /// - Note: Be sure users are members of the channel.
    func onlineUsers(_ onNext: @escaping Client.Completion<Set<User>>) -> Subscription {
        rx.onlineUsers.bind(to: onNext)
    }
}
