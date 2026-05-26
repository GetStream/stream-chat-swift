//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
    var timer: TimerScheduling.Type = DefaultTimer.self

    /// A list of timers per user id.
    @Atomic private var typingEventTimeoutTimerControls: [UserId: TimerControl] = [:]

    /// Creates a new `TypingStartCleanupMiddleware`
    ///
    /// - Parameter excludedUsers: A set of users for which the `typingStart` event shouldn't be cleaned up automatically.
    init(emitEvent: @escaping (Event) -> Void) {
        self.emitEvent = emitEvent
    }

    func handle(event: Event, session: DatabaseSession) -> Event? {
        let currentUserId = session.currentUser?.user.id

        if let startEvent = event as? TypingStartEventDTO {
            handle(userId: startEvent.user?.id, cidString: startEvent.cid, isStart: true, currentUserId: currentUserId)
        } else if let stopEvent = event as? TypingStopEventDTO {
            handle(userId: stopEvent.user?.id, cidString: stopEvent.cid, isStart: false, currentUserId: currentUserId)
        }

        return event
    }

    private func handle(userId: UserId?, cidString: String?, isStart: Bool, currentUserId: UserId?) {
        guard let userId, currentUserId != userId else { return }

        _typingEventTimeoutTimerControls.mutate {
            $0[userId]?.cancel()
            $0[userId] = nil

            guard isStart, let cidString, let cid = try? ChannelId(cid: cidString) else { return }

            $0[userId] = timer.schedule(
                timeInterval: .incomingTypingStartEventTimeout,
                queue: .global(),
                onFire: { [weak self] in
                    let typingStopEvent = CleanUpTypingEvent(cid: cid, userId: userId)
                    self?.emitEvent(typingStopEvent)
                }
            )
        }
    }
}
