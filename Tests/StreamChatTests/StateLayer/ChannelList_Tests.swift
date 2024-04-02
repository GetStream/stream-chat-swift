//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13.0, *)
final class ChannelList_Tests: XCTestCase {
    private var channelList: ChannelList!
    private var env: TestEnvironment!
    private var memberId: UserId!
    private var testError: TestError!
    
    override func setUpWithError() throws {
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
    
    /// For tests which rely on the channel updater to update the local database.
    private func setUpChannelList(usesMockedChannelUpdater: Bool, dynamicFilter: ((ChatChannel) -> Bool)? = nil) {
        channelList = ChannelList(
            initialChannels: nil,
            query: .init(filter: .in(.members, values: [memberId])),
            dynamicFilter: dynamicFilter,
            channelListUpdater: usesMockedChannelUpdater ? env.channelListUpdaterMock : env.channelListUpdater,
            client: env.client,
            environment: env.channelListEnvironment
        )
    }
    
    private func makeChannels(count: Int) -> [ChatChannel] {
        (0..<count)
            .map { _ in ChatChannel.mock(cid: .unique) }
            .sorted(by: { $0.cid.rawValue < $1.cid.rawValue })
    }
    
    private func makeMatchingChannelPayload() -> ChannelPayload {
        makeMatchingChannelListPayload(channelCount: 1).channels[0]
    }
    
    private func makeMatchingChannelListPayload(channelCount: Int) -> ChannelListPayload {
        let channelPayloads = (0..<channelCount)
            .map { _ in ChannelId(type: .messaging, id: .unique) }
            .map { dummyPayload(with: $0, members: [.dummy(user: .dummy(userId: memberId))]) }
        return ChannelListPayload(channels: channelPayloads)
    }
    
    // MARK: - Restoring State from the Core Data Store
    
    func test_restoringState_whenDatabaseHasEntries_thenStateIsUpdated() async throws {
        let channelListPayload = makeMatchingChannelListPayload(channelCount: 5)
        try await env.client.mockDatabaseContainer.write { session in
            session.saveChannelList(payload: channelListPayload, query: self.channelList.query)
        }
        setUpChannelList(usesMockedChannelUpdater: true)
        XCTAssertEqualIgnoringOrder(channelListPayload.channels.map(\.channel.cid.rawValue), channelList.state.channels.map(\.cid.rawValue))
    }
    
    func test_restoringState_whenDatabaseHasEntriesWhichShouldBeIgnored_thenStateOnlyIncludesQueryMatchingResults() async throws {
        let matchingChannelListPayload = makeMatchingChannelListPayload(channelCount: 5)
        let deletedChannelPayload = makeMatchingChannelPayload()
        try await env.client.mockDatabaseContainer.write { session in
            // These match with the query
            session.saveChannelList(payload: matchingChannelListPayload, query: self.channelList.query)
            // Should be ignored because it was deleted
            let dto = try session.saveChannel(payload: deletedChannelPayload, query: self.channelList.query, cache: nil)
            dto.deletedAt = .unique
            // Unrelated channel to the query
            try session.saveChannel(payload: self.dummyPayload(with: .unique))
        }
        setUpChannelList(usesMockedChannelUpdater: true)
        XCTAssertEqualIgnoringOrder(matchingChannelListPayload.channels.map(\.channel.cid.rawValue), channelList.state.channels.map(\.cid.rawValue))
    }
    
    // MARK: - Pagination and Channel Updater Arguments

    func test_loadChannels_whenChannelUpdaterSucceeds_thenLoadSucceeds() async throws {
        let pageSize = 5
        let responseChannels = makeChannels(count: pageSize)
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
    
    func test_loadNextChannels_whenChannelUpdaterSucceeds_thenLoadSucceeds() async throws {
        let pageSize = 2
        let responseChannels = makeChannels(count: pageSize)
        env.channelListUpdaterMock.update_completion_result = .success(responseChannels)
        let result = try await channelList.loadNextChannels(limit: pageSize)
        
        XCTAssertEqual(env.channelListUpdaterMock.update_queries.count, 1)
        XCTAssertEqual(env.channelListUpdaterMock.update_queries.first?.filter, channelList.query.filter)
        XCTAssertEqual(env.channelListUpdaterMock.update_queries.first?.sort, channelList.query.sort)
        XCTAssertEqual(env.channelListUpdaterMock.update_queries.first?.pagination.pageSize, pageSize)
        XCTAssertEqual(env.channelListUpdaterMock.update_queries.first?.pagination.offset, 0)
        XCTAssertEqual(responseChannels, result)
    }
    
    func test_loadNextChannels_whenChannelUpdaterFails_thenLoadFails() async throws {
        env.channelListUpdaterMock.update_completion_result = .failure(testError)
        await XCTAssertAsyncFailure(try await channelList.loadNextChannels(), testError)
    }
    
    // MARK: - Pagination and State
    
    func test_loadChannels_whenAPIRequestSucceeds_thenStateUpdates() async throws {
        setUpChannelList(usesMockedChannelUpdater: false)
        let pageSize = 2
        let channelListPayload = makeMatchingChannelListPayload(channelCount: pageSize)
        env.client.mockAPIClient.test_mockResponseResult(.success(channelListPayload))

        let pagination = Pagination(pageSize: pageSize, offset: 0)
        let result = try await channelList.loadChannels(with: pagination)
        XCTAssertEqualIgnoringOrder(channelListPayload.channels.map(\.channel.cid.rawValue), result.map(\.cid.rawValue))
        XCTAssertEqualIgnoringOrder(channelListPayload.channels.map(\.channel.cid.rawValue), channelList.state.channels.map(\.cid.rawValue))
    }
    
    func test_loadNextChannels_whenAPIRequestSucceeds_thenStateUpdates() async throws {
        // Initial DB state
        let existingChannelListPayload = makeMatchingChannelListPayload(channelCount: 2)
        try await env.client.mockDatabaseContainer.write { session in
            session.saveChannelList(payload: existingChannelListPayload, query: self.channelList.query)
        }
        setUpChannelList(usesMockedChannelUpdater: false)
        
        // Load more channels
        let nextChannelListPayload = makeMatchingChannelListPayload(channelCount: 3)
        env.client.mockAPIClient.test_mockResponseResult(.success(nextChannelListPayload))
        let result = try await channelList.loadNextChannels()
        XCTAssertEqual(nextChannelListPayload.channels.map(\.channel.cid), result.map(\.cid))
        // State should contain both the existing and next channels
        let expectedChannels = existingChannelListPayload.channels + nextChannelListPayload.channels
        XCTAssertEqualIgnoringOrder(expectedChannels.map(\.channel.cid.rawValue), channelList.state.channels.map(\.cid.rawValue))
    }
    
    // MARK: - Observing the Core Data Store
    
    func test_observingLocalStore_whenStoreChanges_thenStateChanges() async throws {
        let expectation = XCTestExpectation(description: "State changed")
        let incomingChannelListPayload = makeMatchingChannelListPayload(channelCount: 2)
        let cancellable = channelList.state.$channels
            .dropFirst() // ignore initial
            .sink { channels in
                XCTAssertEqualIgnoringOrder(incomingChannelListPayload.channels.map(\.channel.cid.rawValue), channels.map(\.cid.rawValue))
                expectation.fulfill()
            }
        try await env.client.mockDatabaseContainer.write { session in
            session.saveChannelList(payload: incomingChannelListPayload, query: self.channelList.query)
        }
        await fulfillment(of: [expectation], timeout: defaultTimeout)
        cancellable.cancel()
    }
    
    // MARK: - Linking and Unlinking Channels
    
    func test_observingEvents_whenAddedToChannelEventReceived_thenChannelIsLinkedAndStateUpdates() async throws {
        // Allow any channel to be linked by returning true
        setUpChannelList(usesMockedChannelUpdater: false, dynamicFilter: { _ in true })
        // Create channel list
        let existingChannelListPayload = makeMatchingChannelListPayload(channelCount: 1)
        try await env.client.mockDatabaseContainer.write { session in
            session.saveChannelList(payload: existingChannelListPayload, query: self.channelList.query)
        }
        
        // New channel event
        let incomingChannelPayload = makeMatchingChannelPayload()
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
        let cancellable = channelList.state.$channels
            .dropFirst() // ignore initial
            .sink { channels in
                let expectedCids = existingChannelListPayload.channels.map(\.channel.cid.rawValue) + CollectionOfOne(incomingCid.rawValue)
                XCTAssertEqualIgnoringOrder(expectedCids, channels.map(\.cid.rawValue))
                stateExpectation.fulfill()
            }
        
        // Processing the event is picked up by the state
        let eventExpectation = XCTestExpectation(description: "Event processed")
        env.client.eventNotificationCenter.process([event], completion: { eventExpectation.fulfill() })
        await fulfillment(of: [eventExpectation, stateExpectation], timeout: defaultTimeout)
        cancellable.cancel()
    }
    
    func test_observingEvents_whenChannelUpdatedEventReceived_thenChannelIsUnlinkedAndStateUpdates() async throws {
        // Allow unlink a channel
        setUpChannelList(usesMockedChannelUpdater: false, dynamicFilter: { _ in false })
        // Create channel list
        let existingChannelListPayload = makeMatchingChannelListPayload(channelCount: 1)
        let existingCid = try XCTUnwrap(existingChannelListPayload.channels.first?.channel.cid)
        try await env.client.mockDatabaseContainer.write { session in
            session.saveChannelList(payload: existingChannelListPayload, query: self.channelList.query)
        }
        // Ensure that the channel is in the state
        XCTAssertEqualIgnoringOrder(existingChannelListPayload.channels.map(\.channel.cid.rawValue), channelList.state.channels.map(\.cid.rawValue))
        
        let event = ChannelUpdatedEvent(
            channel: .mock(cid: existingCid, memberCount: 4),
            user: .unique,
            message: .unique,
            createdAt: .unique
        )
        let eventExpectation = XCTestExpectation(description: "Event processed")
        env.client.eventNotificationCenter.process([event], completion: { eventExpectation.fulfill() })
        await fulfillment(of: [eventExpectation], timeout: defaultTimeout)
        
        // Ensure the unlinking removed it from the state
        XCTAssertEqual([], channelList.state.channels.map(\.cid))
    }
}

@available(iOS 13.0, *)
extension ChannelList_Tests {
    final class TestEnvironment {
        let client: ChatClient_Mock
        private(set) var channelListState: ChannelListState!
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
            channelListUpdater = ChannelListUpdater(
                database: client.mockDatabaseContainer,
                apiClient: client.mockAPIClient
            )
            channelListUpdaterMock = ChannelListUpdater_Spy(
                database: client.mockDatabaseContainer,
                apiClient: client.mockAPIClient
            )
        }
        
        lazy var channelListEnvironment: ChannelList.Environment = .init(
            stateBuilder: { [unowned self] in
                self.channelListState = ChannelListState(initialChannels: $0, query: $1, dynamicFilter: $2, clientConfig: $3, channelListUpdater: $4, database: $5, eventNotificationCenter: $6)
                return channelListState
            }
        )
    }
}
