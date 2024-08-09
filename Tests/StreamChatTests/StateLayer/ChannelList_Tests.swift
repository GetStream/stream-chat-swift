//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelList_Tests: XCTestCase {
    private var channelList: ChannelList!
    private var env: TestEnvironment!
    private var memberId: UserId!
    private var testError: TestError!
    
    @MainActor override func setUpWithError() throws {
        memberId = .unique
        testError = TestError()
        env = TestEnvironment()
        setUpChannelList(usesMockedChannelUpdater: true)
    }

    override func tearDownWithError() throws {
        env.cleanUp()
        channelList = nil
        env = nil
        memberId = nil
        testError = nil
    }
    
    // MARK: - Restoring State from the Core Data Store
    
    func test_restoringState_whenDatabaseHasEntries_thenStateIsUpdated() async throws {
        let channelListPayload = makeMatchingChannelListPayload(channelCount: 5, createdAtOffset: 0)
        try await env.client.mockDatabaseContainer.write { session in
            session.saveChannelList(payload: channelListPayload, query: self.channelList.query)
        }
        await setUpChannelList(usesMockedChannelUpdater: true)
        XCTAssertEqual(channelListPayload.channels.map(\.channel.cid.rawValue), await channelList.state.channels.map(\.cid.rawValue))
    }
    
    func test_restoringState_whenDatabaseHasEntriesWhichShouldBeIgnored_thenStateOnlyIncludesQueryMatchingResults() async throws {
        let matchingChannelListPayload = makeMatchingChannelListPayload(channelCount: 5, createdAtOffset: 0)
        let deletedChannelPayload = makeMatchingChannelPayload(createdAtOffset: 5)
        try await env.client.mockDatabaseContainer.write { session in
            // These match with the query
            session.saveChannelList(payload: matchingChannelListPayload, query: self.channelList.query)
            // Should be ignored because it was deleted
            let dto = try session.saveChannel(payload: deletedChannelPayload, query: self.channelList.query, cache: nil)
            dto.deletedAt = .unique
            // Unrelated channel to the query
            try session.saveChannel(payload: self.dummyPayload(with: .unique))
        }
        await setUpChannelList(usesMockedChannelUpdater: true)
        XCTAssertEqual(matchingChannelListPayload.channels.map(\.channel.cid.rawValue), await channelList.state.channels.map(\.cid.rawValue))
    }
    
    // MARK: - Get
    
    func test_get_whenLocalStoreHasChannels_thenGetResetsChannels() async throws {
        // Existing state
        let channelListPayload = makeMatchingChannelListPayload(channelCount: 10, createdAtOffset: 0)
        try await env.client.mockDatabaseContainer.write { session in
            session.saveChannelList(payload: channelListPayload, query: self.channelList.query)
        }
        
        await setUpChannelList(usesMockedChannelUpdater: false)
        await XCTAssertEqual(10, channelList.state.channels.count)
        
        let nextChannelListPayload = makeMatchingChannelListPayload(channelCount: 3, createdAtOffset: 0)
        env.client.mockAPIClient.test_mockResponseResult(.success(nextChannelListPayload))
        try await channelList.get()
        
        await XCTAssertEqual(3, channelList.state.channels.count)
        await XCTAssertEqual(nextChannelListPayload.channels.map(\.channel.cid.rawValue), channelList.state.channels.map(\.cid.rawValue))
    }
    
    func test_get_whenLocalStoreHasNoChannels_thenGetFetchesFirstPageOfChannels() async throws {
        await setUpChannelList(usesMockedChannelUpdater: false)
        await XCTAssertEqual(0, channelList.state.channels.count)
        
        let nextChannelListPayload = makeMatchingChannelListPayload(channelCount: 3, createdAtOffset: 0)
        env.client.mockAPIClient.test_mockResponseResult(.success(nextChannelListPayload))
        try await channelList.get()
        
        await XCTAssertEqual(3, channelList.state.channels.count)
        await XCTAssertEqual(nextChannelListPayload.channels.map(\.channel.cid.rawValue), channelList.state.channels.map(\.cid.rawValue))
    }
    
    // MARK: - Pagination and Channel Updater Arguments
    
    func test_loadChannels_whenChannelUpdaterSucceeds_thenLoadSucceeds() async throws {
        let pageSize = 5
        let responseChannels = makeChannels(count: pageSize, createdAtOffset: 0)
        env.channelListUpdaterMock.update_completion_result = .success(responseChannels)
        
        let pagination = Pagination(pageSize: pageSize, offset: 0)
        let result = try await channelList.loadChannels(with: pagination)
        
        XCTAssertEqual(env.channelListUpdaterMock.update_queries.count, 1)
        XCTAssertEqual(env.channelListUpdaterMock.update_queries.first?.filter, channelList.query.filter)
        XCTAssertEqual(env.channelListUpdaterMock.update_queries.first?.sort, channelList.query.sort)
        XCTAssertEqual(env.channelListUpdaterMock.update_queries.first?.pagination.pageSize, pageSize)
        XCTAssertEqual(env.channelListUpdaterMock.update_queries.first?.pagination.offset, 0)
        XCTAssertEqual(responseChannels, result)
    }
    
    func test_loadChannels_whenChannelUpdaterFails_thenLoadFails() async throws {
        env.channelListUpdaterMock.update_completion_result = .failure(testError)
        let pagination = Pagination(pageSize: 5, offset: 0)
        await XCTAssertAsyncFailure(try await channelList.loadChannels(with: pagination), testError)
    }
    
    func test_loadMoreChannels_whenChannelUpdaterSucceeds_thenLoadSucceeds() async throws {
        let pageSize = 2
        let responseChannels = makeChannels(count: pageSize, createdAtOffset: 0)
        env.channelListUpdaterMock.update_completion_result = .success(responseChannels)
        let result = try await channelList.loadMoreChannels(limit: pageSize)
        
        XCTAssertEqual(env.channelListUpdaterMock.update_queries.count, 1)
        XCTAssertEqual(env.channelListUpdaterMock.update_queries.first?.filter, channelList.query.filter)
        XCTAssertEqual(env.channelListUpdaterMock.update_queries.first?.sort, channelList.query.sort)
        XCTAssertEqual(env.channelListUpdaterMock.update_queries.first?.pagination.pageSize, pageSize)
        XCTAssertEqual(env.channelListUpdaterMock.update_queries.first?.pagination.offset, 0)
        XCTAssertEqual(responseChannels, result)
    }
    
    func test_loadMoreChannels_whenChannelUpdaterFails_thenLoadFails() async throws {
        env.channelListUpdaterMock.update_completion_result = .failure(testError)
        await XCTAssertAsyncFailure(try await channelList.loadMoreChannels(), testError)
    }
    
    // MARK: - Pagination and State
    
    func test_loadChannels_whenAPIRequestSucceeds_thenStateUpdates() async throws {
        await setUpChannelList(usesMockedChannelUpdater: false)
        let pageSize = 2
        let channelListPayload = makeMatchingChannelListPayload(channelCount: pageSize, createdAtOffset: 0)
        env.client.mockAPIClient.test_mockResponseResult(.success(channelListPayload))

        let pagination = Pagination(pageSize: pageSize, offset: 0)
        let result = try await channelList.loadChannels(with: pagination)
        XCTAssertEqual(channelListPayload.channels.map(\.channel.cid.rawValue), result.map(\.cid.rawValue))
        XCTAssertEqual(channelListPayload.channels.map(\.channel.cid.rawValue), await channelList.state.channels.map(\.cid.rawValue))
    }
    
    func test_loadMoreChannels_whenAPIRequestSucceeds_thenStateUpdates() async throws {
        // Initial DB state
        let existingChannelListPayload = makeMatchingChannelListPayload(channelCount: 2, createdAtOffset: 0)
        try await env.client.mockDatabaseContainer.write { session in
            session.saveChannelList(payload: existingChannelListPayload, query: self.channelList.query)
        }
        await setUpChannelList(usesMockedChannelUpdater: false)
        
        // Load more channels
        let nextChannelListPayload = makeMatchingChannelListPayload(channelCount: 3, createdAtOffset: 2)
        env.client.mockAPIClient.test_mockResponseResult(.success(nextChannelListPayload))
        let result = try await channelList.loadMoreChannels()
        XCTAssertEqual(nextChannelListPayload.channels.map(\.channel.cid), result.map(\.cid))
        // State should contain both the existing and next channels
        let expectedChannels = existingChannelListPayload.channels + nextChannelListPayload.channels
        XCTAssertEqual(expectedChannels.map(\.channel.cid.rawValue), await channelList.state.channels.map(\.cid.rawValue))
    }
    
    // MARK: - Observing the Core Data Store
    
    func test_observingLocalStore_whenStoreChanges_thenStateChanges() async throws {
        let expectation = XCTestExpectation(description: "State changed")
        let incomingChannelListPayload = makeMatchingChannelListPayload(channelCount: 2, createdAtOffset: 0)
        let cancellable = await channelList.state.$channels
            .dropFirst() // ignore initial
            .sink { channels in
                XCTAssertEqual(incomingChannelListPayload.channels.map(\.channel.cid.rawValue), channels.map(\.cid.rawValue))
                expectation.fulfill()
            }
        try await env.client.mockDatabaseContainer.write { session in
            session.saveChannelList(payload: incomingChannelListPayload, query: self.channelList.query)
        }
        await fulfillmentCompatibility(of: [expectation], timeout: defaultTimeout)
        cancellable.cancel()
    }
    
    // MARK: - Linking and Unlinking Channels
    
    func test_observingEvents_whenAddedToChannelEventReceived_thenChannelIsLinkedAndStateUpdates() async throws {
        // Allow any channel to be linked by returning true
        await setUpChannelList(usesMockedChannelUpdater: false, dynamicFilter: { _ in true })
        // Create channel list
        let existingChannelListPayload = makeMatchingChannelListPayload(channelCount: 1, createdAtOffset: 0)
        try await env.client.mockDatabaseContainer.write { session in
            session.saveChannelList(payload: existingChannelListPayload, query: self.channelList.query)
        }
        
        // New channel event
        let incomingChannelPayload = makeMatchingChannelPayload(createdAtOffset: 1)
        let incomingCid = incomingChannelPayload.channel.cid
        let event = NotificationAddedToChannelEvent(
            channel: .mock(cid: incomingCid),
            unreadCount: nil,
            member: .mock(id: .unique),
            createdAt: .unique
        )
        // Write the incoming channel to the database
        try await env.client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: incomingChannelPayload)
        }
        
        let stateExpectation = XCTestExpectation(description: "State changed")
        let cancellable = await channelList.state.$channels
            .dropFirst() // ignore initial
            .sink { channels in
                let expectedCids = existingChannelListPayload.channels.map(\.channel.cid.rawValue) + CollectionOfOne(incomingCid.rawValue)
                XCTAssertEqual(expectedCids, channels.map(\.cid.rawValue))
                stateExpectation.fulfill()
            }
        
        // Processing the event is picked up by the state
        let eventExpectation = XCTestExpectation(description: "Event processed")
        env.client.eventNotificationCenter.process([event], completion: { eventExpectation.fulfill() })

        await fulfillmentCompatibility(of: [eventExpectation, stateExpectation], timeout: defaultTimeout, enforceOrder: true)
        cancellable.cancel()
    }
    
    func test_observingEvents_whenChannelUpdatedEventReceived_thenChannelIsUnlinkedAndStateUpdates() async throws {
        // Allow unlink a channel
        await setUpChannelList(usesMockedChannelUpdater: false, dynamicFilter: { _ in false })
        // Create channel list
        let existingChannelListPayload = makeMatchingChannelListPayload(channelCount: 1, createdAtOffset: 0)
        let existingCid = try XCTUnwrap(existingChannelListPayload.channels.first?.channel.cid)
        try await env.client.mockDatabaseContainer.write { session in
            session.saveChannelList(payload: existingChannelListPayload, query: self.channelList.query)
        }
        // Ensure that the channel is in the state
        XCTAssertEqual(existingChannelListPayload.channels.map(\.channel.cid.rawValue), await channelList.state.channels.map(\.cid.rawValue))
        
        let stateExpectation = XCTestExpectation(description: "State changed")
        let cancellable = await channelList.state.$channels
            .dropFirst() // ignore initial
            .sink { channels in
                // Ensure the unlinking removed it from the state
                XCTAssertEqual([], channels.map(\.cid))
                stateExpectation.fulfill()
            }
        
        let event = ChannelUpdatedEvent(
            channel: .mock(cid: existingCid, memberCount: 4),
            user: .unique,
            message: .unique,
            createdAt: .unique
        )
        let eventExpectation = XCTestExpectation(description: "Event processed")
        env.client.eventNotificationCenter.process([event], completion: { eventExpectation.fulfill() })
        await fulfillmentCompatibility(of: [eventExpectation], timeout: defaultTimeout, enforceOrder: true)
        cancellable.cancel()
    }
    
    func test_refreshingChannels_whenMultiplePagesAreLoaded_thenAllAreRefreshed() async throws {
        await setUpChannelList(usesMockedChannelUpdater: false, dynamicFilter: { _ in true })
        
        let pageCount = 2
        let loadedCount = pageCount * Int.channelsPageSize
        let existingChannelListPayload = makeMatchingChannelListPayload(channelCount: loadedCount, createdAtOffset: 0)
        try await env.client.mockDatabaseContainer.write { session in
            session.saveChannelList(payload: existingChannelListPayload, query: self.channelList.query)
        }
        
        // Ensure that the channel is in the state
        XCTAssertEqual(existingChannelListPayload.channels.map(\.channel.cid.rawValue), await channelList.state.channels.map(\.cid.rawValue))
        
        // Record 2 mock responses
        for offset in stride(from: 0, to: loadedCount, by: Int.channelsPageSize) {
            let nextChannelListPayload = makeMatchingChannelListPayload(
                channelCount: Int.channelsPageSize,
                createdAtOffset: offset,
                namePrefix: "Updated Name"
            )
            env.client.mockAPIClient.test_mockResponseResult(.success(nextChannelListPayload))
        }
        
        let refreshedChannelIds = try await channelList.refreshLoadedChannels()
        XCTAssertEqual(loadedCount, refreshedChannelIds.count)
        
        let expectedNames = (0..<loadedCount).map { "Updated Name \($0)" }
        await XCTAssertEqual(expectedNames, channelList.state.channels.compactMap(\.name))
    }
    
    // MARK: - Test Data
    
    /// For tests which rely on the channel updater to update the local database.
    @MainActor private func setUpChannelList(usesMockedChannelUpdater: Bool, loadState: Bool = true, dynamicFilter: ((ChatChannel) -> Bool)? = nil) {
        channelList = ChannelList(
            query: ChannelListQuery(filter: .in(.members, values: [memberId]), sort: [.init(key: .createdAt, isAscending: true)]),
            dynamicFilter: dynamicFilter,
            client: env.client,
            environment: env.channelListEnvironment(usesMockedUpdater: usesMockedChannelUpdater)
        )
        if loadState {
            _ = channelList.state
        }
    }
    
    private func makeChannels(count: Int, createdAtOffset: Int) -> [ChatChannel] {
        (0..<count)
            .map { ChatChannel.mock(cid: .unique, createdAt: Date(timeIntervalSinceReferenceDate: TimeInterval($0 + createdAtOffset))) }
            .sorted(by: { $0.cid.rawValue < $1.cid.rawValue })
    }
    
    private func makeMatchingChannelPayload(createdAtOffset: Int) -> ChannelPayload {
        makeMatchingChannelListPayload(channelCount: 1, createdAtOffset: createdAtOffset).channels[0]
    }
    
    private func makeMatchingChannelListPayload(channelCount: Int, createdAtOffset: Int, namePrefix: String = "Name") -> ChannelListPayload {
        let channelPayloads = (0..<channelCount)
            .map {
                dummyPayload(
                    with: ChannelId(type: .messaging, id: "cid\($0 + createdAtOffset)"),
                    name: "\(namePrefix) \($0 + createdAtOffset)",
                    members: [.dummy(user: .dummy(userId: memberId))],
                    createdAt: Date(timeIntervalSinceReferenceDate: TimeInterval($0 + createdAtOffset))
                )
            }
        return ChannelListPayload(channels: channelPayloads)
    }
}

extension ChannelList_Tests {
    final class TestEnvironment {
        let client: ChatClient_Mock
        private(set) var channelListUpdater: ChannelListUpdater!
        private(set) var channelListUpdaterMock: ChannelListUpdater_Spy!
        
        func cleanUp() {
            client.cleanUp()
            channelListUpdaterMock?.cleanUp()
        }
        
        init() {
            client = ChatClient_Mock(
                config: ChatClient_Mock.defaultMockedConfig
            )
        }
        
        func channelListEnvironment(usesMockedUpdater: Bool) -> ChannelList.Environment {
            ChannelList.Environment(
                channelListUpdater: { [unowned self] in
                    channelListUpdater = ChannelListUpdater(
                        database: $0,
                        apiClient: $1
                    )
                    channelListUpdaterMock = ChannelListUpdater_Spy(
                        database: $0,
                        apiClient: $1
                    )
                    return usesMockedUpdater ? channelListUpdaterMock : channelListUpdater
                }
            )
        }
    }
}

extension XCTestCase {
    func fulfillmentCompatibility(of expectations: [XCTestExpectation], timeout seconds: TimeInterval, enforceOrder enforceOrderOfFulfillment: Bool = false) async {
        #if swift(>=5.8)
        await fulfillment(of: expectations, timeout: seconds, enforceOrder: enforceOrderOfFulfillment)
        #else
        await withCheckedContinuation { continuation in
            Thread.detachNewThread { [self] in
                wait(for: expectations, timeout: seconds, enforceOrder: enforceOrderOfFulfillment)
                continuation.resume()
            }
        }
        #endif
    }
}
