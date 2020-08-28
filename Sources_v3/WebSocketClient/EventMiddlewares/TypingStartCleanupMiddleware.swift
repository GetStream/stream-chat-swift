//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// Automatically sends a `TypingStop` event if it hasn't come in a specified time after `TypingStart`.
class TypingStartCleanupMiddleware<ExtraData: ExtraDataTypes>: EventMiddleware {
    /// The maximum time the incoming `typingStart` event is valid before a `typingStop` event is emitted automatically.
    static var incomingTypingStartEventTimeout: TimeInterval { 30 }
    
    let excludedUserIds: () -> Set<UserId>
    var typingEventTimeoutTimerControls: [UserId: TimerControl] = [:]
    var timer: Timer.Type = DefaultTimer.self
    
    /// Creates a new `TypingStartCleanupMiddleware`
    ///
    /// - Parameter excludedUsers: A set of users for which the `typingStart` event shouldn't be cleaned up automatically.
    init(excludedUserIds: @escaping () -> Set<UserId>) {
        self.excludedUserIds = excludedUserIds
    }
    
    func handle(event: Event, completion: @escaping (Event?) -> Void) {
        switch event {
        case let event as TypingEvent where !event.isTyping && excludedUserIds().contains(event.userId) == false:
            typingEventTimeoutTimerControls[event.userId]?.cancel()
            typingEventTimeoutTimerControls[event.userId] = nil
            
        case let event as TypingEvent where event.isTyping && excludedUserIds().contains(event.userId) == false:
            let userId = event.userId
            typingEventTimeoutTimerControls[userId]?.cancel()
            
            let stopTypingEventTimerControl =
                timer.schedule(timeInterval: Self.incomingTypingStartEventTimeout, queue: .global()) {
                    let typingStopEvent = TypingEvent(isTyping: false, cid: event.cid, userId: userId)
                    completion(typingStopEvent)
                }
            
            typingEventTimeoutTimerControls[userId] = stopTypingEventTimerControl
            
        default: break
        }
        
        completion(event)
    }
}
