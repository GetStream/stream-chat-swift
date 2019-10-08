//
//  Client+Events.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 08/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

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

// MARK: - Unread Count

extension Client {
    public typealias UnreadCount = (channels: Int, messages: Int)
    
    /// Observe an unread count of messages in the channel.
    ///
    /// - Note: Be sure the current user is a member of the channel.
    /// - Note: 100 is the maximum unread count of messages.
    public var unreadCount: Driver<UnreadCount> {
        return Client.shared.connection.connected()
            // Subscribe for new messages and read events.
            .flatMapLatest({ [weak self] _ in
                Client.shared.webSocket.response
                    .filter { self?.updateUnreadCount($0) ?? false }
                    .map { _ in self?.unreadCountAtomic.get() }
                    .startWith(self?.unreadCountAtomic.get())
                    .unwrap()
            })
            .startWith((0, 0))
            .map { "\($0.0), \($0.1)" }
            .distinctUntilChanged()
            .map { [weak self] _ in self?.unreadCountAtomic.get() ?? (0, 0) }
            .asDriver(onErrorJustReturn: (0, 0))
    }
    
    func updateUnreadCount(_ response: WebSocket.Response) -> Bool {
        switch response.event {
        case .notificationMarkRead(_, let messagesUnreadCount, let channelsUnreadCount, _),
             .messageNew(_, let messagesUnreadCount, let channelsUnreadCount, _, _):
            unreadCountAtomic.set((channelsUnreadCount, messagesUnreadCount))
            return true
        default:
            return false
        }
    }
}
