//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension TimeInterval {
    /// The maximum time the incoming `typingStart` event is valid before a `typingStop` event is emitted automatically.
    static let incomingTypingStartEventTimeout: TimeInterval = 30
}

/// Automatically sends a `TypingStop` event if it hasn't come in a specified time after `TypingStart`.
class TypingStartCleanupMiddleware: EventMiddleware {
    /// A closure that will be invoked with `stop typing` event when the `incomingTypingStartEventTimeout` has passed
    /// after `start typing` event.
    let emitEvent: (Event) -> Void
    /// A timer type.
    var timer: Timer.Type = DefaultTimer.self

    /// A list of timers per user id.
    @Atomic private var typingEventTimeoutTimerControls: [UserId: TimerControl] = [:]

    /// Creates a new `TypingStartCleanupMiddleware`
    ///
    /// - Parameter excludedUsers: A set of users for which the `typingStart` event shouldn't be cleaned up automatically.
    init(emitEvent: @escaping (Event) -> Void) {
        self.emitEvent = emitEvent
    }

    func handle(event: Event, session: DatabaseSession) -> Event? {
        // Skip other events and typing events from currentUserId.
        let currentUserId = session.currentUser?.user.id
        guard let typingEvent = event as? TypingEventDTO, currentUserId != typingEvent.user.id else {
            return event
        }

        _typingEventTimeoutTimerControls {
            $0[typingEvent.user.id]?.cancel()
            $0[typingEvent.user.id] = nil

            guard typingEvent.isTyping else { return }

            let stopTyping = { [weak self] in
                let typingStopEvent = CleanUpTypingEvent(cid: typingEvent.cid, userId: typingEvent.user.id)
                self?.emitEvent(typingStopEvent)
            }

            $0[typingEvent.user.id] = timer.schedule(
                timeInterval: .incomingTypingStartEventTimeout,
                queue: .global(),
                onFire: stopTyping
            )
        }

        return event
    }
}
