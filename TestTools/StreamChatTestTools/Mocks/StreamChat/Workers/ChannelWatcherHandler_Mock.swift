//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of ChannelWatcherHandling
final class ChannelWatcherHandler_Mock: ChannelWatcherHandling, Spy {
    let spyState = SpyState()
    
    var attemptToWatch_callCount = 0
    @Atomic var attemptToWatch_channelIds: [ChannelId] = []
    @Atomic var attemptToWatch_completion: ((Error?) -> Void)?
    var attemptToWatch_completion_success = false
    
    func cleanUp() {
        attemptToWatch_callCount = 0
        attemptToWatch_channelIds.removeAll()
        attemptToWatch_completion = nil
        attemptToWatch_completion_success = false
    }
    
    func attemptToWatch(channelIds: [ChannelId], completion: ((Error?) -> Void)?) {
        record()
        attemptToWatch_callCount += 1
        attemptToWatch_channelIds = channelIds
        if attemptToWatch_completion_success {
            completion?(nil)
        } else {
            attemptToWatch_completion = completion
        }
    }
}
