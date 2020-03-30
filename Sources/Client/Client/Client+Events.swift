//
//  Client+Events.swift
//  StreamChatClient
//
//  Created by Bahadir Oncel on 30.03.2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// Reference for the subscription initiated. Call `cancel()` to end subscription.
public struct Subscription {
    private let onCancel: (String) -> ()
    let uuid: String
    
    init(onCancel: @escaping (String) -> ()) {
        self.onCancel = onCancel
        uuid = UUID().uuidString
    }
    
    /// Cancel the underlying subscription for this object.
    public func cancel() {
        onCancel(uuid)
    }
}

extension Client {
    /// Observe events for the given event types.
    /// - Parameters:
    ///   - eventTypes: A set of event types to be observed. Defaults to all events.
    ///   - callback: Callback closure to be called for each new event.
    /// - Returns: `Subscription` object to be able to cancel observing. Call `subscription.cancel()` when you want to stop observing.
    /// - Warning: Subscriptions do not cancel on `deinit` and that can cause crashes / memory leaks, so make sure you handle subscriptions correctly.
    public func subscribe(forEvents eventTypes: Set<EventType> = Set(EventType.allCases), _ callback: @escaping OnEvent) -> Subscription {
        subscribe(forEvents: eventTypes, cid: nil, callback)
    }
    
    func subscribe(forEvents eventTypes: Set<EventType> = Set(EventType.allCases), cid: ChannelId?, _ callback: @escaping OnEvent) -> Subscription {
        let subscription = Subscription { [unowned self] uuid in
            self.eventHandlingQueue.async {
                self.onEventObservers[uuid] = nil
            }
        }
        
        let handler: OnEvent = { event in
            guard eventTypes.contains(event.type) else {
                return
            }
            
            if let cid = cid, event.cid != cid {
                return
            }
            
            callback(event)
        }
        
        onEventObservers[subscription.uuid] = handler
        
        return subscription
    }
}
