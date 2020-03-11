//
//  Client+Events.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient

// MARK: Events

public extension Client {
    
    /// Observe a connected shared event with a given event type.
    /// - Parameters:
    ///   - eventType: an event type.
    ///   - onNext: an event observable block.
    /// - Returns: an observable event.
    func onEvent(eventType: EventType, _ onNext: @escaping Client.Completion<Event>) -> Subscription {
        rx.onEvent(eventTypes: [eventType]).bind(to: onNext)
    }
    
    /// Observe connected shared events with a given even types.
    /// - Parameters:
    ///   - eventTypes: event types.
    ///   - onNext: events observable block.
    /// - Returns: an observable events.
    func onEvent(eventTypes: [EventType] = [], _ onNext: @escaping Client.Completion<Event>) -> Subscription {
        rx.onEvent(eventTypes: eventTypes).bind(to: onNext)
    }
    
    /// Observe a connected shared event with a given event type and channel.
    /// - Parameters:
    ///   - eventType: an event type.
    ///   - channel: a channel.
    ///   - onNext: a channel event observable block.
    /// - Returns: an observable channel events.
    func onEvent(eventType: EventType, channel: Channel, _ onNext: @escaping Client.Completion<Event>) -> Subscription {
        rx.onEvent(eventTypes: [eventType], channel: channel).bind(to: onNext)
    }
    
    /// Observe connected shared events with a given event types and channel.
    /// - Parameters:
    ///   - eventTypes: event types.
    ///   - channel: a channel.
    ///   - onNext: channel events observable block.
    /// - Returns: an observable channel events.
    func onEvent(_ eventTypes: [EventType] = [], channel: Channel, _ onNext: @escaping Client.Completion<Event>) -> Subscription {
        rx.onEvent(eventTypes: eventTypes, channel: channel).bind(to: onNext)
    }
}

// MARK: Unread Count

public extension Client {
    
    /// Observe an unread count of messages nd channels.
    /// - Parameter onNext: an unread count observable block.
    func unreadCount(_ onNext: @escaping Client.Completion<UnreadCount>) -> Subscription {
        rx.unreadCount.bind(to: onNext)
    }
    
    /// Observe an unread count of messages and mentioned messages for a given channel.
    /// - Note: Be sure the current user is a member of the channel.
    /// - Note: 100 is the maximum unread count of messages.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - onNext: a channel unread count observable block.
    func channelUnreadCount(_ channel: Channel, _ onNext: @escaping Client.Completion<ChannelUnreadCount> ) -> Subscription {
        rx.channelUnreadCount(channel).bind(to: onNext)
    }
}

// MARK: Watcher Count

public extension Client {
    /// Observe a watcher count of users for a given channel.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - onNext: a watcher count observable block.
    func watcherCount(channel: Channel, _ onNext: @escaping Client.Completion<Int>) -> Subscription {
        rx.watcherCount(channel: channel).bind(to: onNext)
    }
}
