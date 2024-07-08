//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelListUpdater_Tests: XCTestCase {
    var webSocketClient: WebSocketClient_Mock!
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer!

    var listUpdater: ChannelListUpdater!

    override func setUp() {
        super.setUp()

        webSocketClient = WebSocketClient_Mock()
        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()

        listUpdater = ChannelListUpdater(database: database, apiClient: apiClient)
    }

    override func tearDown() {
        apiClient.cleanUp()

        AssertAsync {
            Assert.canBeReleased(&apiClient)
            Assert.canBeReleased(&listUpdater)
            Assert.canBeReleased(&database)
            Assert.canBeReleased(&webSocketClient)
        }

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

        AssertAsync.willBeTrue(completionCalled)

        // Assert the data is stored in the DB
        var channel: ChatChannel? {
            try? database.viewContext.channel(cid: cid)?.asModel()
        }
        AssertAsync {
            Assert.willBeTrue(channel != nil)
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

        AssertAsync.willBeTrue(completionCalled)

        // Assert the data is stored in the DB
        var queryDTO: ChannelListQueryDTO? {
            database.viewContext.channelListQuery(filterHash: query.filter.filterHash)
        }
        AssertAsync {
            Assert.willBeTrue(queryDTO != nil)
        }
    }

    func test_update_whenSuccess_whenFirstFetch_shouldRemoveAllPreviousChannelsFromQuery() throws {
        var query = ChannelListQuery(
            filter: .in(.members, values: [.unique])
        )
        query.pagination = .init(pageSize: 25, offset: 0)

        try database.writeSynchronously { session in
            let queryDTO = session.saveQuery(query: query)
            queryDTO.channels.insert(try session.saveChannel(payload: .dummy()))
            queryDTO.channels.insert(try session.saveChannel(payload: .dummy()))
            queryDTO.channels.insert(try session.saveChannel(payload: .dummy()))
        }

        var channelsFromQuery: [ChatChannel] {
            database.viewContext.channelListQuery(
                filterHash: query.filter.filterHash
            )?.channels.compactMap { try? $0.asModel() } ?? []
        }

        XCTAssertEqual(channelsFromQuery.count, 3)

        let exp = expectation(description: "update completes")
        listUpdater.update(channelListQuery: query, completion: { result in
            XCTAssertNil(result.error)
            exp.fulfill()
        })

        let cid = ChannelId(type: .messaging, id: .unique)
        let payload = ChannelListPayload(channels: [dummyPayload(with: cid)])
        apiClient.test_simulateResponse(.success(payload))

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(channelsFromQuery.count, 1)
    }

    func test_update_whenSuccess_whenNotFirstFetch_shouldContinueChannelsFromQuery() throws {
        var query = ChannelListQuery(
            filter: .in(.members, values: [.unique])
        )
        query.pagination = .init(pageSize: 25, offset: 25)

        try database.writeSynchronously { session in
            let queryDTO = session.saveQuery(query: query)
            queryDTO.channels.insert(try session.saveChannel(payload: .dummy()))
            queryDTO.channels.insert(try session.saveChannel(payload: .dummy()))
            queryDTO.channels.insert(try session.saveChannel(payload: .dummy()))
        }

        var channelsFromQuery: [ChatChannel] {
            database.viewContext.channelListQuery(
                filterHash: query.filter.filterHash
            )?.channels.compactMap { try? $0.asModel() } ?? []
        }

        XCTAssertEqual(channelsFromQuery.count, 3)

        let exp = expectation(description: "update completes")
        listUpdater.update(channelListQuery: query, completion: { result in
            XCTAssertNil(result.error)
            exp.fulfill()
        })

        let cid = ChannelId(type: .messaging, id: .unique)
        let payload = ChannelListPayload(channels: [dummyPayload(with: cid)])
        apiClient.test_simulateResponse(.success(payload))

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(channelsFromQuery.count, 4)
    }

    func test_update_whenError_shouldContinueChannelsFromQuery() throws {
        var query = ChannelListQuery(
            filter: .in(.members, values: [.unique])
        )
        query.pagination = .init(pageSize: 25, offset: 25)

        try database.writeSynchronously { session in
            let queryDTO = session.saveQuery(query: query)
            queryDTO.channels.insert(try session.saveChannel(payload: .dummy()))
            queryDTO.channels.insert(try session.saveChannel(payload: .dummy()))
            queryDTO.channels.insert(try session.saveChannel(payload: .dummy()))
        }

        var channelsFromQuery: [ChatChannel] {
            database.viewContext.channelListQuery(
                filterHash: query.filter.filterHash
            )?.channels.compactMap { try? $0.asModel() } ?? []
        }

        XCTAssertEqual(channelsFromQuery.count, 3)

        let exp = expectation(description: "update completes")
        listUpdater.update(channelListQuery: query, completion: { result in
            XCTAssertNotNil(result.error)
            exp.fulfill()
        })

        let result: Result<ChannelListPayload, Error> = .failure(TestError())
        apiClient.test_simulateResponse(result)

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(channelsFromQuery.count, 3)
    }

    // MARK: - Reset Channels Query

    func test_resetChannelsQueryGreenPath() throws {
        var query = ChannelListQuery(filter: .in(.members, values: [.unique]))
        query.pagination = Pagination(pageSize: 10, offset: 4)

        try database.writeSynchronously { session in
            session.saveQuery(query: query)
        }

        let expectation = self.expectation(description: "resetChannelsQuery completion")
        var receivedResult: Result<(synchedAndWatched: [ChatChannel], unwanted: Set<ChannelId>), Error>!
        listUpdater.resetChannelsQuery(
            for: query,
            pageSize: query.pagination.pageSize,
            watchedAndSynchedChannelIds: Set<ChannelId>(),
            synchedChannelIds: Set<ChannelId>()
        ) { result in
            receivedResult = result
            expectation.fulfill()
        }

        // Simulate API response with channel data
        let cid = ChannelId(type: .messaging, id: .unique)
        let payload = ChannelListPayload(channels: [dummyPayload(with: cid)])
        apiClient.test_simulateRecoveryResponse(.success(payload))

        waitForExpectations(timeout: defaultTimeout, handler: nil)

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
        var receivedResult: Result<(synchedAndWatched: [ChatChannel], unwanted: Set<ChannelId>), Error>!
        listUpdater.resetChannelsQuery(
            for: query,
            pageSize: query.pagination.pageSize,
            watchedAndSynchedChannelIds: Set<ChannelId>(),
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

        waitForExpectations(timeout: defaultTimeout, handler: nil)

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
        let localId = ChannelId(type: .messaging, id: "localId")
        let outdatedId = ChannelId(type: .messaging, id: "outdatedId")
        let watchedAndSynchedId = ChannelId(type: .messaging, id: "watchedAndSynchedId")
        let syncedAndWatchedId = ChannelId(type: .messaging, id: "syncedAndWatchedId")
        let newRemoteChannel = ChannelId(type: .messaging, id: "newRemoteChannel")
        let watchedChannelIds = Set<ChannelId>([syncedAndWatchedId, watchedAndSynchedId])
        let synchedChannelIds = Set<ChannelId>([syncedId1, syncedId2, syncedAndWatchedId])

        try database.writeSynchronously { session in
            try session.saveUser(payload: .dummy(userId: userId))
            try [syncedId1, syncedId2, outdatedId, watchedAndSynchedId, syncedAndWatchedId, localId].forEach {
                let payload = self.dummyPayload(with: $0, members: [.dummy(user: .dummy(userId: userId))])
                try session.saveChannel(payload: payload, query: query, cache: nil)
            }
        }

        XCTAssertEqual(channels(for: query, database: database).count, 6)

        // Reset Channels Query
        let expectation = self.expectation(description: "resetChannelsQuery completion")
        var receivedResult: Result<(synchedAndWatched: [ChatChannel], unwanted: Set<ChannelId>), Error>!
        listUpdater.resetChannelsQuery(
            for: query,
            pageSize: query.pagination.pageSize,
            watchedAndSynchedChannelIds: watchedChannelIds,
            synchedChannelIds: synchedChannelIds
        ) { result in
            receivedResult = result
            expectation.fulfill()
        }

        // Simulate API response with channel data
        let payload = ChannelListPayload(channels: [syncedAndWatchedId, syncedId2, newRemoteChannel, localId].map {
            self.dummyPayload(with: $0, numberOfMessages: 0, members: [.dummy(user: .dummy(userId: userId))])
        })
        apiClient.test_simulateRecoveryResponse(.success(payload))

        waitForExpectations(timeout: defaultTimeout, handler: nil)

        // EXPECTED RESULTS:
        // syncedId1 -> Not present in remote query, but synched:               Unwanted    -
        // syncedId2 -> Present in local and remote query, synched:             Kept        1
        // outdatedId -> Not present in remote query, not synched:              Unwanted    -
        // localId -> Present in local and remote query, not synched:           Cleaned     2
        // watchedAndSynchedId -> Not present in remote query, but watched:     Unlinked    -
        // syncedAndWatchedId -> Present in local and remote query, watched:    Kept        3
        // newRemoteChannel -> Present in remote query only:                    Added       4

        let requests = apiClient.recoveryRequest_allRecordedCalls
        XCTAssertEqual(requests.count, 1)
        XCTAssertFalse(receivedResult.isError)

        // Two channels were marked as unwanted
        XCTAssertEqual(receivedResult.value?.unwanted.count, 2)
        XCTAssertTrue(receivedResult.value?.unwanted.contains { $0 == outdatedId } == true)
        XCTAssertTrue(receivedResult.value?.unwanted.contains { $0 == syncedId1 } == true)

        // Four channels were synched and watched, and are now part of the query
        XCTAssertEqual(receivedResult.value?.synchedAndWatched.count, 4)
        let queryChannels = channels(for: query, database: database)
        XCTAssertEqual(queryChannels.count, 4)
        [syncedId2, localId, syncedAndWatchedId, newRemoteChannel].forEach { cid in
            XCTAssertTrue(queryChannels.contains { $0.cid == cid.rawValue })
        }

        // No channel should have been removed yet here
        let allChannels = (try? database.viewContext.fetch(ChannelDTO.allChannelsFetchRequest)) ?? []
        XCTAssertEqual(allChannels.count, 7)

        // Cleaned channel should not have messages
        XCTAssertEqual(queryChannels.first { $0.cid == localId.rawValue }?.messages.count, 0)

        // Unlinked channels should not have been cleared
        XCTAssertEqual(allChannels.first { $0.cid == syncedId1.rawValue }?.messages.count, 1)
        XCTAssertEqual(allChannels.first { $0.cid == watchedAndSynchedId.rawValue }?.messages.count, 1)
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

    // MARK: - Start Watching Channels

    func test_startWatchingChannels_whenFetchCallSuccess_thenSavePayload_thenCallCompletionWithoutError() {
        // When
        var actualError: Error?
        let exp = expectation(description: "fetch call completes with success")
        let cids: [ChannelId] = [.unique, .unique, .unique]
        listUpdater.startWatchingChannels(withIds: cids) { error in
            actualError = error
            exp.fulfill()
        }
        let payload = ChannelListPayload(channels: cids.map { dummyPayload(with: $0) })
        apiClient.test_simulateResponse(.success(payload))

        // Then
        wait(for: [exp], timeout: defaultTimeout)
        let expectedQuery = ChannelListQuery(filter: .in(.cid, values: cids))
        let expectedEndpoint: Endpoint<ChannelListPayload> = .channels(query: expectedQuery)
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), apiClient.request_endpoint)
        XCTAssertEqual(
            Set(cids.compactMap { try? database.viewContext.channel(cid: $0)?.asModel().cid }),
            Set(cids)
        )
        XCTAssertNil(actualError)
    }

    func test_startWatchingChannels_whenFetchCallFail_thenCallCompletionWithError() {
        // When
        var actualError: Error?
        let exp = expectation(description: "fetch call completes with success")
        let cids: [ChannelId] = [.unique, .unique, .unique]
        listUpdater.startWatchingChannels(withIds: cids) { error in
            actualError = error
            exp.fulfill()
        }
        let error = TestError()
        apiClient.test_simulateResponse(Result<ChannelListPayload, Error>.failure(error))

        // Then
        wait(for: [exp], timeout: defaultTimeout)
        let expectedQuery = ChannelListQuery(filter: .in(.cid, values: cids))
        let expectedEndpoint: Endpoint<ChannelListPayload> = .channels(query: expectedQuery)
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), apiClient.request_endpoint)
        XCTAssertNotNil(actualError)
    }

    func test_link_shouldAddChannelToQuery() throws {
        let exp = expectation(description: "link completion is called")
        let channel = ChatChannel.mock(cid: .unique)
        let query = ChannelListQuery(filter: .noTeam)

        try database.writeSynchronously { session in
            try session.saveChannel(
                payload: .dummy(channel: .dummy(cid: channel.cid))
            )
            session.saveQuery(query: query)
        }

        listUpdater.link(channel: channel, with: query) { _ in
            exp.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)

        var channelsInQuery: [ChatChannel] {
            database.viewContext.channelListQuery(
                filterHash: query.filter.filterHash
            )?.channels.compactMap { try? $0.asModel() } ?? []
        }

        XCTAssertTrue(channelsInQuery.contains(where: { $0.cid == channel.cid }))
    }

    func test_unlink_shouldRemoveChannelFromQuery() throws {
        let exp = expectation(description: "unlink completion is called")
        let channel = ChatChannel.mock(cid: .unique)
        let query = ChannelListQuery(filter: .noTeam)

        try database.writeSynchronously { session in
            let channelDTO = try session.saveChannel(
                payload: .dummy(channel: .dummy(cid: channel.cid))
            )
            let queryDTO = session.saveQuery(query: query)
            queryDTO.channels.insert(channelDTO)
        }

        var channelsInQuery: [ChatChannel] {
            database.viewContext.channelListQuery(
                filterHash: query.filter.filterHash
            )?.channels.compactMap { try? $0.asModel() } ?? []
        }

        XCTAssertTrue(channelsInQuery.contains(where: { $0.cid == channel.cid }))

        listUpdater.unlink(channel: channel, with: query) { _ in
            exp.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertFalse(channelsInQuery.contains(channel))
    }

    private func channels(for query: ChannelListQuery, database: DatabaseContainer) -> Set<ChannelDTO> {
        let request = NSFetchRequest<ChannelListQueryDTO>(entityName: ChannelListQueryDTO.entityName)
        request.predicate = NSPredicate(format: "filterHash == %@", query.filter.filterHash)
        return (try? database.viewContext.fetch(request).first)?.channels ?? Set()
    }
}
