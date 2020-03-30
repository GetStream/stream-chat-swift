//
//  Client+Events.swift
//  StreamChatClient
//
//  Created by Bahadir Oncel on 30.03.2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Subscription {
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


extension Client {
    public func subscribe(forEvents eventTypes: Set<EventType> = Set(EventType.allCases), _ callback: @escaping OnEvent) -> Subscription {
        subscribe(forEvents: eventTypes, channelId: nil, callback)
    }
    
    func subscribe(forEvents eventTypes: Set<EventType> = Set(EventType.allCases), channelId: ChannelId?, _ callback: @escaping OnEvent) -> Subscription {
        let subscription = Subscription { [unowned self] uuid in
            self.onEventObservers[uuid] = nil
        }
        
        let handler: OnEvent = { event in
            guard eventTypes.contains(event.type) && event.cid == channelId else { return }
            callback(event)
        }
        
        onEventObservers[subscription.uuid] = handler
        
        return subscription
    }
}
