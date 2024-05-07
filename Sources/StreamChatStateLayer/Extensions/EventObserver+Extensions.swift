//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat

@available(iOS 13.0, *)
extension EventObserver {
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
}
