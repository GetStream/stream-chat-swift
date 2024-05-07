//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat

@available(iOS 13.0, *)
extension EventNotificationCenter {
    func subscribe<E>(to event: E.Type, filter: @escaping (E) -> Bool = { _ in true }, handler: @escaping (E) -> Void) -> AnyCancellable where E: Event {
        publisher(for: .NewEventReceived)
            .compactMap { $0.event as? E }
            .filter(filter)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
    }
    
    func subscribe(filter: @escaping (Event) -> Bool = { _ in true }, handler: @escaping (Event) -> Void) -> AnyCancellable {
        publisher(for: .NewEventReceived)
            .compactMap(\.event)
            .filter(filter)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
    }
    
    static func channelFilter(cid: ChannelId, event: Event) -> Bool {
        switch event {
        case let channelEvent as ChannelSpecificEvent:
            return channelEvent.cid == cid
        case let channelEvent as UnknownChannelEvent:
            return channelEvent.cid == cid
        default:
            return false
        }
    }
}
