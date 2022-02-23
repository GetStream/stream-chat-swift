//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class OfflineRequestsRepository_Tests: XCTestCase {
    var repository: OfflineRequestsRepository!
    var database: DatabaseContainerMock!
    var apiClient: APIClientMock!

    override func setUp() {
        let client = ChatClient.mock
        database = client.mockDatabaseContainer
        apiClient = client.mockAPIClient
        let messageRepository = MessageRepositoryMock(database: database, apiClient: apiClient)
        repository = OfflineRequestsRepository(messageRepository: messageRepository, database: database, apiClient: apiClient)
    }

    // MARK: - Run queued requests

    func test_runQueuedRequestsWithoutPendingRequests() {
        let expectation = self.expectation(description: "Running completes")
        repository.runQueuedRequests {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.1, handler: nil)

        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 0)
    }

    func test_runQueuedRequestsWithPendingRequests() throws {
        try createRequests(count: 1)

        let expectation = self.expectation(description: "Running completes")
        repository.runQueuedRequests {
            expectation.fulfill()
        }

        AssertAsync.willBeTrue(apiClient.recoveryRequest_endpoint != nil)
        apiClient.test_simulateRecoveryResponse(.success(Data()))

        waitForExpectations(timeout: 0.1, handler: nil)

        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 1)
        let pendingRequests = QueuedRequestDTO.loadAllPendingRequests(context: database.viewContext)
        XCTAssertEqual(pendingRequests.count, 0)
    }

    func test_runQueuedRequestsWithManyPendingRequests() throws {
        let count = 5
        try createRequests(count: count)

        let expectation = self.expectation(description: "Running completes")
        repository.runQueuedRequests {
            expectation.fulfill()
        }

        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 5)
        apiClient.recoveryRequest_allRecordedCalls.forEach { _, completion in
            let completion = completion as? ((Result<Data, Error>) -> Void)
            completion?(.success(Data()))
        }

        waitForExpectations(timeout: 0.1, handler: nil)

        let pendingRequests = QueuedRequestDTO.loadAllPendingRequests(context: database.viewContext)
        XCTAssertEqual(pendingRequests.count, 0)
    }

    func test_runQueuedRequestsWithManyPendingRequestsOneNetworkFailureShouldBeKept() throws {
        let count = 5
        try createRequests(count: count)

        let expectation = self.expectation(description: "Running completes")
        repository.runQueuedRequests {
            expectation.fulfill()
        }

        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 5)
        apiClient.recoveryRequest_allRecordedCalls.forEach { endpoint, completion in
            let completion = completion as? ((Result<Data, Error>) -> Void)
            if case let .sendMessage(id) = endpoint.path, id.id == "request2" {
                completion?(.failure(ClientError.ConnectionError()))
            } else {
                completion?(.success(Data()))
            }
        }

        waitForExpectations(timeout: 0.1, handler: nil)

        let pendingRequests = QueuedRequestDTO.loadAllPendingRequests(context: database.viewContext)
        XCTAssertEqual(pendingRequests.count, 1)
    }

    func test_runQueuedRequestsWhichFailShouldBeRemoved() throws {
        let count = 5
        try createRequests(count: count)

        let expectation = self.expectation(description: "Running completes")
        repository.runQueuedRequests {
            expectation.fulfill()
        }

        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 5)
        apiClient.recoveryRequest_allRecordedCalls.forEach { endpoint, completion in
            let completion = completion as? ((Result<Data, Error>) -> Void)
            if case let .sendMessage(id) = endpoint.path, id.id == "request2" {
                completion?(.failure(NSError(domain: "whatever", code: 1, userInfo: nil)))
            } else {
                completion?(.success(Data()))
            }
        }

        waitForExpectations(timeout: 0.1, handler: nil)

        let pendingRequests = QueuedRequestDTO.loadAllPendingRequests(context: database.viewContext)
        XCTAssertEqual(pendingRequests.count, 0)
    }

    private func createRequests(count: Int) throws {
        func createRequest(index: Int) throws {
            let id = "request\(index)"
            let date = Date()
            let endpoint = Endpoint<EmptyResponse>(
                path: .sendMessage(.init(type: .messaging, id: id)),
                method: .post,
                queryItems: nil,
                requiresConnectionId: true,
                requiresToken: false,
                body: ["something\(index)": 123]
            )
            let endpointData: Data = try JSONEncoder.stream.encode(endpoint)
            QueuedRequestDTO.createRequest(id: id, date: date, endpoint: endpointData, context: database.writableContext)
        }

        try database.writeSynchronously { _ in
            try (1...count).forEach {
                try createRequest(index: $0)
            }
        }

        let allRequests = QueuedRequestDTO.loadAllPendingRequests(context: database.viewContext)
        XCTAssertEqual(allRequests.count, count)
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
