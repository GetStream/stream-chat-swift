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
    /// - Parameter eventType: an event type.
    /// - Returns: an observable event.
    func onEvent(eventType: EventType, _ onNext: @escaping Client.Completion<Event>) -> Subscription {
        rx.onEvent(eventTypes: [eventType]).bind(to: onNext)
    }
    
    /// Observe connected shared events with a given even types.
    /// - Parameter eventTypes: event types.
    /// - Returns: an observable events.
    func onEvent(eventTypes: [EventType] = [], _ onNext: @escaping Client.Completion<Event>) -> Subscription {
        rx.onEvent(eventTypes: eventTypes).bind(to: onNext)
    }
    
    /// Observe a connected shared event with a given event type and channel.
    /// - Parameters:
    ///   - eventType: an event type.
    ///   - channel: a channel.
    /// - Returns: an observable channel events.
    func onEvent(eventType: EventType, channel: Channel, _ onNext: @escaping Client.Completion<Event>) -> Subscription {
        rx.onEvent(eventTypes: [eventType], channel: channel).bind(to: onNext)
    }
    
    /// Observe connected shared events with a given event types and channel.
    /// - Parameters:
    ///   - eventTypes: event types.
    ///   - channel: a channel.
    /// - Returns: an observable channel events.
    func onEvent(_ eventTypes: [EventType] = [], channel: Channel, _ onNext: @escaping Client.Completion<Event>) -> Subscription {
        rx.onEvent(eventTypes: eventTypes, channel: channel).bind(to: onNext)
    }
}
