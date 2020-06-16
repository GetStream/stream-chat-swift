//
// TypingStartCleanupMiddleware.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// Automatically sends a `TypingStop` event if it hasn't come in a specified time after `TypingStart`.
class TypingStartCleanupMiddleware<ExtraData: ExtraDataTypes>: EventMiddleware {
    /// The maximum time the incoming `typingStart` event is valid before a `typingStop` event is emitted automatically.
    static var incomingTypingStartEventTimeout: TimeInterval { 30 }
    
    /// Creates a new `TypingStartCleanupMiddleware`
    ///
    /// - Parameter excludedUsers: A set of users for which the `typingStart` event shouldn't be cleaned up automatically.
    init(excludedUsers: Set<UserModel<ExtraData.User>>) {
        self.excludedUsers = excludedUsers
    }
    
    let excludedUsers: Set<UserModel<ExtraData.User>>
    
    var typingEventTimeoutTimerControls: [UserModel<ExtraData.User>: TimerControl] = [:]
    var timer: Timer.Type = DefaultTimer.self
    
    func handle(event: Event, completion: @escaping (Event?) -> Void) {
        switch event {
        case let event as TypingStop<ExtraData> where excludedUsers.contains(event.user) == false:
            typingEventTimeoutTimerControls[event.user]?.cancel()
            typingEventTimeoutTimerControls[event.user] = nil
            
        case let event as TypingStart<ExtraData> where excludedUsers.contains(event.user) == false:
            let user = event.user
            typingEventTimeoutTimerControls[user]?.cancel()
            
            let stopTypingEventTimerControl = timer.schedule(timeInterval: Self.incomingTypingStartEventTimeout, queue: .global()) {
                let typingStopEvent = TypingStop<ExtraData>(user: user)
                completion(typingStopEvent)
            }
            
            typingEventTimeoutTimerControls[user] = stopTypingEventTimerControl
            
        default: break
        }
        
        completion(event)
    }
}
