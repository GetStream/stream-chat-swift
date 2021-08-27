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
    
    func test_fetch_called_forEachQuery() throws {
        // Save 2 queries to database
        let query1 = ChannelListQuery(filter: .equal(.frozen, to: true))
        let query2 = ChannelListQuery(filter: .equal(.cid, to: .unique))
        
        try database.createChannelListQuery(query1)
        try database.createChannelListQuery(query2)
        
        // Save new channel to database
        let cid: ChannelId = .unique
        try database.createChannel(cid: cid)
       
        // Assert `fetch(channelListQuery)` is called for each query in DB
        let updatedQuery1 = ChannelListQuery(filter: .and([query1.filter, .equal(.cid, to: cid)]))
        let updatedQuery2 = ChannelListQuery(filter: .and([query2.filter, .equal(.cid, to: cid)]))
        AssertAsync.willBeEqual(
            env!.channelQueryUpdater?.fetch_channelListQueries.map(\.queryHash).sorted(),
            [updatedQuery1, updatedQuery2].map(\.queryHash).sorted()
        )
    }

    func test_fetch_notCalled_whenNeedsRefreshQueries_isFalse() throws {
        // Save a query to database
        let query = ChannelListQuery(filter: .equal(.frozen, to: true))
        try database.createChannelListQuery(query)

        // Save a channel to database that we should not try to link to queries
        let cid: ChannelId = .unique
        try database.createChannel(cid: cid, needsRefreshQueries: false)

        // Assert `fetch(channelListQuery:)` is not called
        AssertAsync.staysTrue(env!.channelQueryUpdater?.fetch_channelListQueries.isEmpty == true)
    }

    func test_fetch_called_forExistingChannel() throws {
        // Deinitialize newChannelQueryUpdater
        newChannelQueryUpdater = nil
        
        // Save a query to database
        let query = ChannelListQuery(filter: .equal(.frozen, to: true))
        try database.createChannelListQuery(query)
        
        // Save a channel to database
        let cid: ChannelId = .unique
        try database.createChannel(cid: cid)
        
        // Assert `fetch(channelListQuery)` is not called
        AssertAsync.willBeTrue(env!.channelQueryUpdater?.fetch_channelListQueries.isEmpty)
        
        // Create `newChannelQueryUpdater`
        newChannelQueryUpdater = NewChannelQueryUpdater(
            database: database,
            apiClient: apiClient,
            env: env.environment
        )
        
        // Assert `fetch(channelListQuery)` called for channel that was in DB before observing started
        let extectedQuery = ChannelListQuery(filter: .and([query.filter, .equal(.cid, to: cid)]))
        AssertAsync.willBeEqual(
            env!.channelQueryUpdater?.fetch_channelListQueries.first?.queryHash,
            extectedQuery.queryHash
        )
    }

    func test_updater_setsNeedsRefreshQueries_toFalse() throws {
        let query = ChannelListQuery(filter: .equal(.frozen, to: true))
        try database.createChannelListQuery(query)

        let cid: ChannelId = .unique
        try database.createChannel(cid: cid)

        AssertAsync.willBeEqual(env!.channelQueryUpdater?.fetch_channelListQueries.count, 1)

        AssertAsync.willBeEqual(database.viewContext.channel(cid: cid)?.needsRefreshQueries, false)

        // Reset the flag and check if the queries are refreshed
        try database.writeSynchronously {
            let channelDTO = $0.channel(cid: cid)
            channelDTO?.needsRefreshQueries = true
        }

        AssertAsync.willBeEqual(env!.channelQueryUpdater?.fetch_channelListQueries.count, 2)
        AssertAsync.willBeEqual(database.viewContext.channel(cid: cid)?.needsRefreshQueries, false)
    }

    func test_filter_isModified() throws {
        let cid: ChannelId = .unique
        let query = ChannelListQuery(filter: .equal(.cid, to: .unique))
        
        try database.createChannelListQuery(query)
        try database.createChannel(cid: cid)
        
        let expectedFilter: Filter = .and([query.filter, .equal(.cid, to: cid)])
        
        // Assert `fetch(channelListQuery)` called with modified query
        AssertAsync {
            Assert.willBeEqual(self.env!.channelQueryUpdater?.fetch_channelListQueries.first?.filter.filterHash, expectedFilter.filterHash)
            Assert.willBeEqual(self.env!.channelQueryUpdater?.fetch_channelListQueries.first?.filter.description, expectedFilter.description)
        }
    }
    
    func test_newChannelQueryUpdater_doesNotRetainItself() throws {
        let query = ChannelListQuery(filter: .equal(.cid, to: .unique))
        try database.createChannelListQuery(query)
        try database.createChannel()
        
        // Assert `fetch(channelListQuery)` is called
        AssertAsync.willBeTrue(env!.channelQueryUpdater?.fetch_channelListQueries.isEmpty == false)
        
        // Assert `newChannelQueryUpdater` can be released even though network response hasn't come yet
        AssertAsync.canBeReleased(&newChannelQueryUpdater)
    }
}

private class TestEnvironment {
    var channelQueryUpdater: ChannelListUpdaterMock?
    
    lazy var environment = NewChannelQueryUpdater.Environment(createChannelListUpdater: { [unowned self] in
        self.channelQueryUpdater = ChannelListUpdaterMock(
            database: $0,
            apiClient: $1
        )
        return self.channelQueryUpdater!
    })
}
