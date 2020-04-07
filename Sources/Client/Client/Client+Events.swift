//
//  Client+Events.swift
//  StreamChatClient
//
//  Created by Bahadir Oncel on 30.03.2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// Reference for the subscription initiated. Call `cancel()` to end subscription.
public protocol Cancellable {
    /// Cancel the underlying subscription for this object.
    func cancel()
}

/// Reference for the subscription initiated. Call `cancel()` to end the subscription.
/// Alternatively, when this object is deallocated, it calls `cancel()` on itself automatically.
public protocol AutoCancellable: Cancellable {}

struct Subscription: Cancellable {
    private let onCancel: (String) -> Void
    let uuid: String
    
    init(onCancel: @escaping (String) -> Void) {
        self.onCancel = onCancel
        uuid = UUID().uuidString
    }
    
    public func cancel() {
        onCancel(uuid)
    }
}

public final class SubscriptionBag: Cancellable {
    private var subscriptions = [Cancellable]()
    
    public func add(_ subscription: Cancellable) {
        subscriptions.append(subscription)
    }
    
    @discardableResult
    public func adding(_ subscription: Cancellable) -> Self {
        add(subscription)
        return self
    }
    
    public func cancel() {
        subscriptions.forEach { $0.cancel() }
        subscriptions = []
    }
}

extension Client {
    
    /// Observe all events.
    /// - Parameters:
    ///   - eventTypes: A set of client event types to be observed. Defaults to all client events.
    ///   - channelEventTypes: A set of channel event types to be observed. Defaults to all channel events.
    ///   - cid: a channel id.
    ///   - callback: Callback closure to be called for each new event.
    /// - Returns: `Subscription` object to be able to cancel observing.
    ///            Call `subscription.cancel()` when you want to stop observing.
    /// - Warning: Subscriptions do not cancel on `deinit` and that can cause crashes / memory leaks,
    ///            so make sure you handle subscriptions correctly.
    public func subscribe(forEvents eventTypes: Set<ClientEventType> = Set(ClientEventType.allCases),
                          forChannelEvents channelEventTypes: Set<ChannelEventType> = Set(ChannelEventType.allCases),
                          cid: ChannelId? = nil,
                          _ callback: @escaping OnEvent<AnyEvent>) -> Cancellable {
        SubscriptionBag()
            .adding(subscribe(forEvents: eventTypes, { callback(.client($0)) }))
            .adding(subscribe(forChannelEvents: channelEventTypes, cid: cid, { callback(.channel($0)) }))
    }
    
    /// Observe events for the given client event types.
    /// - Parameters:
    ///   - eventTypes: A set of client event types to be observed. Defaults to all client events.
    ///   - callback: Callback closure to be called for each new event.
    /// - Returns: `Subscription` object to be able to cancel observing.
    ///            Call `subscription.cancel()` when you want to stop observing.
    /// - Warning: Subscriptions do not cancel on `deinit` and that can cause crashes / memory leaks,
    ///            so make sure you handle subscriptions correctly.
    public func subscribe(forEvents eventTypes: Set<ClientEventType> = Set(ClientEventType.allCases),
                          _ callback: @escaping OnEvent<ClientEvent>) -> Cancellable {
        webSocket.subscribe(forEvents: eventTypes, callback)
    }
    
    /// Observe events for the given channel event types.
    /// - Parameters:
    ///   - eventTypes: A set of channel event types to be observed. Defaults to all channel events.
    ///   - cid: a channel id.
    ///   - callback: Callback closure to be called for each new event.
    /// - Returns: `Subscription` object to be able to cancel observing.
    ///            Call `subscription.cancel()` when you want to stop observing.
    /// - Warning: Subscriptions do not cancel on `deinit` and that can cause crashes / memory leaks,
    ///            so make sure you handle subscriptions correctly.
    public func subscribe(forChannelEvents eventTypes: Set<ChannelEventType> = Set(ChannelEventType.allCases),
                          cid: ChannelId? = nil,
                          _ callback: @escaping OnEvent<ChannelEvent>) -> Cancellable {
        webSocket.subscribe(forEvents: eventTypes, callback)
    }
    
    public func subscribeToUserUpdates(_ callback: @escaping OnUpdate<User>) -> Cancellable {
        let subscription = Subscription { [unowned self] uuid in
            self.eventsHandlingQueue.async {
                self.onUserUpdateObservers[uuid] = nil
            }
        }
        
        eventsHandlingQueue.async { [unowned self] in
            self.onUserUpdateObservers[subscription.uuid] = callback
            
            // Send the current value.
            if !self.user.isUnknown {
                callback(self.user)
            }
        }
        
        return subscription
    }
    
    public func subscribeToUnreadCount(_ callback: @escaping OnUpdate<UnreadCount>) -> Cancellable {
        let subscription = Subscription { [unowned self] uuid in
            self.eventsHandlingQueue.async {
                self.onUnreadCountUpdateObservers[uuid] = nil
            }
        }
        
        self.eventsHandlingQueue.async { [unowned self] in
            self.onUnreadCountUpdateObservers[subscription.uuid] = callback
            // Send the current value.
            callback(self.unreadCount)
        }
        
        return subscription
    }
    
    func subscribeToUnreadCount(for channel: Channel, _ callback: @escaping Completion<ChannelUnreadCount>) -> Cancellable {
        let subscriptions = SubscriptionBag()
        
        let query = ChannelQuery(channel: channel, messagesPagination: .limit(100), options: [.state, .watch])
        
        let urlSessionTask = queryChannel(query: query) { [unowned self] result in
            if let error = result.error {
                callback(.failure(error))
            }
            
            if let response = result.value {
                let subscription = self.subscribe(cid: response.channel.cid) { _ in
                    callback(.success(channel.unreadCount))
                }
                
                subscriptions.add(subscription)
            }
        }
        
        return subscriptions.adding(Subscription { _ in urlSessionTask.cancel() })
    }
    
    func subscribeToWatcherCount(for channel: Channel, _ callback: @escaping Completion<Int>) -> Cancellable {
        let subscriptions = SubscriptionBag()
        
        let query = ChannelQuery(channel: channel, messagesPagination: .limit(1), options: [.state, .watch])
        
        let urlSessionTask = queryChannel(query: query) { [unowned self] result in
            if let error = result.error {
                callback(.failure(error))
                return
            }
            
            guard let response = result.value else {
                return
            }
            
            let channelEventTypes: Set<ChannelEventType> = [.userStartWatching, .userStopWatching, .messageNew]
            
            subscriptions
                .adding(self.subscribe(forEvents: [.notificationMessageNew]) { _ in
                    callback(.success(channel.watcherCount))
                })
                .adding(self.subscribe(forChannelEvents: channelEventTypes, cid: response.channel.cid) { _ in
                    callback(.success(channel.watcherCount))
                })
        }
        
        return subscriptions.adding(Subscription { _ in urlSessionTask.cancel() })
    }
}
