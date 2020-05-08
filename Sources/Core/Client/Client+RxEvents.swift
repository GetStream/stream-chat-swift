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

extension Client: ReactiveCompatible {}

extension Reactive where Base == Client {
    
    /// Observe events with a given event type.
    /// - Parameter eventType: an event type.
    /// - Returns: an observable event.
    public func events(for type: EventType) -> Observable<StreamChatClient.Event> {
        connectedEvents(for: [type])
    }
    
    /// Observe events with a given even types.
    /// - Parameter eventTypes: event types.
    /// - Returns: an observable events.
    public func events(for types: Set<EventType> = Set(EventType.allCases)) -> Observable<StreamChatClient.Event> {
        connectedEvents(for: types)
    }
    
    /// Observe events with a given event type and channel.
    /// - Parameters:
    ///   - eventType: an event type.
    ///   - channel: a channel.
    /// - Returns: an observable channel events.
    func events(for type: EventType, cid: ChannelId) -> Observable<StreamChatClient.Event> {
        connectedEvents(for: [type], cid: cid)
    }
    
    /// Observe events with a given event types and channel.
    /// - Parameters:
    ///   - eventTypes: event types.
    ///   - channel: a channel.
    /// - Returns: an observable channel events.
    func events(for types: Set<EventType> = Set(EventType.allCases), cid: ChannelId) -> Observable<StreamChatClient.Event> {
        connectedEvents(for: types, cid: cid)
    }
}

// MARK: Private Client Rx Events

extension Client {
    fileprivate static var rxOnConnect: UInt8 = 0
    fileprivate static var rxOnEvent: UInt8 = 0
    fileprivate static var rxOnUserUpdate: UInt8 = 0
}

extension Reactive where Base == Client {
    
    /// Observe the connection state.
    public var connectionState: Observable<ConnectionState> {
        associated(to: base, key: &Client.rxOnConnect) { [unowned base] in
            base.rx.events
                .filter({ _ in !base.isExpiredTokenInProgress })
                .compactMap({
                    if case .connectionChanged(let state) = $0 {
                        return state
                    }
                    
                    return nil
                })
                .startWith(base.connectionState)
                .distinctUntilChanged()
                .share(replay: 1)
        }
    }
    
    /// Observe all events.
    public var events: Observable<StreamChatClient.Event> {
        associated(to: base, key: &Client.rxOnEvent) { [unowned base] in
            Observable<StreamChatClient.Event>.create({ observer in
                let subscription = base.subscribe { observer.onNext($0) }
                return Disposables.create { subscription.cancel() }
            })
                .share()
        }
    }
    
    public var user: Observable<User> {
        associated(to: base, key: &Client.rxOnUserUpdate) { [unowned base] in
            Observable<StreamChatClient.User>.create({ observer in
                let subscription = base.subscribeToUserUpdates { observer.onNext($0) }
                return Disposables.create { subscription.cancel() }
            })
                .share(replay: 1)
        }
    }
    
    /// Observe the connection events and emit an event when the connection will be connected.
    public var connected: Observable<Void> {
        connectionState.filter({ $0.isConnected }).map({ _ in Void() })
    }
    
    func connectedEvents(for types: Set<EventType> = Set(EventType.allCases),
                         cid: ChannelId? = nil) -> Observable<StreamChatClient.Event> {
        connectionState
            .filter({ $0.isConnected })
            .flatMapLatest { [unowned base] _ in base.rx.events }
            .filter({
                if !types.isEmpty, !types.contains($0.type) {
                    return false
                }
                
                if let cid = cid {
                    return cid == $0.cid
                }
                
                return true
            })
            .share()
    }
}
