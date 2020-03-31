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
    private let onCancel: (String) -> ()
    let uuid: String
    
    init(onCancel: @escaping (String) -> ()) {
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
    
    public func cancel() {
        subscriptions.forEach { $0.cancel() }
    }
}

extension Client {
    /// Observe events for the given event types.
    /// - Parameters:
    ///   - eventTypes: A set of event types to be observed. Defaults to all events.
    ///   - callback: Callback closure to be called for each new event.
    /// - Returns: `Subscription` object to be able to cancel observing. Call `subscription.cancel()` when you want to stop observing.
    /// - Warning: Subscriptions do not cancel on `deinit` and that can cause crashes / memory leaks, so make sure you handle subscriptions correctly.
    public func subscribe(forEvents eventTypes: Set<EventType> = Set(EventType.allCases), _ callback: @escaping OnEvent) -> Cancellable {
        subscribe(forEvents: eventTypes, cid: nil, callback)
    }
    
    func subscribe(forEvents eventTypes: Set<EventType> = Set(EventType.allCases), cid: ChannelId?, _ callback: @escaping OnEvent) -> Cancellable {
        let handler: OnEvent = { event in
            if let cid = cid, event.cid != cid {
                return
            }
            
            callback(event)
        }
        
        return webSocket.subscribe(forEvents: eventTypes, callback: handler)
    }
    
    public func subscribeToUserUpdates(_ callback: @escaping OnUpdate<User>) -> Cancellable {
        let subscription = Subscription { [unowned self] uuid in
            self.userUpdateHandlingQueue.async {
                self.onUserUpdateObservers[uuid] = nil
            }
        }
        
        onUserUpdateObservers[subscription.uuid] = callback
        
        return subscription
    }
    
    public func subscribeToUnreadCount(_ callback: @escaping OnUpdate<UnreadCount>) -> Cancellable {
        subscribeToUserUpdates { user in callback(user.unreadCount) }
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
        
        subscriptions.add(Subscription { _ in urlSessionTask.cancel() })
        
        return subscriptions
    }
    
    func subscribeToWatcherCount(for channel: Channel, _ callback: @escaping Completion<Int>) -> Cancellable {
        let subscriptions = SubscriptionBag()
        
        let query = ChannelQuery(channel: channel, messagesPagination: .limit(1), options: [.state, .watch])
        
        let urlSessionTask = queryChannel(query: query) { [unowned self] result in
            if let error = result.error {
                callback(.failure(error))
            }
            
            if let response = result.value {
                let subscription = self.subscribe(forEvents: [.userStartWatching,
                                                              .userStopWatching,
                                                              .messageNew,
                                                              .notificationMessageNew],
                                                  cid: response.channel.cid) { _ in
                    callback(.success(channel.watcherCount))
                }
                subscriptions.add(subscription)
            }
        }
        
        subscriptions.add(Subscription { _ in urlSessionTask.cancel() })
        
        return subscriptions
    }
}
