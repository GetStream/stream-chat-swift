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

extension Client {
    fileprivate static var rxOnTokenChange: UInt8 = 0
    fileprivate static var rxOnConnect: UInt8 = 0
    fileprivate static var rxOnAnyEvent: UInt8 = 0
    fileprivate static var rxOnClientEvent: UInt8 = 0
    fileprivate static var rxOnChannelEvent: UInt8 = 0
    fileprivate static var rxOnUserUpdate: UInt8 = 0
}

public extension Reactive where Base == Client {
    
    var user: Observable<User> {
        associated(to: base, key: &Client.rxOnUserUpdate) { [unowned base] in
            Observable<StreamChatClient.User>.create({ observer in
                let subscription = base.subscribeToUserUpdates { observer.onNext($0) }
                return Disposables.create { subscription.cancel() }
            })
                .share(replay: 1)
        }
    }
    
    var token: Observable<Token?> {
        associated(to: base, key: &Client.rxOnTokenChange) { [unowned base] in
            Observable<Token?>.create({ observer in
                base.onTokenChange = { observer.onNext($0) }
                return Disposables.create()
            })
                .startWith(base.token)
                .share(replay: 1)
        }
    }
    
    var connection: Observable<ConnectionState> {
        associated(to: base, key: &Client.rxOnConnect) { [unowned base] in
            clientEvents(forEvent: .connectionChanged)
                .filter { _ in !base.isExpiredTokenInProgress }
                .map({
                    if case .connectionChanged(let state) = $0 {
                        return state
                    }
                    
                    return nil
                })
                .unwrap()
                .distinctUntilChanged()
                .startWith(base.connectionState)
                .share(replay: 1)
        }
    }
    
    /// Observe the connection events and emit an event when the connection will be connected.
    var connected: Observable<Void> {
        connection.filter({ $0.isConnected }).map({ _ in Void() })
    }
    
    // MARK: - Events
    
    /// Observe all events.
    /// - Parameters:
    ///   - clientEventTypes: A set of client event types to be observed. Defaults to all client events.
    ///   - channelEventTypes: A set of channel event types to be observed. Defaults to all channel events.
    ///   - cid: a channel id.
    /// - Returns: observable client events.
    func events(forEvents clientEventTypes: Set<ClientEventType> = Set(ClientEventType.allCases),
                forChannelEvents channelEventTypes: Set<ChannelEventType> = Set(ChannelEventType.allCases),
                cid: ChannelId? = nil) -> Observable<AnyEvent> {
        associated(to: base, key: &Client.rxOnAnyEvent) { [unowned base] in
            Observable<AnyEvent>.create({ observer in
                let subscription = base.subscribe(forEvents: clientEventTypes,
                                                  forChannelEvents: channelEventTypes,
                                                  cid: cid) { observer.onNext($0) }
                return Disposables.create { subscription.cancel() }
            })
                .share()
        }
    }
    
    /// Observe client events with a given event type.
    /// - Parameter eventType: a client event type.
    /// - Returns: observable client events.
    func clientEvents(forEvent eventType: ClientEventType) -> Observable<ClientEvent> {
        clientEvents(forEvents: [eventType])
    }
    
    /// Observe all client events with given event types.
    /// - Parameter eventTypes: a client event types.
    /// - Returns: observable client events.
    func clientEvents(forEvents eventTypes: Set<ClientEventType> = Set(ClientEventType.allCases))
        -> Observable<ClientEvent> {
            associated(to: base, key: &Client.rxOnClientEvent) { [unowned base] in
                Observable<ClientEvent>.create({ observer in
                    let subscription = base.subscribe(forEvents: eventTypes) { observer.onNext($0) }
                    return Disposables.create { subscription.cancel() }
                })
                    .share()
            }
    }
    
    /// Observe channel events with a given event type and channel id.
    /// - Parameters:
    ///   - eventType: a channel event type.
    ///   - cid: a channel id.
    /// - Returns: observable channel events.
    func channelEvents(forEvent eventType: ChannelEventType, cid: ChannelId?) -> Observable<ChannelEvent> {
        channelEvents(forEvents: [eventType], cid: cid)
    }
    
    /// Observe channel events with a given event type and channel id.
    /// - Parameters:
    ///   - eventTypes: channel event types.
    ///   - cid: a channel id.
    /// - Returns: observable channel events.
    func channelEvents(forEvents eventTypes: Set<ChannelEventType> = Set(ChannelEventType.allCases),
                       cid: ChannelId? = nil) -> Observable<ChannelEvent> {
        associated(to: base, key: &Client.rxOnChannelEvent) { [unowned base] in
            Observable<ChannelEvent>.create({ observer in
                let subscription = base.subscribe(cid: cid) { observer.onNext($0) }
                return Disposables.create { subscription.cancel() }
            })
                .share()
        }
    }
}
