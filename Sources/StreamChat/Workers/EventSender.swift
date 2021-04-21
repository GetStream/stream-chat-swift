//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension TimeInterval {
    /// The number of seconds from the last `typingStart` event until the `typingStop` event is automatically sent.
    static let startTypingEventTimeout: TimeInterval = 5
    
    /// If the user is typing too long, `EventSender` should resend the `.typingStart` event.
    /// It should be before `.startTypingEventTimeout` and after `.startTypingEventTimeout` will be sent the stop typing event.
    static let startTypingResendInterval: TimeInterval = .incomingTypingStartEventTimeout - .startTypingEventTimeout
}

/// Sends events.
class EventSender<ExtraData: ExtraDataTypes>: Worker {
    /// A timer type.
    var timer: Timer.Type = DefaultTimer.self
    
    @Atomic private var currentUserTypingTimerControl: TimerControl?
    @Atomic private var currentUserLastTypingDate: Date?
    
    // MARK: Typing events
    
    func keystroke(in cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        cancelScheduledTypingTimerControl()
        
        currentUserTypingTimerControl = timer.schedule(timeInterval: .startTypingEventTimeout, queue: .main) { [weak self] in
            self?.cancelScheduledTypingTimerControl()
            self?.stopTyping(in: cid)
        }
        
        // If the user is typing too long, it should resend `.typingStart` event.
        // Checks the last typing time and returns if it was less then `.startTypingResendInterval`.
        if let lastTypingDate = currentUserLastTypingDate,
           timer.currentTime().timeIntervalSince(lastTypingDate) < .startTypingResendInterval {
            completion?(nil)
            return
        }
        
        currentUserLastTypingDate = timer.currentTime()
        startTyping(in: cid)
    }
    
    func startTyping(in cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(
            endpoint: .sendEvent(cid: cid, eventType: .userStartTyping)
        ) {
            completion?($0.error)
        }
    }
    
    func stopTyping(in cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        guard currentUserLastTypingDate != nil else {
            completion?(nil)
            return
        }
        
        cancelScheduledTypingTimerControl()
        currentUserLastTypingDate = nil
        
        apiClient.request(
            endpoint: .sendEvent(cid: cid, eventType: .userStopTyping)
        ) {
            completion?($0.error)
        }
    }
    
    private func cancelScheduledTypingTimerControl() {
        currentUserTypingTimerControl?.cancel()
        currentUserTypingTimerControl = nil
    }
}
