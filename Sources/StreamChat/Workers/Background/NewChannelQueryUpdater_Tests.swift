//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class NewChannelQueryUpdater_Tests: StressTestCase {
    private var env: TestEnvironment!
    
    var database: DatabaseContainerMock!
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    
    var newChannelQueryUpdater: NewChannelQueryUpdater?
    
    override func setUp() {
        super.setUp()
        env = TestEnvironment()
        
        database = DatabaseContainerMock()
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        
        newChannelQueryUpdater = NewChannelQueryUpdater(
            database: database,
            apiClient: apiClient,
            env: env.environment
        )
    }
    
    override func tearDown() {
        apiClient.cleanUp()
        
        AssertAsync {
            Assert.canBeReleased(&newChannelQueryUpdater)
            Assert.canBeReleased(&database)
            Assert.canBeReleased(&webSocketClient)
            Assert.canBeReleased(&apiClient)
            Assert.canBeReleased(&env)
        }
        
        super.tearDown()
    }
    
    func test_update_called_forEachQuery() throws {
        let filter1: Filter<ChannelListFilterScope> = .equal(.frozen, to: true)
        let filter2: Filter<ChannelListFilterScope> = .equal(.cid, to: .unique)
        
        try database.createChannelListQuery(filter: filter1)
        try database.createChannelListQuery(filter: filter2)
                
        try database.createChannel()
        
        // Assert `update(channelListQuery` called for each query in DB
        AssertAsync.willBeEqual(
            env!.channelQueryUpdater?.update_queries.map(\.filter.filterHash).sorted(),
            [filter1, filter2].map(\.filterHash).sorted()
        )
    }

    func test_update_notCalled_whenNeedsRefreshQueries_isFalse() throws {
        let filter: Filter<ChannelListFilterScope> = .equal(.frozen, to: true)
        try database.createChannelListQuery(filter: filter)

        try database.writeSynchronously { session in
            let dto = try session.saveChannel(payload: XCTestCase().dummyPayload(with: .unique))
            dto.needsRefreshQueries = false
        }

        // Assert `update(channelListQuery:)` is not called
        AssertAsync.staysTrue(env!.channelQueryUpdater?.update_queries.isEmpty == true)
    }

    func test_update_called_forExistingChannel() throws {
        // Deinitialize newChannelQueryUpdater
        newChannelQueryUpdater = nil
        
        let filter: Filter<ChannelListFilterScope> = .equal(.cid, to: .unique)
        try database.createChannelListQuery(filter: filter)
        try database.createChannel(cid: .unique)
        
        // Assert `update(channelListQuery` is not called
        AssertAsync.willBeTrue(env!.channelQueryUpdater?.update_queries.isEmpty)
        
        // Create `newChannelQueryUpdater`
        newChannelQueryUpdater = NewChannelQueryUpdater(
            database: database,
            apiClient: apiClient,
            env: env.environment
        )
        
        // Assert `update(channelListQuery` called for channel that was in DB before observing started
        AssertAsync.willBeEqual(env!.channelQueryUpdater?.update_queries.first?.filter.filterHash, filter.filterHash)
    }

    func test_updater_setsNeedsRefreshQueries_toFalse() throws {
        let filter: Filter<ChannelListFilterScope> = .equal(.frozen, to: true)
        try database.createChannelListQuery(filter: filter)

        let cid: ChannelId = .unique
        try database.createChannel(cid: cid)

        AssertAsync.willBeEqual(env!.channelQueryUpdater?.update_queries.count, 1)

        AssertAsync.willBeEqual(database.viewContext.channel(cid: cid)?.needsRefreshQueries, false)

        // Reset the flag and check if the queries are refreshed
        try database.writeSynchronously {
            let channelDTO = $0.channel(cid: cid)
            channelDTO?.needsRefreshQueries = true
        }

        AssertAsync.willBeEqual(env!.channelQueryUpdater?.update_queries.count, 2)
        AssertAsync.willBeEqual(database.viewContext.channel(cid: cid)?.needsRefreshQueries, false)
    }

    func test_filter_isModified() throws {
        let cid: ChannelId = .unique
        let filter: Filter<ChannelListFilterScope> = .equal(.cid, to: .unique)
        
        try database.createChannelListQuery(filter: filter)
        try database.createChannel(cid: cid)
        
        let expectedFilter: Filter = .and([filter, .equal("cid", to: cid)])
        
        // Assert `update(channelListQuery` called with modified query
        AssertAsync {
            Assert.willBeEqual(self.env!.channelQueryUpdater?.update_queries.first?.filter.filterHash, filter.filterHash)
            Assert.willBeEqual(self.env!.channelQueryUpdater?.update_queries.first?.filter.description, expectedFilter.description)
        }
    }
    
    func test_newChannelQueryUpdater_doesNotRetainItself() throws {
        let filter: Filter<ChannelListFilterScope> = .equal(.cid, to: .unique)
        try database.createChannelListQuery(filter: filter)
        try database.createChannel()
        
        // Assert `update(channelListQuery` is called
        AssertAsync.willBeEqual(env!.channelQueryUpdater?.update_queries.first?.filter.filterHash, filter.filterHash)
        
        // Assert `newChannelQueryUpdater` can be released even though network response hasn't come yet
        AssertAsync.canBeReleased(&newChannelQueryUpdater)
    }
}

private class TestEnvironment {
    var channelQueryUpdater: ChannelListUpdaterMock?
    
    lazy var environment = NewChannelQueryUpdater.Environment(createChannelListUpdater: { [weak self] in
        let channelQueryUpdater = ChannelListUpdaterMock(
            database: $0,
            apiClient: $1
        )
        self?.channelQueryUpdater = channelQueryUpdater
        return channelQueryUpdater
    })
}
