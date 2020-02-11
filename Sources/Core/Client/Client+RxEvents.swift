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
    private static var rxOnTokenChange: UInt8 = 0
    private static var rxOnConnect: UInt8 = 0
    private static var rxOnEvent: UInt8 = 0
    private static var rxOnUserUpdate: UInt8 = 0
    
    fileprivate var rxOnTokenChange: Observable<Token?> {
        associated(to: self, key: &Client.rxOnTokenChange) { [unowned self] in
            Observable<Token?>.create({ [unowned self] observer in
                self.onTokenChange = { observer.onNext($0) }
                return Disposables.create()
            })
                .startWith(token)
                .share(replay: 1)
        }
    }
    
    fileprivate var rxOnConnect: Observable<Connection> {
        associated(to: self, key: &Client.rxOnConnect) { [unowned self] in
            Observable<Connection>.create({ [unowned self] observer in
                self.onConnect = { observer.onNext($0) }
                return Disposables.create()
            })
                .startWith(lastConnection)
                .share(replay: 1)
        }
    }
    
    fileprivate var rxOnEvent: Observable<StreamChatClient.Event> {
        associated(to: self, key: &Client.rxOnEvent) { [unowned self] in
            Observable<StreamChatClient.Event>.create({ observer in
                self.onEvent = { observer.onNext($0) }
                return Disposables.create()
            }).share()
        }
    }
    
    fileprivate var rxOnUserUpdate: Observable<User> {
        associated(to: self, key: &Client.rxOnUserUpdate) { [unowned self] in
            Observable<StreamChatClient.User>.create({ observer in
                self.onUserUpdate = { observer.onNext($0) }
                return Disposables.create()
            })
                .startWith(user)
                .share(replay: 1)
        }
    }
}

extension Reactive where Base == Client {
    
    var onTokenChange: Observable<Token?> { base.rxOnTokenChange }
    var onConnect: Observable<Connection> { base.rxOnConnect }
    var onEvent: Observable<StreamChatClient.Event> { base.rxOnEvent }
    var onUserUpdate: Observable<User> { base.rxOnUserUpdate }
    
    func onEventConnected(eventTypes: [EventType], channel: Channel? = nil) -> Observable<StreamChatClient.Event> {
        connection
            .filter({ $0.isConnected })
            .flatMapLatest { _ in self.onEvent }
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
