//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

extension TimeInterval {
    /// The number of seconds from the last `typingStart` event until the `typingStop` event is automatically sent.
    static let startTypingEventTimeout: TimeInterval = 7
    
    /// If the user is typing too long, `EventSender` should resend the `.typingStart` event.
    /// It should be before `.startTypingEventTimeout` and after `.startTypingEventTimeout` will be sent the stop typing event.
    static let startTypingResendInterval: TimeInterval = .incomingTypingStartEventTimeout - .startTypingEventTimeout
}

/// Struct for storing currently typing info.
private struct TypingInfo {
    let channelId: ChannelId
    let parentMessageId: MessageId?
}

/// Sends typing events.
class TypingEventsSender: Worker {
    /// A timer type.
    var timer: Timer.Type = DefaultTimer.self
    /// `TypingInfo` for channel (and parent message) that typing has occurred in. Stored to stop typing when `TypingEventsSender` is deallocated
    private var typingInfo: TypingInfo?
    
    @Atomic private var currentUserTypingTimerControl: TimerControl?
    @Atomic private var currentUserLastTypingDate: Date?
    
    deinit {
        // We need to cleanup the typing state when sender is deallocated
        guard let typingInfo = typingInfo else {
            log.info("There is no typingInfo, skipping stopTyping on deinit.")
            return
        }
        // We don't need to send `stopTyping` event if it's been already sent
        guard currentUserLastTypingDate != nil else { return }
        self.stopTyping(in: typingInfo.channelId, parentMessageId: typingInfo.parentMessageId)
    }
    
    // MARK: Typing events
    
    func keystroke(in cid: ChannelId, parentMessageId: MessageId?, completion: ((Error?) -> Void)? = nil) {
        cancelScheduledTypingTimerControl()
        
        currentUserTypingTimerControl = timer.schedule(timeInterval: .startTypingEventTimeout, queue: .main) { [weak self] in
            self?.stopTyping(in: cid, parentMessageId: parentMessageId)
        }
        
        // If the user is typing too long, it should resend `.typingStart` event.
        // Checks the last typing time and returns if it was less than `.startTypingResendInterval`.
        if let lastTypingDate = currentUserLastTypingDate,
           timer.currentTime().timeIntervalSince(lastTypingDate) < .startTypingResendInterval {
            completion?(nil)
            return
        }
        
        startTyping(in: cid, parentMessageId: parentMessageId)
    }
    
    func startTyping(in cid: ChannelId, parentMessageId: MessageId?, completion: ((Error?) -> Void)? = nil) {
        typingInfo = .init(channelId: cid, parentMessageId: parentMessageId)
        currentUserLastTypingDate = timer.currentTime()
        
        apiClient.request(
            endpoint: .startTypingEvent(cid: cid, parentMessageId: parentMessageId)
        ) {
            completion?($0.error)
        }
    }
    
    func stopTyping(in cid: ChannelId, parentMessageId: MessageId?, completion: ((Error?) -> Void)? = nil) {
        // If there's a timer set, we clear it
        if currentUserLastTypingDate != nil {
            cancelScheduledTypingTimerControl()
            currentUserLastTypingDate = nil
        }
        
        typingInfo = nil
        
        apiClient.request(
            endpoint: .stopTypingEvent(cid: cid, parentMessageId: parentMessageId)
        ) {
            completion?($0.error)
        }
    }
    
    private func cancelScheduledTypingTimerControl() {
        currentUserTypingTimerControl?.cancel()
        currentUserTypingTimerControl = nil
    }
}
