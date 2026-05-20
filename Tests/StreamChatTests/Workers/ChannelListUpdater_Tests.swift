//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        nonisolated(unsafe) var completionCalled = false
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
        nonisolated(unsafe) var completionCalledError: Error?
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
        nonisolated(unsafe) var completionCalled = false
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
            database.viewContext.channelListQuery(query)
        }
        AssertAsync {
            Assert.willBeTrue(queryDTO != nil)
        }
    }

    func test_update_whenSuccess_whenFirstFetch_shouldRemoveAllPreviousChannelsFromQuery() throws {
        nonisolated(unsafe) var query = ChannelListQuery(
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
            database.viewContext.channelListQuery(query)?.channels.compactMap { try? $0.asModel() } ?? []
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
        nonisolated(unsafe) var query = ChannelListQuery(
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
            database.viewContext.channelListQuery(query)?.channels.compactMap { try? $0.asModel() } ?? []
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
        nonisolated(unsafe) var query = ChannelListQuery(
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
            database.viewContext.channelListQuery(query)?.channels.compactMap { try? $0.asModel() } ?? []
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
        nonisolated(unsafe) var channelListPayload: ChannelListPayload?
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
        nonisolated(unsafe) var completionCalledError: Error?
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
        nonisolated(unsafe) var query = ChannelListQuery(filter: .in(.members, values: [.unique]))
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
        nonisolated(unsafe) var completionCalled = false
        listUpdater.markAllRead { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)

        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        AssertAsync.willBeTrue(completionCalled)
    }

    func test_markAllRead_errorResponse_isPropagatedToCompletion() {
        nonisolated(unsafe) var completionCalledError: Error?
        listUpdater.markAllRead { completionCalledError = $0 }

        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Start Watching Channels

    func test_startWatchingChannels_whenFetchCallSuccess_thenSavePayload_thenCallCompletionWithoutError() {
        // When
        nonisolated(unsafe) var actualError: Error?
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
        nonisolated(unsafe) var actualError: Error?
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
            database.viewContext.channelListQuery(query)?.channels.compactMap { try? $0.asModel() } ?? []
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
            database.viewContext.channelListQuery(query)?.channels.compactMap { try? $0.asModel() } ?? []
        }

        XCTAssertTrue(channelsInQuery.contains(where: { $0.cid == channel.cid }))

        listUpdater.unlink(channel: channel, with: query) { _ in
            exp.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertFalse(channelsInQuery.contains(channel))
    }

    // MARK: - queryGroupedChannels

    func test_queryGroupedChannels_initial_sendsBodyWithoutGroupsKey() throws {
        listUpdater.queryGroupedChannels(groupPagination: nil, limit: 10, watch: false, presence: false, completion: { _ in })

        let body = try XCTUnwrap(apiClient.request_endpoint?.bodyAsDictionary())
        XCTAssertEqual(10, body["limit"] as? Int)
        XCTAssertNil(body["groups"])
    }

    func test_queryGroupedChannels_paginated_sendsBodyWithGroupsKeyAndCursor() throws {
        let pagination = GroupedChannelsPagination(groupKey: "old", next: "old-cursor")
        listUpdater.queryGroupedChannels(
            groupPagination: pagination,
            limit: 5,
            watch: false,
            presence: false,
            completion: { _ in }
        )

        let body = try XCTUnwrap(apiClient.request_endpoint?.bodyAsDictionary())
        XCTAssertNil(body["limit"], "top-level limit must be omitted when paginating")
        let groups = try XCTUnwrap(body["groups"] as? [String: [String: Any]])
        XCTAssertEqual(["old"], groups.keys.sorted())
        XCTAssertEqual(5, groups["old"]?["limit"] as? Int)
        XCTAssertEqual("old-cursor", groups["old"]?["next"] as? String)
        XCTAssertNil(groups["old"]?["prev"])
    }

    func test_queryGroupedChannels_response_populatesNextOnGroup() throws {
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: .unique, role: .user))
        }
        nonisolated(unsafe) var completionResult: Result<[ChannelGroup], Error>?
        let exp = expectation(description: "completion called")
        listUpdater.queryGroupedChannels(groupPagination: nil, limit: nil, watch: false, presence: false) { result in
            completionResult = result
            exp.fulfill()
        }

        let groupPayload = GroupedQueryChannelsGroupPayload(
            channels: [],
            unreadChannels: 3,
            next: "next-cursor"
        )
        let payload = GroupedQueryChannelsPayload(groups: ["current": groupPayload])
        apiClient.test_simulateResponse(.success(payload))

        waitForExpectations(timeout: defaultTimeout)
        let group = try completionResult?.get().first { $0.groupKey == "current" }
        XCTAssertEqual("next-cursor", group?.next)
    }

    func test_queryGroupedChannels_paginated_doesNotOverwriteGroupedUnreadCount() throws {
        // Seed current user with unread counts for multiple groups.
        let userId = UserId.unique
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: userId, role: .user))
            try session.saveCurrentUserGroupedUnreadCount(["new": 5, "current": 10, "old": 2])
        }

        let pagination = GroupedChannelsPagination(groupKey: "old", next: "cursor")
        nonisolated(unsafe) var completionCalled = false
        listUpdater.queryGroupedChannels(groupPagination: pagination, limit: nil, watch: false, presence: false) { _ in
            completionCalled = true
        }

        // Paginated response carries only "old" group.
        let payload = GroupedQueryChannelsPayload(
            groups: ["old": .init(channels: [], unreadChannels: 99)]
        )
        apiClient.test_simulateResponse(.success(payload))

        AssertAsync.willBeTrue(completionCalled)

        // Other groups' counters must remain intact (would be clobbered if mapValues ran).
        let counters = database.viewContext.currentUser?.groupedUnreadCount ?? [:]
        XCTAssertEqual(5, counters["new"])
        XCTAssertEqual(10, counters["current"])
        XCTAssertEqual(2, counters["old"])
    }

    func test_queryGroupedChannels_initial_linksChannelsToQueryDTOPerGroupKey() throws {
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: .unique, role: .user))
        }
        let allCid1 = ChannelId(type: .messaging, id: .unique)
        let allCid2 = ChannelId(type: .messaging, id: .unique)
        let newCid = ChannelId(type: .messaging, id: .unique)
        let allChannels = [self.dummyPayload(with: allCid1), self.dummyPayload(with: allCid2)]
        let newChannels = [self.dummyPayload(with: newCid)]

        let exp = expectation(description: "completion called")
        listUpdater.queryGroupedChannels(groupPagination: nil, limit: nil, watch: false, presence: false) { _ in exp.fulfill() }
        let payload = GroupedQueryChannelsPayload(
            groups: [
                "all": .init(channels: allChannels, unreadChannels: 0),
                "new": .init(channels: newChannels, unreadChannels: 0)
            ]
        )
        apiClient.test_simulateResponse(.success(payload))
        waitForExpectations(timeout: defaultTimeout)

        let allLinked = try XCTUnwrap(database.viewContext.channelListQuery(ChannelListQuery(groupKey: "all")))
        let newLinked = try XCTUnwrap(database.viewContext.channelListQuery(ChannelListQuery(groupKey: "new")))
        XCTAssertEqual(Set([allCid1.rawValue, allCid2.rawValue]), Set(allLinked.channels.map(\.cid)))
        XCTAssertEqual(Set([newCid.rawValue]), Set(newLinked.channels.map(\.cid)))
    }

    func test_queryGroupedChannels_initialFetchForSingleGroup_resetsAndLinks() throws {
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: .unique, role: .user))
        }
        let staleCid = ChannelId(type: .messaging, id: .unique)
        try database.writeSynchronously { session in
            let staleDTO = try session.saveChannel(payload: self.dummyPayload(with: staleCid))
            let queryDTO = session.saveQuery(query: ChannelListQuery(groupKey: "all"))
            queryDTO.channels.insert(staleDTO)
        }
        let freshCid = ChannelId(type: .messaging, id: .unique)
        let freshChannels = [self.dummyPayload(with: freshCid)]

        let pagination = GroupedChannelsPagination(groupKey: "all", next: nil)
        let exp = expectation(description: "completion called")
        listUpdater.queryGroupedChannels(groupPagination: pagination, limit: nil, watch: false, presence: false) { _ in exp.fulfill() }
        let payload = GroupedQueryChannelsPayload(
            groups: ["all": .init(channels: freshChannels, unreadChannels: 0)]
        )
        apiClient.test_simulateResponse(.success(payload))
        waitForExpectations(timeout: defaultTimeout)

        let linked = try XCTUnwrap(database.viewContext.channelListQuery(ChannelListQuery(groupKey: "all")))
        XCTAssertEqual(Set([freshCid.rawValue]), Set(linked.channels.map(\.cid)))
        XCTAssertNil(linked.next)
    }

    func test_queryGroupedChannels_persistsNextCursorOnQueryDTO() throws {
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: .unique, role: .user))
        }
        let exp = expectation(description: "completion called")
        listUpdater.queryGroupedChannels(groupPagination: nil, limit: nil, watch: false, presence: false) { _ in exp.fulfill() }
        let payload = GroupedQueryChannelsPayload(
            groups: [
                "all": .init(channels: [], unreadChannels: 0, next: "all-next", prev: nil),
                "exhausted": .init(channels: [], unreadChannels: 0, next: nil, prev: nil)
            ]
        )
        apiClient.test_simulateResponse(.success(payload))
        waitForExpectations(timeout: defaultTimeout)

        let allLinked = try XCTUnwrap(database.viewContext.channelListQuery(ChannelListQuery(groupKey: "all")))
        let exhaustedLinked = try XCTUnwrap(database.viewContext.channelListQuery(ChannelListQuery(groupKey: "exhausted")))
        XCTAssertEqual("all-next", allLinked.next)
        XCTAssertNil(exhaustedLinked.next)
    }

    func test_queryGroupedChannels_paginatedContinuation_appendsToQueryDTOWithoutReset() throws {
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: .unique, role: .user))
        }
        let existingCid = ChannelId(type: .messaging, id: .unique)
        try database.writeSynchronously { session in
            let existingDTO = try session.saveChannel(payload: self.dummyPayload(with: existingCid))
            let queryDTO = session.saveQuery(query: ChannelListQuery(groupKey: "all"))
            queryDTO.channels.insert(existingDTO)
        }
        let appendedCid = ChannelId(type: .messaging, id: .unique)
        let appendedChannels = [self.dummyPayload(with: appendedCid)]

        let pagination = GroupedChannelsPagination(groupKey: "all", next: "cursor-1")
        let exp = expectation(description: "completion called")
        listUpdater.queryGroupedChannels(groupPagination: pagination, limit: nil, watch: false, presence: false) { _ in exp.fulfill() }
        let payload = GroupedQueryChannelsPayload(
            groups: ["all": .init(channels: appendedChannels, unreadChannels: 0)]
        )
        apiClient.test_simulateResponse(.success(payload))
        waitForExpectations(timeout: defaultTimeout)

        let linked = try XCTUnwrap(database.viewContext.channelListQuery(ChannelListQuery(groupKey: "all")))
        XCTAssertEqual(Set([existingCid.rawValue, appendedCid.rawValue]), Set(linked.channels.map(\.cid)))
    }

    private func channels(for query: ChannelListQuery, database: DatabaseContainer) -> Set<ChannelDTO> {
        let request = NSFetchRequest<ChannelListQueryDTO>(entityName: ChannelListQueryDTO.entityName)
        request.predicate = NSPredicate(format: "filterHash == %@", query.filter.filterHash)
        return (try? database.viewContext.fetch(request).first)?.channels ?? Set()
    }
}
