//
//  Client+Events.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 08/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Events

public extension Client {
    
    /// An observable event by event type.
    ///
    /// - Parameters:
    ///     - eventType: an event type.
    ///     - channelId: a channeld id (optional).
    /// - Returns: an observable event.
    func onEvent(_ eventType: EventType? = nil, for channelId: String? = nil) -> Observable<Event> {
        return webSocket.response
            .filter {
                if let channelId = channelId {
                    if let eventChannelId = $0.channelId {
                        return channelId == eventChannelId
                    }
                    
                    return false
                }
                
                return true
            }
            .map { $0.event }
            .filter {
                if let eventType = eventType {
                    return $0.type == eventType
                }
                
                return $0.type != .healthCheck
            }
            .share()
    }
}
