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
    func onEvent(_ eventType: EventType, for channelId: String? = nil) -> Observable<Event> {
        return connection.connected()
            .flatMapLatest { [weak self] in self?.webSocket.response ?? .empty() }
            .filter {
                if let channelId = channelId {
                    return channelId == $0.channelId
                }
                
                return true
            }
            .map { $0.event }
            .filter { $0.type == eventType }
            .share()
    }
}
