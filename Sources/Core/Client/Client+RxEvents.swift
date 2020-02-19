//
//  Client+RxEvents.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 08/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift

// MARK: Client Rx Events

public extension Reactive where Base == Client {
    
    /// Observe events with a given event type.
    /// - Parameter eventType: an event type.
    /// - Returns: an observable event.
    func onEvent(eventType: EventType) -> Observable<StreamChatClient.Event> {
        onEventConnected(eventTypes: [eventType])
    }
    
    /// Observe events with a given even types.
    /// - Parameter eventTypes: event types.
    /// - Returns: an observable events.
    func onEvent(eventTypes: [EventType] = []) -> Observable<StreamChatClient.Event> {
        onEventConnected(eventTypes: eventTypes)
    }
    
    /// Observe events with a given event type and channel.
    /// - Parameters:
    ///   - eventType: an event type.
    ///   - channel: a channel.
    /// - Returns: an observable channel events.
    func onEvent(eventType: EventType, channel: Channel) -> Observable<StreamChatClient.Event> {
        onEventConnected(eventTypes: [eventType], channel: channel)
    }
    
    /// Observe events with a given event types and channel.
    /// - Parameters:
    ///   - eventTypes: event types.
    ///   - channel: a channel.
    /// - Returns: an observable channel events.
    func onEvent(eventTypes: [EventType] = [], channel: Channel) -> Observable<StreamChatClient.Event> {
        onEventConnected(eventTypes: eventTypes, channel: channel)
    }
}

// MARK: Private Client Rx Events

extension Client {
    fileprivate static var rxOnTokenChange: UInt8 = 0
    fileprivate static var rxOnConnect: UInt8 = 0
    fileprivate static var rxOnEvent: UInt8 = 0
    fileprivate static var rxOnUserUpdate: UInt8 = 0
}

extension Reactive where Base == Client {
    
    var onTokenChange: Observable<Token?> {
        associated(to: base, key: &Client.rxOnTokenChange) { [unowned base] in
            Observable<Token?>.create({ observer in
                base.onTokenChange = { observer.onNext($0) }
                return Disposables.create()
            })
                .startWith(base.token)
                .share(replay: 1)
        }
    }
    
    var onConnect: Observable<Connection> {
        associated(to: base, key: &Client.rxOnConnect) { [unowned base] in
            Observable<Connection>.create({ observer in
                base.onConnect = { observer.onNext($0) }
                return Disposables.create()
            })
                .startWith(base.connection)
                .share()
        }
    }
    
    var onEvent: Observable<StreamChatClient.Event> {
        associated(to: base, key: &Client.rxOnEvent) { [unowned base] in
            Observable<StreamChatClient.Event>.create({ observer in
                base.onEvent = { observer.onNext($0) }
                return Disposables.create()
            }).share()
        }
    }
    
    var onUserUpdate: Observable<User> {
        associated(to: base, key: &Client.rxOnUserUpdate) { [unowned base] in
            Observable<StreamChatClient.User>.create({ observer in
                base.onUserUpdate = { observer.onNext($0) }
                return Disposables.create()
            })
                .startWith(base.user)
                .share(replay: 1)
        }
    }
    
    func onEventConnected(eventTypes: [EventType], channel: Channel? = nil) -> Observable<StreamChatClient.Event> {
        connection
            .filter({ $0.isConnected })
            .flatMapLatest { [unowned base] _ in base.rx.onEvent }
            .filter({ [weak channel] in
                if !eventTypes.isEmpty, !eventTypes.contains($0.type) {
                    return false
                }
                
                if let cid = channel?.cid {
                    return cid == $0.cid
                }
                
                return true
            })
            .share()
    }
}
