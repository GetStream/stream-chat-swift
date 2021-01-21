//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class NewChannelQueryUpdater_Tests: StressTestCase {
    typealias ExtraData = NoExtraData
    
    private var env: TestEnvironment!
    
    var database: DatabaseContainerMock!
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    
    var newChannelQueryUpdater: NewChannelQueryUpdater<ExtraData>?
    
    override func setUp() {
        super.setUp()
        env = TestEnvironment()
        
        database = try! DatabaseContainerMock(kind: .inMemory)
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
        let filter1: Filter<ChannelListFilterScope<NoExtraData>> = .equal(.frozen, to: true)
        let filter2: Filter<ChannelListFilterScope<NoExtraData>> = .equal(.cid, to: .unique)
        
        try database.createChannelListQuery(filter: filter1)
        try database.createChannelListQuery(filter: filter2)
                
        try database.createChannel()
        
        // Assert `update(channelListQuery` called for each query in DB
        AssertAsync.willBeEqual(
            env!.channelQueryUpdater?.update_queries.map(\.filter.filterHash).sorted(),
            [filter1, filter2].map(\.filterHash).sorted()
        )
    }
    
    func test_update_called_forExistingChannel() throws {
        // Deinitialize newChannelQueryUpdater
        newChannelQueryUpdater = nil
        
        let filter: Filter<ChannelListFilterScope<NoExtraData>> = .equal(.cid, to: .unique)
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
    
    func test_filter_isModified() throws {
        let cid: ChannelId = .unique
        let filter: Filter<ChannelListFilterScope<NoExtraData>> = .equal(.cid, to: .unique)
        
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
        let filter: Filter<ChannelListFilterScope<NoExtraData>> = .equal(.cid, to: .unique)
        try database.createChannelListQuery(filter: filter)
        try database.createChannel()
        
        // Assert `update(channelListQuery` is called
        AssertAsync.willBeEqual(env!.channelQueryUpdater?.update_queries.first?.filter.filterHash, filter.filterHash)
        
        // Assert `newChannelQueryUpdater` can be released even though network response hasn't come yet
        AssertAsync.canBeReleased(&newChannelQueryUpdater)
    }
}

private class TestEnvironment {
    var channelQueryUpdater: ChannelListUpdaterMock<NoExtraData>?
    
    lazy var environment = NewChannelQueryUpdater<NoExtraData>.Environment(createChannelListUpdater: { [unowned self] in
        self.channelQueryUpdater = ChannelListUpdaterMock(
            database: $0,
            apiClient: $1
        )
        return self.channelQueryUpdater!
    })
}
