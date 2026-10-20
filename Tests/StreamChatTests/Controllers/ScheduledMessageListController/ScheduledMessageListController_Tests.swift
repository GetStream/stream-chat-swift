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

    @MainActor func test_delegate_isNotifiedOfInsertionsAndRemovals() throws {
        let controller = client.scheduledMessageListController()
        let delegate = DelegateSpy()
        controller.delegate = delegate

        let message = try schedule()
        AssertAsync.willBeTrue(delegate.insertions.contains { $0.item == message && $0.index == IndexPath(item: 0, section: 0) })

        apiClient.test_mockResponseResult(.success(DeleteScheduledMessageResponse(scheduledMessage: .dummy(id: message.id, cid: cid, status: "canceled"))))
        _ = try waitFor { controller.deleteScheduledMessage(id: message.id, completion: $0) }

        AssertAsync.willBeTrue(delegate.removedIds.contains(message.id))
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

    func test_sendScheduledMessageNow_requestsToSendIt() throws {
        let message = try schedule()
        let controller = client.scheduledMessageListController()
        apiClient.test_mockResponseResult(.success(SendScheduledMessageNowResponse(scheduledMessage: .dummy(id: message.id, cid: cid, status: "sending"))))

        let error = try waitFor { controller.sendScheduledMessageNow(id: message.id, completion: $0) }

        let expectedEndpoint: Endpoint<SendScheduledMessageNowResponse> = .sendScheduledMessageNow(id: message.id)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(error)
        XCTAssertEqual(controller.scheduledMessages.first?.status, .sending)
    }

    // MARK: - Helpers

    private func schedule(cid: ChannelId? = nil) throws -> ScheduledMessage {
        let cid = cid ?? self.cid!
        apiClient.test_mockUnmanagedResponseResult(.success(
            SendMessageResponsePayload(message: .dummy(cid: cid), scheduledMessage: .dummy(cid: cid))
        ))
        let channelController = client.channelController(for: cid)
        return try waitFor {
            channelController.scheduleMessage(text: "Hello", scheduledAt: Date().addingTimeInterval(3600), completion: $0)
        }.get()
    }
}

private final class DelegateSpy: ScheduledMessageListControllerDelegate, @unchecked Sendable {
    @Atomic private(set) var changes: [ListChange<ScheduledMessage>] = []

    var insertions: [(item: ScheduledMessage, index: IndexPath)] {
        changes.compactMap {
            guard case let .insert(item, index) = $0 else { return nil }
            return (item, index)
        }
    }

    var removedIds: [String] {
        changes.compactMap {
            guard case let .remove(item, _) = $0 else { return nil }
            return item.id
        }
    }

    func controller(
        _ controller: ScheduledMessageListController,
        didChangeScheduledMessages changes: [ListChange<ScheduledMessage>]
    ) {
        _changes.mutate { $0.append(contentsOf: changes) }
    }
}
