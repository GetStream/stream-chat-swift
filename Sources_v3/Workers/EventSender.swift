//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

extension TimeInterval {
    /// The number of seconds from the last `typingStart` event until the `typingStop` event is automatically sent.
    static let startTypingEventTimeout: TimeInterval = 5
    
    /// If user is still typing, resend the `typingStart` event after this time interval.
    static let startTypingResendInterval: TimeInterval = 20
}

/// Sends events.
class EventSender<ExtraData: ExtraDataTypes>: Worker {
    /// A timer type.
    var timer: Timer.Type = DefaultTimer.self
    
    @Atomic private var currentUserTypingTimerControl: TimerControl?
    @Atomic private var currentUserTypingLastDate: Date?
    
    // MARK: Typing events
    
    func keystroke(in cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        cancelScheduledTypingTimerControl()
        
        currentUserTypingTimerControl = timer.schedule(timeInterval: .startTypingEventTimeout, queue: .main) { [weak self] in
            self?.cancelScheduledTypingTimerControl()
            self?.stopTyping(in: cid)
        }
        
        // The user is typing too long, we should resend `.typingStart` event.
        if let lastDate = currentUserTypingLastDate,
            timer.currentTime().timeIntervalSince(lastDate) < .startTypingResendInterval {
            completion?(nil)
            return
        }
        
        currentUserTypingLastDate = timer.currentTime()
        
        apiClient.request(
            endpoint: .event(cid: cid, eventType: .userStartTyping)
        ) { (result: Result<EventPayload<ExtraData>, Error>) in
            completion?(result.error)
        }
    }
    
    func stopTyping(in cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        guard currentUserTypingLastDate != nil else {
            completion?(nil)
            return
        }
        
        cancelScheduledTypingTimerControl()
        currentUserTypingLastDate = nil
        
        apiClient.request(
            endpoint: .event(cid: cid, eventType: .userStopTyping)
        ) { (result: Result<EventPayload<ExtraData>, Error>) in
            completion?(result.error)
        }
    }
    
    func cancelScheduledTypingTimerControl() {
        currentUserTypingTimerControl?.cancel()
        currentUserTypingTimerControl = nil
    }
}
