//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
    /// A closure to get a list of user ids to skip typing events for them.
    let excludedUserIds: () -> Set<UserId>
    /// A timer type.
    var timer: Timer.Type = DefaultTimer.self
    
    /// A list of timers per user id.
    @Atomic private var typingEventTimeoutTimerControls: [UserId: TimerControl] = [:]
    
    /// Creates a new `TypingStartCleanupMiddleware`
    ///
    /// - Parameter excludedUsers: A set of users for which the `typingStart` event shouldn't be cleaned up automatically.
    init(excludedUserIds: @escaping () -> Set<UserId>, emitEvent: @escaping (Event) -> Void) {
        self.excludedUserIds = excludedUserIds
        self.emitEvent = emitEvent
    }

    func handle(event: Event, session: DatabaseSession) -> Event? {
        // Skip other events and typing events from `excludedUserIds`.
        guard let typingEvent = event as? TypingEvent, excludedUserIds().contains(typingEvent.userId) == false else {
            return event
        }

        _typingEventTimeoutTimerControls {
            $0[typingEvent.userId]?.cancel()
            $0[typingEvent.userId] = nil

            guard typingEvent.isTyping else { return }

            let stopTyping = { [emitEvent] in
                let typingStopEvent = CleanUpTypingEvent(cid: typingEvent.cid, userId: typingEvent.userId)
                emitEvent(typingStopEvent)
            }

            $0[typingEvent.userId] = timer.schedule(
                timeInterval: .incomingTypingStartEventTimeout,
                queue: .global(),
                onFire: stopTyping
            )
        }

        return event
    }
}
