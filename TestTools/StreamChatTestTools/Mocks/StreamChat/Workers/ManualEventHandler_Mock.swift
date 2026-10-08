//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class ManualEventHandler_Mock: ManualEventHandler, @unchecked Sendable {
    init() {
        super.init()
    }

    static func mock() -> Self {
        Self()
    }

    var registerCallCount = 0
    var registerCalledWith: [ChannelId] = []

    override func register(channelId: ChannelId) {
        registerCallCount += 1
        registerCalledWith.append(channelId)
    }

    var unregisterCallCount = 0
    var unregisterCalledWith: [ChannelId] = []

    override func unregister(channelId: ChannelId) {
        unregisterCallCount += 1
        unregisterCalledWith.append(channelId)
    }

    var handleCallCount = 0
    var handleCalledWith: [Event] = []
    var handleReturnValue: Event?

    override func handle(_ event: Event, session: DatabaseSession) -> Event? {
        handleCallCount += 1
        handleCalledWith.append(event)
        return handleReturnValue
    }
}
