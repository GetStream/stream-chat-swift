//
//  Client+Events.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: Events

public extension Client {
    
    /// Observe a list of event types.
    /// - Parameters:
    ///   - eventType: an event type.
    ///   - completion: a completion block with `Event`.
    /// - Returns: a subscription.
    func onEvent(_ eventType: EventType, _ completion: @escaping ClientCompletion<Event>) -> Subscription {
        return rx.onEvent(eventType).bind(to: completion)
    }
    
    /// Observe a list of events.
    /// - Parameters:
    ///   - eventTypes: a list of event types.
    ///   - completion: a completion block with `Event`.
    /// - Returns: a subscription.
    func onEvent(_ eventTypes: [EventType] = [], _ completion: @escaping ClientCompletion<Event>) -> Subscription {
        return rx.onEvent(eventTypes).bind(to: completion)
    }
    
    /// Observe a list of events with a given channel type and id.
    /// - Parameters:
    ///   - eventType: an of event type.
    ///   - channel: a channel for filtering events.
    ///   - completion: a completion block with `Event`.
    /// - Returns: a subscription.
    func onEvent(_ eventType: EventType, channel: Channel, _ completion: @escaping ClientCompletion<Event>) -> Subscription {
        return rx.onEvent([eventType], channel: channel).bind(to: completion)
    }
    
    /// Observe a list of events with a given channel type and id.
    ///
    /// - Parameters:
    ///   - eventTypes: a list of event types.
    ///   - channel: a channel for filtering events.
    ///   - completion: a completion block with `Event`.
    /// - Returns: a subscription.
    func onEvent(_ eventTypes: [EventType] = [],
                 channel: Channel,
                 _ completion: @escaping ClientCompletion<Event>) -> Subscription {
        return rx.onEvent(eventTypes, channel: channel).bind(to: completion)
    }
}
