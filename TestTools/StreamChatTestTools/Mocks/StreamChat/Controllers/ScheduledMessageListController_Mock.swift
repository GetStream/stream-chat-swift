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

    @Atomic var scheduledMessages_mock: [ScheduledMessage]?
    override var scheduledMessages: [ScheduledMessage] {
        scheduledMessages_mock ?? super.scheduledMessages
    }

    @Atomic var hasLoadedAllScheduledMessages_mock: Bool?
    override var hasLoadedAllScheduledMessages: Bool {
        hasLoadedAllScheduledMessages_mock ?? super.hasLoadedAllScheduledMessages
    }

    @Atomic var state_mock: State?
    override var state: DataController.State {
        get { state_mock ?? super.state }
        set { super.state = newValue }
    }

    @Atomic var synchronize_completion: (@MainActor (Error?) -> Void)?
    @Atomic var synchronize_callCount = 0
    override func synchronize(_ completion: (@MainActor (Error?) -> Void)? = nil) {
        synchronize_callCount += 1
        synchronize_completion = completion
    }

    @Atomic var loadMoreScheduledMessages_completion: (@MainActor (Result<[ScheduledMessage], Error>) -> Void)?
    @Atomic var loadMoreScheduledMessages_callCount = 0
    override func loadMoreScheduledMessages(
        limit: Int? = nil,
        completion: (@MainActor (Result<[ScheduledMessage], Error>) -> Void)? = nil
    ) {
        loadMoreScheduledMessages_callCount += 1
        loadMoreScheduledMessages_completion = completion
    }

    @Atomic var deleteScheduledMessage_id: String?
    @Atomic var deleteScheduledMessage_completion: (@MainActor (Error?) -> Void)?
    @Atomic var deleteScheduledMessage_callCount = 0
    override func deleteScheduledMessage(id: String, completion: (@MainActor (Error?) -> Void)? = nil) {
        deleteScheduledMessage_callCount += 1
        deleteScheduledMessage_id = id
        deleteScheduledMessage_completion = completion
    }

    @Atomic var rescheduleMessage_id: String?
    @Atomic var rescheduleMessage_scheduledAt: Date?
    @Atomic var rescheduleMessage_completion: (@MainActor (Result<ScheduledMessage, Error>) -> Void)?
    @Atomic var rescheduleMessage_callCount = 0
    override func rescheduleMessage(
        id: String,
        scheduledAt: Date,
        completion: (@MainActor (Result<ScheduledMessage, Error>) -> Void)? = nil
    ) {
        rescheduleMessage_callCount += 1
        rescheduleMessage_id = id
        rescheduleMessage_scheduledAt = scheduledAt
        rescheduleMessage_completion = completion
    }

    @Atomic var sendScheduledMessageNow_id: String?
    @Atomic var sendScheduledMessageNow_completion: (@MainActor (Error?) -> Void)?
    @Atomic var sendScheduledMessageNow_callCount = 0
    override func sendScheduledMessageNow(id: String, completion: (@MainActor (Error?) -> Void)? = nil) {
        sendScheduledMessageNow_callCount += 1
        sendScheduledMessageNow_id = id
        sendScheduledMessageNow_completion = completion
    }
}
