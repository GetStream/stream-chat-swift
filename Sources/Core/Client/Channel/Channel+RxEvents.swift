//
//  Channel+RxEvents.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 08/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift
import RxCocoa

// MARK: Events

public extension Reactive where Base == Channel {
    
    /// Observe events with a given event type and channel.
    /// - Parameter eventType: an event type.
    /// - Returns: an observable channel events.
    func event(eventType: EventType) -> Observable<StreamChatClient.Event> {
        Client.shared.rx.events(eventTypes: [eventType], cid: base.cid)
    }
    
    /// Observe events with a given event types and channel.
    /// - Parameter eventTypes: event types.
    /// - Returns: an observable channel events.
    func events(eventTypes: [EventType] = []) -> Observable<StreamChatClient.Event> {
        Client.shared.rx.events(eventTypes: eventTypes, cid: base.cid)
    }
    
    // MARK: - Unread Count
    
    /// An observable channel unread count.
    var unreadCount: Observable<ChannelUnreadCount> {
        Client.shared.rx.channelUnreadCount(base)
    }
    
    /// An observable channel isUnread state.
    var isUnread: Observable<Bool> {
        unreadCount.map({ $0.messages > 0 })
    }
    
    // MARK: - Users Presence
    
    /// Observe a watcher count of users for the channel.
    var watcherCount: Observable<Int> {
        Client.shared.rx.watcherCount(channel: base)
    }
}
