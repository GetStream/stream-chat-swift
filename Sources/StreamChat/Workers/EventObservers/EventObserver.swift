//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
    
    @available(iOS 13.0, *)
    convenience init<EventType>(
        notificationCenter: NotificationCenter,
        transform: @escaping (Event) -> EventType?,
        callback: @escaping (EventType) async throws -> Void
    ) {
        self.init(notificationCenter: notificationCenter, transform: transform) { event in
            Task {
                do {
                    try await callback(event)
                } catch {
                    log.debug("Event observer failed to handle event \(event) with error \(error)")
                }
            }
        }
    }

    deinit {
        stopObserving()
    }
}
