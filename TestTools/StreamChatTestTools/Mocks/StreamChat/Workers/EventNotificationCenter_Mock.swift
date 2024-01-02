//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// Mock implementation of `EventNotificationCenter`
final class EventNotificationCenter_Mock: EventNotificationCenter {

    override var newMessageIds: Set<MessageId> {
        newMessageIdsMock ?? super.newMessageIds
    }

    var newMessageIdsMock: Set<MessageId>?

    lazy var mock_process = MockFunc<([Event], Bool, (() -> Void)?), Void>.mock(for: process)
    var mock_processCalledWithEvents: [Event] = []

    override func process(
        _ events: [Event],
        postNotifications: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        super.process(events, postNotifications: postNotifications, completion: completion)
        
        mock_processCalledWithEvents = events
        mock_process.call(with: (events, postNotifications, completion))
    }
}
