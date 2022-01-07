//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type is designed to observe events conforming to `Event` protocol delivered via `NotificationCenter`
class EventObserver {
    private let stopObserving: () -> Void

    init<EventType>(
        notificationCenter: NotificationCenter,
        transform: @escaping (Event) -> EventType?,
        callback: @escaping (EventType) -> Void
    ) {
        let observer = notificationCenter.addObserver(forName: .NewEventReceived, object: nil, queue: nil) {
            guard let event = $0.event.flatMap(transform) else { return }
            callback(event)
        }

        stopObserving = { [weak notificationCenter] in
            notificationCenter?.removeObserver(observer)
        }
    }

    deinit {
        stopObserving()
    }
}
