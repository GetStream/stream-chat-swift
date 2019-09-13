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
        return onEvents([eventType], channelType: .messaging, channelId: nil)
    }
    
    /// Observe a list of events.
    ///
    /// - Parameter eventTypes: a list of event types.
    /// - Returns: an observable events.
    func onEvent(_ eventTypes: [EventType] = []) -> Observable<Event> {
        return onEvents(eventTypes, channelType: .messaging, channelId: nil)
    }
    
    /// Observe a list of events with a given channel type and id.
    ///
    /// - Parameters:
    ///   - eventType: an of event type.
    ///   - channelType: a channel type.
    ///   - channelId: a channel id.
    /// - Returns: an observable events.
    func onEvent(_ eventType: EventType, channelType: ChannelType, channelId: String) -> Observable<Event> {
        return onEvents([eventType], channelType: channelType, channelId: channelId)
    }
    
    /// Observe a list of events with a given channel type and id.
    ///
    /// - Parameters:
    ///   - eventTypes: a list of event types.
    ///   - channelType: a channel type.
    ///   - channelId: a channel id.
    /// - Returns: an observable events.
    func onEvent(_ eventTypes: [EventType] = [], channelType: ChannelType, channelId: String) -> Observable<Event> {
        return onEvents(eventTypes, channelType: channelType, channelId: channelId)
    }
    
    private func onEvents(_ eventTypes: [EventType], channelType: ChannelType, channelId: String?) -> Observable<Event> {
        let events: Observable<WebSocket.Response>
        
        if let channelId = channelId {
            events = Channel(type: channelType, id: channelId).query(options: .watch)
                .flatMapLatest { _ in Client.shared.webSocket.response }
        } else {
            events = webSocket.response
        }
        
        return connection.connected()
            .flatMapLatest { events }
            .filter {
                if let channelId = channelId {
                    if let eventChannelId = $0.channelId {
                        return channelType == $0.channelType && channelId == eventChannelId
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
