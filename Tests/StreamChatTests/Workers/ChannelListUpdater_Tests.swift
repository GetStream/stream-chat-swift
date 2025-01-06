//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
    
    // MARK: - Refresh Loaded Channels
    
    func test_refreshLoadedChannels_whenEmpty_thenRefreshDoesNotHappen() async throws {
        var query = ChannelListQuery(filter: .in(.members, values: [.unique]))
        query.pagination = Pagination(pageSize: 10)
        let initialLoadedChannelCount = 0
        
        let cids = try await listUpdater.refreshLoadedChannels(for: query, channelCount: initialLoadedChannelCount)
        XCTAssertEqual(Set(), cids)
    }
    
    func test_refreshLoadedChannels_whenMultiplePagesAreLoaded_thenAllPagesAreReloaded() async throws {
        let pageSize = Int.channelsPageSize
        var query = ChannelListQuery(filter: .in(.members, values: [.unique]))
        query.pagination = Pagination(pageSize: pageSize)
        
        let initialChannels = (0..<pageSize * 2 + 5)
            .map { self.dummyPayload(with: ChannelId(type: .messaging, id: "\($0)")) }
        try database.writeSynchronously { session in
            session.saveChannelList(payload: .init(channels: initialChannels), query: query)
        }
        
        // Refresh should be called 3 times
        let responseChannels = (0..<pageSize * 2 + 5)
            .map { self.dummyPayload(with: ChannelId(type: .messaging, id: "\($0)_refreshed")) }
        apiClient.test_mockResponseResult(.success(ChannelListPayload(channels: Array(responseChannels[0..<pageSize]))))
        apiClient.test_mockResponseResult(.success(ChannelListPayload(channels: Array(responseChannels[pageSize..<pageSize * 2]))))
        apiClient.test_mockResponseResult(.success(ChannelListPayload(channels: Array(responseChannels[(pageSize * 2)...]))))
        
        let cids = try await listUpdater.refreshLoadedChannels(for: query, channelCount: initialChannels.count)
        XCTAssertEqual(responseChannels.map(\.channel.cid.id).sorted(), cids.map(\.id).sorted())
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
