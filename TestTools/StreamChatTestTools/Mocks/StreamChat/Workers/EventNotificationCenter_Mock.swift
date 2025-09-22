//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// Mock implementation of `EventNotificationCenter`
final class EventNotificationCenter_Mock: EventNotificationCenter, @unchecked Sendable {
    override var newMessageIds: Set<MessageId> {
        newMessageIdsMock ?? super.newMessageIds
    }

    var newMessageIdsMock: Set<MessageId>?

    lazy var mock_process = MockFunc<([Event], Bool, (@Sendable() -> Void)?), Void>.mock(for: process)
    var mock_processCalledWithEvents: [Event] = []

    var registerManualEventHandling_calledWith: ChannelId?
    var registerManualEventHandling_callCount = 0

    var unregisterManualEventHandling_calledWith: ChannelId?
    var unregisterManualEventHandling_callCount = 0

    override func registerManualEventHandling(for cid: ChannelId) {
        registerManualEventHandling_callCount += 1
        registerManualEventHandling_calledWith = cid
    }

    override func unregisterManualEventHandling(for cid: ChannelId) {
        unregisterManualEventHandling_callCount += 1
        unregisterManualEventHandling_calledWith = cid
    }

    override func process(
        _ events: [Event],
        postNotifications: Bool = true,
        completion: (@Sendable() -> Void)? = nil
    ) {
        super.process(events, postNotifications: postNotifications, completion: completion)
        
        mock_processCalledWithEvents = events
        mock_process.call(with: (events, postNotifications, completion))
    }
}
