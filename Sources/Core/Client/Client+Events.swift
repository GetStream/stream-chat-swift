//
//  Client+Events.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 08/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Events

public extension Client {
    
    /// Observe a list of event types.
    ///
    /// - Parameter eventType: an event type.
    /// - Returns: an observable event.
    func onEvent(_ eventType: EventType) -> Observable<Event> {
        return onEvents([eventType])
    }
    
    /// Observe a list of events.
    ///
    /// - Parameter eventTypes: a list of event types.
    /// - Returns: an observable events.
    func onEvent(_ eventTypes: [EventType] = []) -> Observable<Event> {
        return onEvents(eventTypes)
    }
    
    /// Observe a list of events with a given channel type and id.
    ///
    /// - Parameters:
    ///   - eventType: an of event type.
    ///   - channel: a channel for filtering events.
    /// - Returns: an observable events.
    func onEvent(_ eventType: EventType, channel: Channel) -> Observable<Event> {
        return onEvents([eventType], channel: channel)
    }
    
    /// Observe a list of events with a given channel type and id.
    ///
    /// - Parameters:
    ///   - eventTypes: a list of event types.
    ///   - channel: a channel for filtering events.
    /// - Returns: an observable events.
    func onEvent(_ eventTypes: [EventType] = [], channel: Channel) -> Observable<Event> {
        return onEvents(eventTypes, channel: channel)
    }
    
    private func onEvents(_ eventTypes: [EventType], channel: Channel? = nil) -> Observable<Event> {
        let events: Observable<WebSocket.Response>
        
        if let channel = channel {
            events = channel.query(options: .watch).flatMapLatest { _ in Client.shared.webSocket.response }
        } else {
            events = webSocket.response
        }
        
        return connection.connected()
            .flatMapLatest { events }
            .filter {
                if let channel = channel {
                    if let eventChannelId = $0.channelId {
                        return channel.type == $0.channelType && channel.id == eventChannelId
                    }
                    
                    return false
                }
                
                return true
            }
            .map { $0.event }
            .filter { (eventTypes.isEmpty && $0.type != .healthCheck) || eventTypes.contains($0.type) }
            .share()
    }
}
