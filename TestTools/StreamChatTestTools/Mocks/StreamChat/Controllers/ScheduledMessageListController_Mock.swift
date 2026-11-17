//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

class ScheduledMessageListController_Mock: ScheduledMessageListController, @unchecked Sendable {
    static func mock(
        query: ScheduledMessageListQuery = .init(),
        client: ChatClient? = nil
    ) -> ScheduledMessageListController_Mock {
        .init(query: query, client: client ?? .mock())
    }

    var scheduledMessages_mock: [ScheduledMessage]?
    override var scheduledMessages: [ScheduledMessage] {
        scheduledMessages_mock ?? super.scheduledMessages
    }

    var hasLoadedAllScheduledMessages_mock: Bool?
    override var hasLoadedAllScheduledMessages: Bool {
        hasLoadedAllScheduledMessages_mock ?? super.hasLoadedAllScheduledMessages
    }

    var synchronize_completion: (@MainActor (Error?) -> Void)?
    var synchronize_callCount = 0
    override func synchronize(_ completion: (@MainActor (Error?) -> Void)? = nil) {
        synchronize_callCount += 1
        synchronize_completion = completion
    }

    var loadMoreScheduledMessages_completion: (@MainActor (Result<[ScheduledMessage], Error>) -> Void)?
    var loadMoreScheduledMessages_callCount = 0
    override func loadMoreScheduledMessages(
        limit: Int? = nil,
        completion: (@MainActor (Result<[ScheduledMessage], Error>) -> Void)? = nil
    ) {
        loadMoreScheduledMessages_callCount += 1
        loadMoreScheduledMessages_completion = completion
    }
}
