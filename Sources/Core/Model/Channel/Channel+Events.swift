//
//  Channel+Events.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 10/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public extension Channel {
    
    /// Observe channel events.
    /// - Parameters:
    ///   - eventType: an event type.
    ///   - onNext: a onNext block with `Event`.
    /// - Returns: a subscription.
    func onEvent(_ eventType: EventType, _ onNext: @escaping Client.Completion<Event>) -> Subscription {
        return rx.onEvent(eventType).bind(to: onNext)
    }
    
    /// Observe a list of events with a given channel id (optional).
    /// - Parameters:
    ///   - eventType: an event type.
    ///   - onNext: a onNext block with `Event`.
    /// - Returns: a subscription.
    func onEvent(_ eventTypes: [EventType] = [], _ onNext: @escaping Client.Completion<Event>) -> Subscription {
        return rx.onEvent(eventTypes).bind(to: onNext)
    }
    
    /// An observable isUnread state of the channel.
    /// - Parameter onNext: a onNext block with `Bool`.
    /// - Returns: a subscription.
    func isUnread(_ onNext: @escaping Client.Completion<Bool>) -> Subscription {
        return rx.isUnread.asObservable().bind(to: onNext)
    }
    
    /// Observe an unread count of messages in the channel.
    /// - Note: Be sure the current user is a member of the channel.
    /// - Note: 100 is the maximum unread count of messages.
    /// - Parameter onNext: a onNext block with `Int`.
    /// - Returns: a subscription.
    func unreadCount(_ onNext: @escaping Client.Completion<Int>) -> Subscription {
        return rx.unreadCount.asObservable().bind(to: onNext)
    }
    
    /// Observe a user mentioned unread count of messages in the channel.
    /// - Note: Be sure the current user is a member of the channel.
    /// - Note: 100 is the maximum unread count of messages.
    /// - Parameter onNext: a onNext block with `Int`.
    /// - Returns: a subscription.
    func mentionedUnreadCount(_ onNext: @escaping Client.Completion<Int>) -> Subscription {
        return rx.mentionedUnreadCount.asObservable().bind(to: onNext)
    }
    
    /// Online users in the channel.
    /// - Note: Be sure users are members of the channel.
    /// - Parameter onNext: a onNext block with `[User]`.
    /// - Returns: a subscription.
    func onlineUsers(_ onNext: @escaping Client.Completion<[User]>) -> Subscription {
        return rx.onlineUsers.asObservable().bind(to: onNext)
    }
}
