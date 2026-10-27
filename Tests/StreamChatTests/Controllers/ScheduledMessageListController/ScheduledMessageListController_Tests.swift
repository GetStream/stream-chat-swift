//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ScheduledMessageListController_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var apiClient: APIClient_Spy!
    var cid: ChannelId!
    var userId: UserId!

    override func setUp() {
        super.setUp()

        client = ChatClient.mock
        apiClient = client.mockAPIClient
        cid = .unique
        userId = .unique
        client.currentUserId_mock = userId
        try? client.mockDatabaseContainer.createCurrentUser(id: userId)
    }

    override func tearDown() {
        apiClient.cleanUp()
        apiClient = nil
        client = nil
        cid = nil
        userId = nil

        super.tearDown()
    }

    func test_synchronize_loadsTheScheduledMessages() throws {
        apiClient.test_mockResponseResult(.success(QueryScheduledMessagesResponse(scheduledMessages: [.dummy(id: "scheduled-id", cid: cid)])))
        let controller = client.scheduledMessageListController()

        let error = try waitFor { controller.synchronize($0) }

        XCTAssertNil(error)
        XCTAssertEqual(controller.state, .remoteDataFetched)
        XCTAssertTrue(controller.hasLoadedAllScheduledMessages)
        XCTAssertEqual(controller.scheduledMessages.map(\.id), ["scheduled-id"])
    }

    func test_synchronize_withANextPage_hasNotLoadedAllScheduledMessages() throws {
        apiClient.test_mockResponseResult(.success(QueryScheduledMessagesResponse(next: "cursor", scheduledMessages: [.dummy(cid: cid)])))
        let controller = client.scheduledMessageListController()

        _ = try waitFor { controller.synchronize($0) }

        XCTAssertFalse(controller.hasLoadedAllScheduledMessages)
    }

    func test_loadMoreScheduledMessages_requestsTheNextPage() throws {
        apiClient.test_mockResponseResult(.success(QueryScheduledMessagesResponse(next: "cursor", scheduledMessages: [.dummy(id: "first", cid: cid)])))
        let controller = client.scheduledMessageListController(query: .init(pageSize: 1))
        _ = try waitFor { controller.synchronize($0) }
        apiClient.test_mockResponseResult(.success(QueryScheduledMessagesResponse(scheduledMessages: [.dummy(id: "second", cid: cid)])))

        let loaded = try waitFor { controller.loadMoreScheduledMessages(completion: $0) }.get()

        let expectedEndpoint: Endpoint<QueryScheduledMessagesResponse> = .queryScheduledMessages(
            queryScheduledMessagesRequest: QueryScheduledMessagesRequest(limit: 1, next: "cursor")
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertEqual(loaded.map(\.id), ["second"])
        XCTAssertTrue(controller.hasLoadedAllScheduledMessages)
        XCTAssertEqual(Set(controller.scheduledMessages.map(\.id)), ["first", "second"])
    }

    func test_synchronize_whenTheRequestFails_reportsTheError() throws {
        apiClient.test_mockResponseResult(Result<QueryScheduledMessagesResponse, Error>.failure(ClientError.ConnectionError()))
        let controller = client.scheduledMessageListController()

        let error = try waitFor { controller.synchronize($0) }

        XCTAssertNotNil(error)
        guard case .remoteDataFetchFailed = controller.state else {
            return XCTFail("Expected the remote fetch to fail")
        }
    }

    @MainActor func test_delegate_isNotifiedOfTheScheduledMessages() throws {
        let controller = client.scheduledMessageListController()
        let delegate = DelegateSpy()
        controller.delegate = delegate

        let message = try schedule()
        wait(until: { delegate.scheduledMessages == [message] })

        apiClient.test_mockResponseResult(.success(DeleteScheduledMessageResponse(scheduledMessage: .dummy(id: message.id, cid: cid, status: .canceled))))
        _ = try waitFor { controller.deleteScheduledMessage(id: message.id, completion: $0) }

        wait(until: { delegate.scheduledMessages == [] })
        XCTAssertEqual(controller.scheduledMessages, [])
    }

    func test_scheduledMessages_onlyIncludesTheMessagesMatchingTheQuery() throws {
        let message = try schedule()
        _ = try schedule(cid: .unique)

        let controller = client.scheduledMessageListController(query: .init(filter: .equal(.cid, to: cid)))

        XCTAssertEqual(controller.scheduledMessages, [message])
    }

    func test_rescheduleMessage_updatesTheDate() throws {
        let message = try schedule()
        let controller = client.scheduledMessageListController()
        let newDate = Date().addingTimeInterval(7200)
        apiClient.test_mockResponseResult(.success(UpdateScheduledMessageResponse(scheduledMessage: .dummy(id: message.id, cid: cid, scheduledAt: newDate))))

        let rescheduled = try waitFor { controller.rescheduleMessage(id: message.id, scheduledAt: newDate, completion: $0) }.get()

        XCTAssertEqual(rescheduled.scheduledAt.timeIntervalSince1970, newDate.timeIntervalSince1970, accuracy: 0.001)
        let stored = try XCTUnwrap(controller.scheduledMessages.first)
        XCTAssertEqual(stored.scheduledAt.timeIntervalSince1970, newDate.timeIntervalSince1970, accuracy: 0.001)
    }

    func test_sendScheduledMessageNow_marksItToBeSentByTheScheduler() throws {
        let message = try schedule()
        let controller = client.scheduledMessageListController()
        apiClient.cleanUp()

        let error = try waitFor { controller.sendScheduledMessageNow(id: message.id, completion: $0) }

        XCTAssertNil(error)
        XCTAssertNil(apiClient.request_endpoint)
        let isPendingSendNow = try client.databaseContainer.readSynchronously { $0.scheduledMessage(id: message.id)?.isPendingSendNow }
        XCTAssertEqual(isPendingSendNow, true)
    }

    // MARK: - Helpers

    private func schedule(cid: ChannelId? = nil) throws -> ScheduledMessage {
        let cid = cid ?? self.cid!
        apiClient.test_mockResponseResult(.success(
            SendMessageResponsePayload(message: .dummy(cid: cid), scheduledMessage: .dummy(cid: cid))
        ))
        let channelController = client.channelController(for: cid)
        return try waitFor {
            channelController.scheduleMessage(text: "Hello", scheduledAt: Date().addingTimeInterval(3600), completion: $0)
        }.get()
    }
}

private final class DelegateSpy: ScheduledMessageListControllerDelegate, @unchecked Sendable {
    @Atomic private(set) var scheduledMessages: [ScheduledMessage] = []

    func controller(
        _ controller: ScheduledMessageListController,
        didChangeScheduledMessages scheduledMessages: [ScheduledMessage]
    ) {
        self.scheduledMessages = scheduledMessages
    }
}
