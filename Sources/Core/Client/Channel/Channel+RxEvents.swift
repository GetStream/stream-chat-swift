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

extension Channel {
    fileprivate static var rxOnEvent: UInt8 = 0
}

public extension Reactive where Base == Channel {
    
    /// Observe all events for this channel.
    var events: Observable<StreamChatClient.Event> {
        associated(to: base, key: &Channel.rxOnEvent) { [weak base] in
            Observable<StreamChatClient.Event>.create({ observer in
                let subscription = base?.subscribe { observer.onNext($0) }
                return Disposables.create { subscription?.cancel() }
            })
                .share()
        }
    }
    
    /// Observe events with a given event type and channel.
    /// - Parameter eventType: an event type.
    /// - Returns: an observable channel events.
    func events(for type: EventType) -> Observable<StreamChatClient.Event> {
        events.filter({ $0.type == type }).share()
    }
    
    /// Observe events with a given event types and channel.
    /// - Parameter eventTypes: event types.
    /// - Returns: an observable channel events.
    func events(for types: Set<EventType> = Set(EventType.allCases)) -> Observable<StreamChatClient.Event> {
        events.filter({ types.contains($0.type) }).share()
    }
    
    // MARK: - Unread Count
    
    /// An observable channel unread count.
    var unreadCount: Observable<ChannelUnreadCount> {
        Observable<ChannelUnreadCount>.create { [weak base] (observer) -> Disposable in
            let subscription = base?.subscribeToUnreadCount { result in
                do {
                    let response = try result.get()
                    observer.onNext(response)
                } catch {
                    observer.onError(error)
                }
            }
            
            return Disposables.create { subscription?.cancel() }
        }
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
