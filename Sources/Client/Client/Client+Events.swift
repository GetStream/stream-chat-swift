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
    typealias OnCancel = (String) -> Void
    
    /// Cancel the underlying subscription for this object.
    func cancel()
}

/// Reference for the subscription initiated. Call `cancel()` to end the subscription.
/// Alternatively, when this object is deallocated, it calls `cancel()` on itself automatically.
public protocol AutoCancellable: Cancellable {}

struct Subscription: Cancellable {
    static let empty = Subscription { _ in }
    private let onCancel: Cancellable.OnCancel
    let uuid: String
    
    init(onCancel: @escaping Cancellable.OnCancel) {
        self.onCancel = onCancel
        uuid = UUID().uuidString
    }
    
    public func cancel() {
        onCancel(uuid)
    }
}

/// A subscription bag allows you collect multiple subscriptions and cancel them at once.
public final class SubscriptionBag: Cancellable {
    private var subscriptions = [Cancellable]()
    
    /// Init a subscription bag.
    /// - Parameter onCancel: a cancel block for a subscription to put in the bag.
    public init(onCancel: Cancellable.OnCancel? = nil) {
        if let onCancel = onCancel {
            subscriptions.append(Subscription(onCancel: onCancel))
        }
    }
    
    /// Add a subscription.
    /// - Parameter subscription: a subscriiption.
    public func add(_ subscription: Cancellable) {
        subscriptions.append(subscription)
    }
    
    /// Add multiple subscriptions in a chain way.
    /// - Parameter subscription: a subscription
    /// - Returns: this subscription bag.
    @discardableResult
    public func adding(_ subscription: Cancellable) -> Self {
        add(subscription)
        return self
    }
    
    /// Cancel and clear all subscriptions in the bag.
    public func cancel() {
        subscriptions.forEach { $0.cancel() }
        subscriptions = []
    }
}

extension Client {
    
    // MARK: Events
    
    /// Observe events for the given event types.
    /// - Parameters:
    ///   - eventTypes: A set of event types to be observed. Defaults to all events.
    ///   - callback: Callback closure to be called for each new event.
    /// - Returns: `Subscription` object to be able to cancel observing.
    ///            Call `subscription.cancel()` when you want to stop observing.
    /// - Warning: Subscriptions do not cancel on `deinit` and that can cause crashes / memory leaks,
    ///            so make sure you handle subscriptions correctly.
    public func subscribe(forEvents eventTypes: Set<EventType> = Set(EventType.allCases),
                          _ callback: @escaping OnEvent) -> Cancellable {
        subscribe(forEvents: eventTypes, cid: nil, callback)
    }
    
    func subscribe(forEvents eventTypes: Set<EventType> = Set(EventType.allCases),
                   cid: ChannelId?,
                   _ callback: @escaping OnEvent) -> Cancellable {
        let handler: OnEvent = { event in
            if let cid = cid, event.cid != cid {
                return
            }
            
            callback(event)
        }
        
        return webSocket.subscribe(forEvents: eventTypes, callback: handler)
    }
    
    // MARK: - User Updates
    
    public func subscribeToUserUpdates(_ callback: @escaping OnUpdate<User>) -> Cancellable {
        let subscription = Subscription { [unowned self] uuid in
            self.eventsHandlingQueue.async {
                self.onUserUpdateObservers[uuid] = nil
            }
        }
        
        eventsHandlingQueue.async { [unowned self] in
            self.onUserUpdateObservers[subscription.uuid] = callback
            // Send the current value.
            callback(self.user)
        }
        
        return subscription
    }
    
    // MARK: - Unread Count
    
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
        // Check if current user is a member in case Channel is decoded from query
        if channel.didLoad, !channel.members.contains(Member.current) {
            logger?.log("⚠️ The current user is not a member of the channel: (\(channel.cid)). "
                + "They must be a member to get updates for the unread count.")
            return Subscription.empty
        }
        
        // Check if the channel is being watched by the client.
        guard isWatching(channel: channel) else {
            logger?.log("⚠️ You are trying to subscribe for the channel unread count: (\(channel.cid)), "
                + "but you didn't start watching it. Please make a query with "
                + "messages pagination: `[.limit(100)]` and query options: `[.watch, .state]`: "
                + "`channel.query(messagesPagination: [.limit(100)], options: [.watch, .state])`")
            return Subscription.empty
        }
        
        let subscription = subscribe(forEvents: [.messageNew, .messageRead, .messageDeleted], cid: channel.cid) { _ in
            callback(.success(channel.unreadCount))
        }
        
        // Return the current unread count immediately
        eventsHandlingQueue.async {
            callback(.success(channel.unreadCount))
        }
        
        return subscription
    }
    
    // MARK: - Watcher Count

    /// Subscribes to the watcher count for a channel that the user is watching
    func subscribeToWatcherCount(for channel: Channel, _ callback: @escaping Completion<Int>) -> Cancellable {
        let subscription = channel.subscribe(forEvents: [.userStartWatching, .userStopWatching, .messageNew], { _ in
            callback(.success(channel.watcherCount))
        })
        
        // Check if the channel is watching by the client.
        if isWatching(channel: channel) {
            callback(.success(channel.watcherCount))
        } else {
            logger?.log("⚠️ You are trying to subscribe to watcher count for the channel: (\(channel.cid)), "
                + "but you didn't start watching it. Please, make a query with "
                + "messages pagination: `[.limit(1)]` and query options: `[.watch, .state]`:"
                + "`channel.query(messagesPagination: [.limit(1)], options: [.watch, .state])`")
        }

        return subscription
    }
}
