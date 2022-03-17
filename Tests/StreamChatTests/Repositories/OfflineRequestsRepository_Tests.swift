//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class OfflineRequestsRepository_Tests: XCTestCase {
    var messageRepository: MessageRepositoryMock!
    var repository: OfflineRequestsRepository!
    var database: DatabaseContainerMock!
    var apiClient: APIClientMock!

    override func setUp() {
        let client = ChatClient.mock
        database = client.mockDatabaseContainer
        apiClient = client.mockAPIClient
        messageRepository = MessageRepositoryMock(database: database, apiClient: apiClient)
        repository = OfflineRequestsRepository(messageRepository: messageRepository, database: database, apiClient: apiClient)
    }

    override func tearDown() {
        super.tearDown()
        messageRepository = nil
        repository = nil
        database = nil
        apiClient = nil
    }

    // MARK: - Run queued requests

    func test_runQueuedRequestsWithoutPendingRequests() {
        let expectation = self.expectation(description: "Running completes")
        repository.runQueuedRequests {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.1, handler: nil)

        // No calls should be performed when there are no queued requests
        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 0)
    }

    func test_runQueuedRequestsWithPendingRequests() throws {
        // We add one request to the queue
        try createSendMessageRequests(count: 1)

        let expectation = self.expectation(description: "Running completes")
        repository.runQueuedRequests {
            expectation.fulfill()
        }

        AssertAsync.willBeTrue(apiClient.recoveryRequest_endpoint != nil)
        apiClient.test_simulateRecoveryResponse(.success(Data()))

        waitForExpectations(timeout: 0.1, handler: nil)

        // One call should be performed
        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 1)

        // Upon completing, the request should be removed from the queue
        let pendingRequests = QueuedRequestDTO.loadAllPendingRequests(context: database.viewContext)
        XCTAssertEqual(pendingRequests.count, 0)
    }

    func test_runQueuedRequestsWithPendingRequests_createChannel() throws {
        // We add one .createChannel request to the queue. This is NOT a supported offline action anymore.
        try createRequest(id: .unique, path: .createChannel(""))

        let expectation = self.expectation(description: "Running completes")
        repository.runQueuedRequests {
            expectation.fulfill()
        }

        // We reset the counter to properly assert later
        database.writeSessionCounter = 0
        waitForExpectations(timeout: 0.1, handler: nil)

        // No actions should be taken for a request that is not supported offline
        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 0)
        let pendingRequests = QueuedRequestDTO.loadAllPendingRequests(context: database.viewContext)
        XCTAssertEqual(pendingRequests.count, 0)
        // 1 to remove the request from the queue
        XCTAssertEqual(database.writeSessionCounter, 1)
    }

    func test_runQueuedRequestsWithPendingRequests_sendMessage() throws {
        // We add one .sendMessage request to the queue
        try createRequest(id: .unique, path: .sendMessage(.unique))

        let expectation = self.expectation(description: "Running completes")
        repository.runQueuedRequests {
            expectation.fulfill()
        }

        // We reset the counter to properly assert later
        database.writeSessionCounter = 0
        AssertAsync.willBeTrue(apiClient.recoveryRequest_endpoint != nil)

        let jsonData = XCTestCase.mockData(fromFile: "Message", bundle: .testToolsBundle)
        apiClient.test_simulateRecoveryResponse(.success(jsonData))

        waitForExpectations(timeout: 0.1, handler: nil)

        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 1)
        let pendingRequests = QueuedRequestDTO.loadAllPendingRequests(context: database.viewContext)
        XCTAssertEqual(pendingRequests.count, 0)

        // 1 to remove the request from the queue
        XCTAssertEqual(database.writeSessionCounter, 1)
        XCTAssertCall("saveSuccessfullySentMessage(cid:message:completion:)", on: messageRepository, times: 1)
    }

    func test_runQueuedRequestsWithPendingRequests_editMessage() throws {
        // We add one .editMessage request to the queue
        try createRequest(id: .unique, path: .editMessage(.unique))

        let expectation = self.expectation(description: "Running completes")
        repository.runQueuedRequests {
            expectation.fulfill()
        }

        // We reset the counter to properly assert later
        database.writeSessionCounter = 0
        AssertAsync.willBeTrue(apiClient.recoveryRequest_endpoint != nil)

        apiClient.test_simulateRecoveryResponse(.success(Data()))

        waitForExpectations(timeout: 0.1, handler: nil)

        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 1)
        let pendingRequests = QueuedRequestDTO.loadAllPendingRequests(context: database.viewContext)
        XCTAssertEqual(pendingRequests.count, 0)

        // 1 to remove the request from the queue
        XCTAssertEqual(database.writeSessionCounter, 1)
        XCTAssertCall("saveSuccessfullyEditedMessage(for:completion:)", on: messageRepository, times: 1)
    }

    func test_runQueuedRequestsWithPendingRequests_deleteMessage() throws {
        // We add one .deleteMessage request to the queue
        try createRequest(id: .unique, path: .deleteMessage(.unique))

        let expectation = self.expectation(description: "Running completes")
        repository.runQueuedRequests {
            expectation.fulfill()
        }

        // We reset the counter to properly assert later
        database.writeSessionCounter = 0
        AssertAsync.willBeTrue(apiClient.recoveryRequest_endpoint != nil)

        let jsonData = XCTestCase.mockData(fromFile: "Message", bundle: .testToolsBundle)
        apiClient.test_simulateRecoveryResponse(.success(jsonData))

        waitForExpectations(timeout: 0.1, handler: nil)

        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 1)
        let pendingRequests = QueuedRequestDTO.loadAllPendingRequests(context: database.viewContext)
        XCTAssertEqual(pendingRequests.count, 0)

        // 1 to remove the request from the queue
        XCTAssertEqual(database.writeSessionCounter, 1)
        XCTAssertCall("saveSuccessfullyDeletedMessage(message:completion:)", on: messageRepository, times: 1)
    }

    func test_runQueuedRequestsWithManyPendingRequests() throws {
        // We put 5 .sendMessage requests in the queue
        let count = 5
        try createSendMessageRequests(count: count)

        let expectation = self.expectation(description: "Running completes")
        repository.runQueuedRequests {
            expectation.fulfill()
        }

        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 5)
        // We make all the requests succeed
        apiClient.recoveryRequest_allRecordedCalls.forEach { _, completion in
            let completion = completion as? ((Result<Data, Error>) -> Void)
            completion?(.success(Data()))
        }

        waitForExpectations(timeout: 0.1, handler: nil)

        // Queued requests should be removed once completed
        let pendingRequests = QueuedRequestDTO.loadAllPendingRequests(context: database.viewContext)
        XCTAssertEqual(pendingRequests.count, 0)
    }

    func test_runQueuedRequestsWithManyPendingRequestsOneNetworkFailureShouldBeKept() throws {
        // We put 5 .sendMessage requests in the queue
        let count = 5
        try createSendMessageRequests(count: count)

        let expectation = self.expectation(description: "Running completes")
        repository.runQueuedRequests {
            expectation.fulfill()
        }

        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 5)

        // We make all the requests succeed but 1, which receives a Connection Error
        apiClient.recoveryRequest_allRecordedCalls.forEach { endpoint, completion in
            let completion = completion as? ((Result<Data, Error>) -> Void)
            if case let .sendMessage(id) = endpoint.path, id.id == "request2" {
                completion?(.failure(ClientError.ConnectionError()))
            } else {
                completion?(.success(Data()))
            }
        }

        waitForExpectations(timeout: 0.1, handler: nil)

        // Queued requests with ConnectionError should be kept
        let pendingRequests = QueuedRequestDTO.loadAllPendingRequests(context: database.viewContext)
        XCTAssertEqual(pendingRequests.count, 1)
    }

    func test_runQueuedRequestsWhichFailShouldBeRemoved() throws {
        // We put 5 .sendMessage requests in the queue
        let count = 5
        try createSendMessageRequests(count: count)

        let expectation = self.expectation(description: "Running completes")
        repository.runQueuedRequests {
            expectation.fulfill()
        }

        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 5)

        // We make all the requests succeed but 1, which receives a random error
        apiClient.recoveryRequest_allRecordedCalls.forEach { endpoint, completion in
            let completion = completion as? ((Result<Data, Error>) -> Void)
            if case let .sendMessage(id) = endpoint.path, id.id == "request2" {
                completion?(.failure(NSError(domain: "whatever", code: 1, userInfo: nil)))
            } else {
                completion?(.success(Data()))
            }
        }

        waitForExpectations(timeout: 0.1, handler: nil)

        // Queued requests should be removed when result is either success or an error that is not connection related
        let pendingRequests = QueuedRequestDTO.loadAllPendingRequests(context: database.viewContext)
        XCTAssertEqual(pendingRequests.count, 0)
    }

    private func createSendMessageRequests(count: Int) throws {
        try (1...count).forEach {
            let id = "request\($0)"
            try self.createRequest(id: id, path: .sendMessage(.init(type: .messaging, id: id)), body: ["some\($0)": 123])
        }

        let allRequests = QueuedRequestDTO.loadAllPendingRequests(context: database.viewContext)
        XCTAssertEqual(allRequests.count, count)
    }

    private func createRequest(id: String, path: EndpointPath, body: Encodable? = nil) throws {
        let date = Date()
        let endpoint = Endpoint<EmptyResponse>(
            path: path,
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            requiresToken: false,
            body: body
        )
        let endpointData: Data = try JSONEncoder.stream.encode(endpoint)
        try database.writeSynchronously { _ in
            QueuedRequestDTO.createRequest(id: id, date: date, endpoint: endpointData, context: self.database.writableContext)
        }
    }

    // MARK: - Queue requests

    func test_queueOfflineRequestNotWanted() {
        let endpoint = DataEndpoint(
            path: .channelEvent("id"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            requiresToken: true,
            body: nil
        )

        let expectation = self.expectation(description: "Queuing completes")
        repository.queueOfflineRequest(endpoint: endpoint) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertNotCall("write(_:completion:)", on: database)
    }

    func test_queueOfflineRequestWanted() {
        let endpoint = DataEndpoint(
            path: .sendMessage(.unique),
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            requiresToken: true,
            body: nil
        )

        let expectation = self.expectation(description: "Queuing completes")
        repository.queueOfflineRequest(endpoint: endpoint) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertCall("write(_:completion:)", on: database, times: 1)
    }
}
