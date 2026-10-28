//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ScheduledMessageList_Tests: XCTestCase {
    private var client: ChatClient_Mock!
    private var apiClient: APIClient_Spy!
    private var cid: ChannelId!
    private var scheduledMessageList: ScheduledMessageList!

    override func setUpWithError() throws {
        client = ChatClient_Mock(config: ChatClient_Mock.defaultMockedConfig)
        apiClient = client.mockAPIClient
        cid = .unique
        let userId = UserId.unique
        client.currentUserId_mock = userId
        try client.mockDatabaseContainer.createCurrentUser(id: userId)
    }

    override func tearDownWithError() throws {
        apiClient.cleanUp()
        client.cleanUp()
        apiClient = nil
        client = nil
        cid = nil
        scheduledMessageList = nil
    }

    // MARK: - Restoring State

    @MainActor func test_restoreState_whenDatabaseHasScheduledMessages_thenStateIsUpToDate() async throws {
        let message = try await schedule()

        setUpScheduledMessageList()

        XCTAssertEqual([message.id], scheduledMessageList.state.scheduledMessages.map(\.id))
    }

    @MainActor func test_restoreState_onlyIncludesTheScheduledMessagesMatchingTheQuery() async throws {
        let message = try await schedule()
        _ = try await schedule(cid: .unique)

        setUpScheduledMessageList(query: .init(filter: .equal(.cid, to: cid)))

        XCTAssertEqual([message.id], scheduledMessageList.state.scheduledMessages.map(\.id))
    }

    // MARK: - Get

    @MainActor func test_get_thenStateHasTheLoadedScheduledMessages() async throws {
        setUpScheduledMessageList()
        apiClient.test_mockResponseResult(.success(QueryScheduledMessagesResponse(scheduledMessages: [.dummy(id: "first", cid: cid)])))

        try await scheduledMessageList.get()

        XCTAssertEqual(["first"], scheduledMessageList.state.scheduledMessages.map(\.id))
        XCTAssertTrue(scheduledMessageList.state.hasLoadedAllScheduledMessages)
    }

    @MainActor func test_get_whenThereIsANextPage_thenNotAllScheduledMessagesAreLoaded() async throws {
        setUpScheduledMessageList()
        apiClient.test_mockResponseResult(.success(QueryScheduledMessagesResponse(next: "cursor", scheduledMessages: [.dummy(cid: cid)])))

        try await scheduledMessageList.get()

        XCTAssertFalse(scheduledMessageList.state.hasLoadedAllScheduledMessages)
    }

    @MainActor func test_get_whenTheRequestFails_thenGetFails() async throws {
        setUpScheduledMessageList()
        apiClient.test_mockResponseResult(Result<QueryScheduledMessagesResponse, Error>.failure(ClientError.ConnectionError()))

        await XCTAssertAsyncFailure(try await scheduledMessageList.get(), expectedErrorHandler: { $0 is ClientError.ConnectionError })
    }

    // MARK: - Pagination

    @MainActor func test_loadMoreScheduledMessages_thenTheNextPageIsRequestedAndAddedToTheState() async throws {
        setUpScheduledMessageList(query: .init(pageSize: 1))
        apiClient.test_mockResponseResult(.success(QueryScheduledMessagesResponse(next: "cursor", scheduledMessages: [.dummy(id: "first", cid: cid)])))
        try await scheduledMessageList.get()
        apiClient.test_mockResponseResult(.success(QueryScheduledMessagesResponse(scheduledMessages: [.dummy(id: "second", cid: cid)])))

        let loaded = try await scheduledMessageList.loadMoreScheduledMessages()

        let expectedEndpoint: Endpoint<QueryScheduledMessagesResponse> = .queryScheduledMessages(
            queryScheduledMessagesRequest: QueryScheduledMessagesRequest(limit: 1, next: "cursor")
        )
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), apiClient.request_endpoint)
        XCTAssertEqual(["second"], loaded.map(\.id))
        XCTAssertTrue(scheduledMessageList.state.hasLoadedAllScheduledMessages)
        XCTAssertEqual(["first", "second"], Set(scheduledMessageList.state.scheduledMessages.map(\.id)))
    }

    @MainActor func test_loadMoreScheduledMessages_whenAllAreLoaded_thenNothingIsRequested() async throws {
        setUpScheduledMessageList()
        apiClient.test_mockResponseResult(.success(QueryScheduledMessagesResponse(scheduledMessages: [.dummy(id: "first", cid: cid)])))
        try await scheduledMessageList.get()

        let loaded = try await scheduledMessageList.loadMoreScheduledMessages()

        XCTAssertEqual([], loaded.map(\.id))
        XCTAssertEqual(1, apiClient.request_allRecordedCalls.count)
        XCTAssertEqual(["first"], scheduledMessageList.state.scheduledMessages.map(\.id))
    }

    // MARK: - Managing Scheduled Messages

    @MainActor func test_rescheduleMessage_thenTheStateHasTheNewDate() async throws {
        let message = try await schedule()
        setUpScheduledMessageList()
        let newDate = Date().addingTimeInterval(7200)

        let rescheduled = try await scheduledMessageList.rescheduleMessage(id: message.id, scheduledAt: newDate)

        XCTAssertEqual(newDate.timeIntervalSince1970, rescheduled.scheduledAt.timeIntervalSince1970, accuracy: 0.001)
        let stored = try await waitForScheduledMessage(id: message.id) {
            abs($0.scheduledAt.timeIntervalSince1970 - newDate.timeIntervalSince1970) < 0.001
        }
        XCTAssertEqual(newDate.timeIntervalSince1970, stored.scheduledAt.timeIntervalSince1970, accuracy: 0.001)
    }

    @MainActor func test_deleteScheduledMessage_thenItIsRemovedFromTheState() async throws {
        let message = try await schedule()
        setUpScheduledMessageList()
        apiClient.test_mockResponseResult(.success(
            DeleteScheduledMessageResponse(scheduledMessage: .dummy(id: message.id, cid: cid, status: .canceled))
        ))

        try await scheduledMessageList.deleteScheduledMessage(id: message.id)

        try await waitUntil { self.scheduledMessageList.state.scheduledMessages.isEmpty }
        XCTAssertEqual([], scheduledMessageList.state.scheduledMessages.map(\.id))
    }

    @MainActor func test_sendScheduledMessageNow_thenItIsMarkedUntilTheSchedulerSendsIt() async throws {
        let message = try await schedule()
        setUpScheduledMessageList()

        try await scheduledMessageList.sendScheduledMessageNow(id: message.id)

        XCTAssertNil(apiClient.request_endpoint)
        let stored = try await waitForScheduledMessage(id: message.id) { $0.status == .preparingToSchedule }
        XCTAssertEqual(.preparingToSchedule, stored.status)
    }

    @MainActor func test_resendScheduledMessage_whenItHasNoFailedChanges_thenResendFails() async throws {
        let message = try await schedule()
        setUpScheduledMessageList()

        await XCTAssertAsyncFailure(
            try await scheduledMessageList.resendScheduledMessage(id: message.id),
            expectedErrorHandler: { $0 is ClientError.ScheduledMessageHasNoPendingChanges }
        )
    }

    @MainActor func test_resendScheduledMessage_whenItDoesNotExist_thenResendFails() async throws {
        setUpScheduledMessageList()

        await XCTAssertAsyncFailure(
            try await scheduledMessageList.resendScheduledMessage(id: .unique),
            expectedErrorHandler: { $0 is ClientError.ScheduledMessageDoesNotExist }
        )
    }

    // MARK: - Content Changes

    // The list reuses scheduled messages by id, so these check that changes of their content still reach it.

    @MainActor func test_scheduledMessages_whenTheContentChanges_thenTheStateIsUpdated() async throws {
        let message = try await schedule()
        setUpScheduledMessageList()

        try await client.databaseContainer.write { session in
            let content = try XCTUnwrap(session.scheduledMessage(id: message.id)?.message)
            content.text = "Edited"
        }

        let stored = try await waitForScheduledMessage(id: message.id) { $0.message.text == "Edited" }
        XCTAssertEqual("Edited", stored.message.text)
    }

    @MainActor func test_scheduledMessages_whenAnAttachmentChanges_thenTheStateIsUpdated() async throws {
        let message = try await scheduleLocally(attachments: [.mockImage])
        setUpScheduledMessageList()

        // Only the attachment changes, not the content message or the scheduled message.
        try await client.databaseContainer.write { session in
            let content = try XCTUnwrap(session.scheduledMessage(id: message.id)?.message)
            content.attachments.forEach { $0.localState = .uploadingFailed }
        }

        let stored = try await waitForScheduledMessage(id: message.id) {
            $0.message.allAttachments.first?.uploadingState?.state == .uploadingFailed
        }
        XCTAssertEqual(.uploadingFailed, stored.message.allAttachments.first?.uploadingState?.state)
    }

    // MARK: - Test Data

    @MainActor private func setUpScheduledMessageList(query: ScheduledMessageListQuery = .init()) {
        scheduledMessageList = client.makeScheduledMessageList(with: query)
        _ = scheduledMessageList.state
    }

    /// Saves a scheduled message as returned by the server.
    private func schedule(cid: ChannelId? = nil) async throws -> ScheduledMessage {
        let payload = ScheduledMessageResponse.dummy(cid: cid ?? self.cid!)
        return try await withCheckedThrowingContinuation { continuation in
            client.databaseContainer.write(converting: { session in
                try session.saveScheduledMessage(payload: payload).asModel()
            }, completion: { continuation.resume(with: $0) })
        }
    }

    /// Schedules a message on the device, with local attachments.
    @MainActor private func scheduleLocally(attachments: [AnyAttachmentPayload]) async throws -> ScheduledMessage {
        apiClient.test_mockResponseResult(.success(
            SendMessageResponsePayload(message: .dummy(cid: cid), scheduledMessage: .dummy(cid: cid))
        ))
        let channelController = client.channelController(for: cid)
        return try await withCheckedThrowingContinuation { continuation in
            channelController.scheduleMessage(
                text: "Photo",
                attachments: attachments,
                scheduledAt: Date().addingTimeInterval(3600),
                completion: { continuation.resume(with: $0) }
            )
        }
    }

    @MainActor private func waitForScheduledMessage(
        id: String,
        matching predicate: (ScheduledMessage) -> Bool
    ) async throws -> ScheduledMessage {
        try await waitUntil {
            self.scheduledMessageList.state.scheduledMessages.contains { $0.id == id && predicate($0) }
        }
        return try XCTUnwrap(scheduledMessageList.state.scheduledMessages.first { $0.id == id })
    }

    @MainActor private func waitUntil(
        timeout: TimeInterval = 2,
        _ condition: () throws -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while try !condition() {
            guard Date() < deadline else {
                XCTFail("The condition was not met in time", file: file, line: line)
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}
