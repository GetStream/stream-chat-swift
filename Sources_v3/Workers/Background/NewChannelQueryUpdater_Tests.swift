//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class NewChannelQueryUpdater_Tests: StressTestCase {
    typealias ExtraData = DefaultDataTypes
    
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
            webSocketClient: webSocketClient,
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
    
    func test_update_called_for_each_query() throws {
        let filter1: Filter = .contains(.unique, String.unique)
        let filter2: Filter = .notEqual(.unique, to: 1)
        
        try database.createChannelListQuery(filter: filter1)
        try database.createChannelListQuery(filter: filter2)
                
        try database.createChannel()
        
        // Assert `update(channelListQuery` called for each query in DB
        AssertAsync.willBeEqual(env!.channelQueryUpdater?.update_calls_counter, 2)
    }
    
    func test_update_called_for_existingChannel() throws {
        // Deinitialize newChannelQueryUpdater
        newChannelQueryUpdater = nil
        
        let filter: Filter = .notEqual(.unique, to: 1)
        try database.createChannelListQuery(filter: filter)
        try database.createChannel(cid: .unique)
        
        // Assert `update(channelListQuery` is not called
        AssertAsync.willBeNil(env!.channelQueryUpdater?.update_query)
        
        // Create `newChannelQueryUpdater`
        newChannelQueryUpdater = NewChannelQueryUpdater(
            database: database,
            webSocketClient: webSocketClient,
            apiClient: apiClient,
            env: env.environment
        )
        
        // Assert `update(channelListQuery` called for channel that was in DB before observing started
        AssertAsync.willBeEqual(env!.channelQueryUpdater?.update_query?.filter.filterHash, filter.filterHash)
    }
    
    func test_filter_is_Modified() throws {
        let cid: ChannelId = .unique
        let filter: Filter = .notEqual(.unique, to: 1)
        
        try database.createChannelListQuery(filter: filter)
        try database.createChannel(cid: cid)
        
        let expectedFilter: Filter = .and([filter, .equal("cid", to: cid)])
        
        // Assert `update(channelListQuery` called with modified query
        AssertAsync {
            Assert.willBeEqual(self.env!.channelQueryUpdater?.update_query?.filter.filterHash, filter.filterHash)
            Assert.willBeEqual(self.env!.channelQueryUpdater?.update_query?.filter.description, expectedFilter.description)
        }
    }
    
    func test_newChannelQueryUpdater_doesNotRetainItself() throws {
        let filter: Filter = .contains(.unique, String.unique)
        try database.createChannelListQuery(filter: filter)
        try database.createChannel()
        
        // Assert `update(channelListQuery` is called
        AssertAsync.willBeEqual(env!.channelQueryUpdater?.update_calls_counter, 1)
        
        // Assert `newChannelQueryUpdater` can be released even though network response hasn't come yet
        AssertAsync.canBeReleased(&newChannelQueryUpdater)
    }
}

private class TestEnvironment {
    var channelQueryUpdater: ChannelListUpdaterMock<DefaultDataTypes>?
    
    lazy var environment = NewChannelQueryUpdater<DefaultDataTypes>.Environment(createChannelListUpdater: { [unowned self] in
        self.channelQueryUpdater = ChannelListUpdaterMock(
            database: $0,
            webSocketClient: $1,
            apiClient: $2
        )
        return self.channelQueryUpdater!
    })
}
