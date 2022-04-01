//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelListUpdater_Tests: XCTestCase {
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    var database: DatabaseContainer!
    
    var listUpdater: ChannelListUpdater!
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        database = DatabaseContainerMock()
        
        listUpdater = ChannelListUpdater(database: database, apiClient: apiClient)
    }
    
    override func tearDown() {
        webSocketClient = nil
        apiClient.cleanUp()
        apiClient = nil

        database = nil
        listUpdater = nil
        
        super.tearDown()
    }
    
    // MARK: - Update
    
    func test_update_makesCorrectAPICall() {
        // Simulate `update` call
        let query = ChannelListQuery(filter: .in(.members, values: [.unique]))
        listUpdater.update(channelListQuery: query)
        
        let referenceEndpoint: Endpoint<ChannelListPayload> = .channels(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_update_successfulResponseData_areSavedToDB() {
        // Simulate `update` call
        let query = ChannelListQuery(filter: .in(.members, values: [.unique]))
        var completionCalled = false
        listUpdater.update(channelListQuery: query, completion: { result in
            XCTAssertNil(result.error)
            completionCalled = true
        })
        
        // Simulate API response with channel data
        let cid = ChannelId(type: .messaging, id: .unique)
        let payload = ChannelListPayload(channels: [dummyPayload(with: cid)])
        apiClient.test_simulateResponse(.success(payload))
        
        // Assert the data is stored in the DB
        var channel: ChatChannel? {
            database.viewContext.channel(cid: cid)?.asModel()
        }
        AssertAsync {
            Assert.willBeTrue(channel != nil)
            Assert.willBeTrue(completionCalled)
        }
    }
    
    func test_update_errorResponse_isPropagatedToCompletion() {
        // Simulate `update` call
        let query = ChannelListQuery(filter: .in(.members, values: [.unique]))
        var completionCalledError: Error?
        listUpdater.update(channelListQuery: query, completion: { completionCalledError = $0.error })
        
        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<ChannelListPayload, Error>.failure(error))
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    func test_update_doesNotRetainSelf() {
        // Simulate `update` call
        listUpdater.update(channelListQuery: .init(filter: .in(.members, values: [.unique])))
        
        // Assert updater can be deallocated without waiting for the API response.
        AssertAsync.canBeReleased(&listUpdater)
    }
    
    func test_update_savesQuery_onEmptyResponse() {
        // Simulate `update` call
        let query = ChannelListQuery(filter: .in(.members, values: [.unique]))
        var completionCalled = false
        listUpdater.update(channelListQuery: query, completion: { result in
            XCTAssertNil(result.error)
            completionCalled = true
        })
        
        // Simulate API response with no channel data
        let payload = ChannelListPayload(channels: [])
        apiClient.test_simulateResponse(.success(payload))
        
        // Assert the data is stored in the DB
        var queryDTO: ChannelListQueryDTO? {
            database.viewContext.channelListQuery(filterHash: query.filter.filterHash)
        }
        AssertAsync {
            Assert.willBeTrue(queryDTO != nil)
            Assert.willBeTrue(completionCalled)
        }
    }

    // MARK: - Reset Channels Query

    func test_resetChannelsQueryGreenPath() throws {
        var query = ChannelListQuery(filter: .in(.members, values: [.unique]))
        query.pagination = Pagination(pageSize: 10, offset: 4)

        try database.writeSynchronously { session in
            session.saveQuery(query: query)
        }

        let expectation = self.expectation(description: "resetChannelsQuery completion")
        var receivedResult: Result<[ChatChannel], Error>!
        listUpdater.resetChannelsQuery(
            for: query,
            watchedChannelIds: Set<ChannelId>(),
            synchedChannelIds: Set<ChannelId>()
        ) { result in
            receivedResult = result
            expectation.fulfill()
        }

        // Simulate API response with channel data
        let cid = ChannelId(type: .messaging, id: .unique)
        let payload = ChannelListPayload(channels: [dummyPayload(with: cid)])
        apiClient.test_simulateRecoveryResponse(.success(payload))

        waitForExpectations(timeout: 0.1, handler: nil)

        let requests = apiClient.recoveryRequest_allRecordedCalls
        XCTAssertEqual(requests.count, 1)
        XCTAssertFalse(receivedResult.isError)

        // Should reset pagination
        query.pagination = Pagination(pageSize: 20, offset: 0)
        let expectedBody = ["payload": query]
        XCTAssertEqual(requests.first?.0.body, expectedBody.asAnyEncodable)
    }

    func test_resetChannelsQuery_QueryNotInDatabase() throws {
        let userId = "UserId"
        var query = ChannelListQuery(filter: .in(.members, values: [userId]))
        try database.writeSynchronously { session in
            try session.saveUser(payload: .dummy(userId: userId))
        }

        let expectation = self.expectation(description: "resetChannelsQuery completion")
        var receivedResult: Result<[ChatChannel], Error>!
        listUpdater.resetChannelsQuery(
            for: query,
            watchedChannelIds: Set<ChannelId>(),
            synchedChannelIds: Set<ChannelId>()
        ) { result in
            receivedResult = result
            expectation.fulfill()
        }

        // Simulate API response with channel data
        let cid = ChannelId(type: .messaging, id: "newChannel")
        let payload = ChannelListPayload(
            channels: [dummyPayload(with: cid, members: [.dummy(user: .dummy(userId: userId))])]
        )
        apiClient.test_simulateRecoveryResponse(.success(payload))

        waitForExpectations(timeout: 0.1, handler: nil)

        let requests = apiClient.recoveryRequest_allRecordedCalls
        XCTAssertEqual(requests.count, 1)
        XCTAssertNil(receivedResult.error)

        // If the query does not exist, the payload should still be saved in database
        XCTAssertEqual(channels(for: query, database: database).count, 1)

        // Should reset pagination
        query.pagination = Pagination(pageSize: 20, offset: 0)
        let expectedBody = ["payload": query]
        XCTAssertEqual(requests.first?.0.body, expectedBody.asAnyEncodable)
    }

    func test_resetChannelsQuery_shouldOnlyRemoveOutdatedAndNotWatchedChannels() throws {
        // Preparation of the environment
        let userId = "UserId"
        let query = ChannelListQuery(filter: .in(.members, values: [userId]))

        let syncedId1 = ChannelId(type: .messaging, id: "syncedId1")
        let syncedId2 = ChannelId(type: .messaging, id: "syncedId2")
        let outdatedId = ChannelId(type: .messaging, id: "outdatedId")
        let watchedId = ChannelId(type: .messaging, id: "watchedId")
        let syncedAndWatchedId = ChannelId(type: .messaging, id: "syncedAndWatchedId")
        let newRemoteChannel = ChannelId(type: .messaging, id: "newRemoteChannel")
        let watchedChannelIds = Set<ChannelId>([syncedAndWatchedId, watchedId])
        let synchedChannelIds = Set<ChannelId>([syncedId1, syncedId2, syncedAndWatchedId])

        try database.writeSynchronously { session in
            try session.saveUser(payload: .dummy(userId: userId))
            try [syncedId1, syncedId2, outdatedId, watchedId, syncedAndWatchedId].forEach {
                let payload = self.dummyPayload(with: $0, members: [.dummy(user: .dummy(userId: userId))])
                try session.saveChannel(payload: payload, query: query)
            }
        }

        XCTAssertEqual(channels(for: query, database: database).count, 5)

        // Reset Channels Query
        let expectation = self.expectation(description: "resetChannelsQuery completion")
        var receivedResult: Result<[ChatChannel], Error>!
        listUpdater.resetChannelsQuery(
            for: query,
            watchedChannelIds: watchedChannelIds,
            synchedChannelIds: synchedChannelIds
        ) { result in
            receivedResult = result
            expectation.fulfill()
        }

        // Simulate API response with channel data
        let payload = ChannelListPayload(channels: [syncedAndWatchedId, syncedId2, newRemoteChannel].map {
            self.dummyPayload(with: $0, members: [.dummy(user: .dummy(userId: userId))])
        })
        apiClient.test_simulateRecoveryResponse(.success(payload))

        waitForExpectations(timeout: 0.2, handler: nil)

        // EXPECTED RESULTS:
        // syncedId1 -> Not present in remote query nor watched:    Removed     -
        // syncedId2 -> Present in remote query:                    Kept        1
        // outdatedId -> Not present in remote query nor watched:   Removed     -
        // watchedId -> Not present in remote query but watched:    Kept        2
        // syncedAndWatchedId -> Present in remote query:           Kept        3
        // newRemoteChannel -> Present in remote query:             Added       4

        let requests = apiClient.recoveryRequest_allRecordedCalls
        XCTAssertEqual(requests.count, 1)
        XCTAssertFalse(receivedResult.isError)
        let channels = self.channels(for: query, database: database)
        XCTAssertEqual(channels.count, 4)
        XCTAssertTrue(channels.contains { $0.cid == syncedId2.rawValue })
        XCTAssertTrue(channels.contains { $0.cid == watchedId.rawValue })
        XCTAssertTrue(channels.contains { $0.cid == syncedAndWatchedId.rawValue })
        XCTAssertTrue(channels.contains { $0.cid == newRemoteChannel.rawValue })

        // Unlinked channels should have been cleared
        let notInQuery = ChannelListQuery(filter: .notIn(.members, values: [userId]))
        let unlinkedChannels = self.channels(for: notInQuery, database: database)
        XCTAssertEqual(unlinkedChannels.count, 0)
    }

    private func channels(for query: ChannelListQuery, database: DatabaseContainer) -> Set<ChannelDTO> {
        let request = NSFetchRequest<ChannelListQueryDTO>(entityName: ChannelListQueryDTO.entityName)
        request.predicate = NSPredicate(format: "filterHash == %@", query.filter.filterHash)
        return (try? database.viewContext.fetch(request).first)?.channels ?? Set()
    }
    
    // MARK: - Fetch
    
    func test_fetch_makesCorrectAPICall() {
        // Simulate `fetch` call
        let query = ChannelListQuery(filter: .in(.members, values: [.unique]))
        listUpdater.fetch(channelListQuery: query, completion: { _ in })
        
        let referenceEndpoint: Endpoint<ChannelListPayload> = .channels(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_fetch_successfulResponse_isPropagatedToCompletion() {
        // Simulate `fetch` call
        let query = ChannelListQuery(filter: .in(.members, values: [.unique]))
        var channelListPayload: ChannelListPayload?
        listUpdater.fetch(channelListQuery: query, completion: { result in
            channelListPayload = try? result.get()
        })
        
        // Simulate API response with channel data
        let cid = ChannelId(type: .messaging, id: .unique)
        let payload = ChannelListPayload(channels: [dummyPayload(with: cid)])
        apiClient.test_simulateResponse(.success(payload))
        
        AssertAsync.willBeEqual(
            Set(payload.channels.map(\.channel.cid)),
            Set(channelListPayload?.channels.map(\.channel.cid) ?? [])
        )
    }
    
    func test_fetch_errorResponse_isPropagatedToCompletion() {
        // Simulate `fetch` call
        let query = ChannelListQuery(filter: .in(.members, values: [.unique]))
        var completionCalledError: Error?
        listUpdater.update(channelListQuery: query, completion: { completionCalledError = $0.error })
        
        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<ChannelListPayload, Error>.failure(error))
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    func test_fetch_doesNotRetainSelf() {
        // Simulate `fetch` call
        listUpdater.fetch(channelListQuery: .init(filter: .in(.members, values: [.unique])), completion: { _ in })
        
        // Assert updater can be deallocated without waiting for the API response.
        AssertAsync.canBeReleased(&listUpdater)
    }
    
    // MARK: - Mark all read
    
    func test_markAllRead_makesCorrectAPICall() {
        listUpdater.markAllRead()
        
        let referenceEndpoint = Endpoint<EmptyResponse>.markAllRead()
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_markAllRead_successfulResponse_isPropagatedToCompletion() {
        var completionCalled = false
        listUpdater.markAllRead { error in
            XCTAssertNil(error)
            completionCalled = true
        }
        
        XCTAssertFalse(completionCalled)
        
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))
        
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_markAllRead_errorResponse_isPropagatedToCompletion() {
        var completionCalledError: Error?
        listUpdater.markAllRead { completionCalledError = $0 }
        
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))
        
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
}
