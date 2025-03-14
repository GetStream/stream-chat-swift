//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelRepository_Tests: XCTestCase {
    private var repository: ChannelRepository!
    private var database: DatabaseContainer_Spy!
    private var apiClient: APIClient_Spy!

    override func setUp() {
        super.setUp()
        let client = ChatClient.mock
        database = client.mockDatabaseContainer
        apiClient = client.mockAPIClient
        repository = ChannelRepository(database: database, apiClient: apiClient)
    }

    override func tearDown() {
        repository = nil
        database = nil
        apiClient = nil
        super.tearDown()
    }
    
    // MARK: - Get Channel
    
    func test_getChannel_storeFalse_successfulResponse() throws {
        let cid = ChannelId.unique
        let query = ChannelQuery(cid: cid)
        let channelPayload = ChannelPayload.dummy(channel: .dummy(cid: cid))
        apiClient.test_mockResponseResult(.success(channelPayload))
        let result = try waitFor { done in
            repository.getChannel(for: query, store: false, completion: done)
        }
        let expectedEndpoint = Endpoint<ChannelPayload>.createChannel(query: query)
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), apiClient.request_endpoint)
        XCTAssertEqual(1, database.writeSessionCounter, "Write is called, but rolled back")
        
        let databaseChannel = try database.readSynchronously { $0.channel(cid: cid) }
        XCTAssertEqual(nil, databaseChannel, "When store is false, nothing is stored")
        
        let channel = try XCTUnwrap(result.value)
        XCTAssertEqual(cid, channel.cid)
    }
    
    func test_getChannel_storeFalse_errorResponse() throws {
        let cid = ChannelId.unique
        let query = ChannelQuery(cid: cid)
        let expectedError = TestError()
        apiClient.test_mockResponseResult(Result<ChannelPayload, Error>.failure(expectedError))
        let result = try waitFor { done in
            repository.getChannel(for: query, store: false, completion: done)
        }
        let expectedEndpoint = Endpoint<ChannelPayload>.createChannel(query: query)
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), apiClient.request_endpoint)
        XCTAssertEqual(0, database.writeSessionCounter)
        
        let error = try XCTUnwrap(result.error)
        XCTAssertEqual(expectedError, error)
    }

    // MARK: - Mark as read

    func test_markRead_successfulResponse() {
        let cid = ChannelId.unique
        let userId = UserId.unique

        let expectation = self.expectation(description: "markRead completes")
        var receivedError: Error?
        repository.markRead(cid: cid, userId: userId) { error in
            receivedError = error
            expectation.fulfill()
        }

        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))
        waitForExpectations(timeout: defaultTimeout)

        let referenceEndpoint = Endpoint<EmptyResponse>.markRead(cid: cid)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
        XCTAssertEqual(database.writeSessionCounter, 1)
        XCTAssertNil(receivedError)
    }

    func test_markRead_errorResponse() {
        let cid = ChannelId.unique
        let userId = UserId.unique

        let expectation = self.expectation(description: "markRead completes")
        var receivedError: Error?
        repository.markRead(cid: cid, userId: userId) { error in
            receivedError = error
            expectation.fulfill()
        }

        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        waitForExpectations(timeout: defaultTimeout)

        let referenceEndpoint = Endpoint<EmptyResponse>.markRead(cid: cid)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
        XCTAssertEqual(database.writeSessionCounter, 0)
        XCTAssertEqual(receivedError, error)
    }

    // MARK: - Mark as unread

    func test_markUnread_successfulResponse() throws {
        let cid = ChannelId.unique
        let userId = UserId.unique
        let messageId = MessageId.unique

        try database.createCurrentUser()
        try database.writeSynchronously {
            try $0.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
        }
        database.writeSessionCounter = 0

        let expectation = self.expectation(description: "markUnread completes")
        var receivedError: Error?
        repository.markUnread(for: cid, userId: userId, from: messageId, lastReadMessageId: .unique) { result in
            receivedError = result.error
            expectation.fulfill()
        }

        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))
        waitForExpectations(timeout: defaultTimeout)

        let referenceEndpoint = Endpoint<EmptyResponse>.markUnread(cid: cid, messageId: messageId, userId: userId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
        XCTAssertEqual(database.writeSessionCounter, 1)
        XCTAssertNil(receivedError)
    }

    func test_markUnread_errorResponse() {
        let cid = ChannelId.unique
        let userId = UserId.unique
        let messageId = MessageId.unique

        let expectation = self.expectation(description: "markUnread completes")
        var receivedError: Error?
        repository.markUnread(for: cid, userId: userId, from: messageId, lastReadMessageId: .unique) { result in
            receivedError = result.error
            expectation.fulfill()
        }

        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        waitForExpectations(timeout: defaultTimeout)

        let referenceEndpoint = Endpoint<EmptyResponse>.markUnread(cid: cid, messageId: messageId, userId: userId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
        XCTAssertEqual(database.writeSessionCounter, 0)
        XCTAssertEqual(receivedError, error)
    }
}
