//
//  Channel+Events.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 08/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Events

public extension Channel {
    
    /// An observable channel event by event type.
    ///
    /// - Parameter eventType: an event type.
    /// - Returns: an observable event.
    func onEvent(_ eventType: EventType? = nil) -> Observable<Event> {
        return Client.shared.webSocket.response
            .filter { [weak self] in
                if let self = self, let channelId = $0.channelId {
                    return self.id == channelId
                }
                
                return false
            }
            .map { $0.event }
            .filter {
                if let eventType = eventType {
                    return eventType == $0.type
                }
                
                return true
            }
            .share()
    }
}
