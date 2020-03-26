//
//  Channel+Events.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 10/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift

public extension Channel {
    
    /// Observe events with a given event type and channel.
    /// - Parameter eventType: an event type.
    /// - Returns: an observable channel events.
    func event(eventType: EventType, _ onNext: @escaping Client.Completion<StreamChatClient.Event>) -> Subscription {
        rx.event(eventType: eventType).bind(to: onNext)
    }
    
    /// Observe events with a given event types and channel.
    /// - Parameter eventTypes: event types.
    /// - Returns: an observable channel events.
    func events(eventTypes: [EventType] = [], _ onNext: @escaping Client.Completion<StreamChatClient.Event>) -> Subscription {
        rx.events(eventTypes: eventTypes).bind(to: onNext)
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
    
    /// Observe a watcher count of users for the channel.
    func watcherCount(_ onNext: @escaping Client.Completion<Int>) -> Subscription {
        rx.watcherCount.bind(to: onNext)
    }
}
