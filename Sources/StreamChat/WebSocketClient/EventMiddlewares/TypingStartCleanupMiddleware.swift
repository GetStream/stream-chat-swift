//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension TimeInterval {
    /// The maximum time the incoming `typingStart` event is valid before a `typingStop` event is emitted automatically.
    static let incomingTypingStartEventTimeout: TimeInterval = 30
}

/// Automatically sends a `TypingStop` event if it hasn't come in a specified time after `TypingStart`.
class TypingStartCleanupMiddleware<ExtraData: ExtraDataTypes>: EventMiddleware {
    /// A closure to get a list of user ids to skip typing events for them.
    let excludedUserIds: () -> Set<UserId>
    /// A timer type.
    var timer: Timer.Type = DefaultTimer.self
    
    /// A list of timers per user id.
    @Atomic private var typingEventTimeoutTimerControls: [UserId: TimerControl] = [:]
    
    /// Creates a new `TypingStartCleanupMiddleware`
    ///
    /// - Parameter excludedUsers: A set of users for which the `typingStart` event shouldn't be cleaned up automatically.
    init(excludedUserIds: @escaping () -> Set<UserId>) {
        self.excludedUserIds = excludedUserIds
    }
    
    func handle(event: Event, completion: @escaping (Event?) -> Void) {
        defer { completion(event) }
        
        // Skip other events and typing events from `excludedUserIds`.
        guard let typingEvent = event as? TypingEvent, excludedUserIds().contains(typingEvent.userId) == false else {
            return
        }
        
        guard typingEvent.isTyping else {
            // User stops typing.
            _typingEventTimeoutTimerControls {
                $0[typingEvent.userId]?.cancel()
                $0[typingEvent.userId] = nil
            }
            return
        }
        
        // User is typing.
        let userId = typingEvent.userId
        _typingEventTimeoutTimerControls.mutate { typingEventTimeoutTimerControls in

            typingEventTimeoutTimerControls[userId]?.cancel()

            let stopTypingEventTimerControl =
                timer.schedule(timeInterval: .incomingTypingStartEventTimeout, queue: .global()) {
                    let typingStopEvent = TypingEvent(isTyping: false, cid: typingEvent.cid, userId: userId)
                    completion(typingStopEvent)
                }
            
            typingEventTimeoutTimerControls[userId] = stopTypingEventTimerControl
        }
    }
}
