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
    /// - Parameters:
    ///     - eventType: an event type.
    ///     - channelId: a channeld id (optional).
    /// - Returns: an observable event.
    func onEvent(_ eventType: EventType, channelId: String? = nil) -> Observable<Event> {
        return onEvent([eventType], channelId: channelId)
    }
    
    /// Observe a list of events with a given channel id (optional).
    ///
    /// - Parameters:
    ///     - eventType: an event type (optional).
    ///     - channelId: a channeld id (optional).
    /// - Returns: an observable events.
    func onEvent(_ eventTypes: [EventType] = [], channelId: String? = nil) -> Observable<Event> {
        let events: Observable<WebSocket.Response>
        
        if let channelId = channelId {
            events = Channel(id: channelId).query(pagination: .limit(1), queryOptions: .watch)
                .flatMapLatest { _ in Client.shared.webSocket.response }
        } else {
            events = webSocket.response
        }
        
        return connection.connected()
            .flatMapLatest { events }
            .filter {
                if let channelId = channelId {
                    if let eventChannelId = $0.channelId {
                        return channelId == eventChannelId
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
