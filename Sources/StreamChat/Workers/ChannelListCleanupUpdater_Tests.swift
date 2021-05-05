//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelListCleanupUpdater_Tests: StressTestCase {
    typealias ExtraData = NoExtraData
        
    var database: DatabaseContainerMock!
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    
    var channelListCleanupUpdater: ChannelListCleanupUpdater<ExtraData>?
    var channelListUpdater: ChannelListUpdaterMock<NoExtraData>!
    
    override func setUp() {
        super.setUp()
        
        database = DatabaseContainerMock()
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        channelListUpdater = ChannelListUpdaterMock(database: database, apiClient: apiClient)
        
        channelListCleanupUpdater = ChannelListCleanupUpdater(
            database: database,
            apiClient: apiClient,
            channelListUpdater: channelListUpdater
        )
    }
    
    override func tearDown() {
        apiClient.cleanUp()
        
        AssertAsync {
            Assert.canBeReleased(&channelListCleanupUpdater)
            Assert.canBeReleased(&database)
            Assert.canBeReleased(&webSocketClient)
            Assert.canBeReleased(&apiClient)
        }
        
        super.tearDown()
    }
    
    func test_cleanupChannelList_cleansChannelsData() throws {
        let cid1 = ChannelId.unique
        let cid2 = ChannelId.unique
        
        try database.createChannel(
            cid: cid1,
            withMessages: true,
            withQuery: true,
            hiddenAt: Date(timeIntervalSince1970: 56789),
            needsRefreshQueries: false
        )
        
        try database.createChannel(
            cid: cid2,
            withMessages: true,
            withQuery: true,
            hiddenAt: Date(timeIntervalSince1970: 56789),
            needsRefreshQueries: false
        )
        
        channelListCleanupUpdater?.cleanupChannelList()
        
        let channel1 = database.viewContext.channel(cid: cid1)!
        let channel2 = database.viewContext.channel(cid: cid2)!
        
        func checkChannelClearedOutProperly(channel: ChannelDTO) {
            AssertAsync.willBeTrue(channel.messages.isEmpty)
            AssertAsync.willBeTrue(channel.currentlyTypingMembers.isEmpty)
            AssertAsync.willBeTrue(channel.watchers.isEmpty)
            AssertAsync.willBeTrue(channel.members.isEmpty)
            AssertAsync.willBeTrue(channel.attachments.isEmpty)
            AssertAsync.willBeTrue(channel.pinnedMessages.isEmpty)
            AssertAsync.willBeTrue(channel.reads.isEmpty)
            AssertAsync.willBeTrue(channel.queries.isEmpty)
            AssertAsync.willBeNil(channel.oldestMessageAt)
            AssertAsync.willBeNil(channel.hiddenAt)
            AssertAsync.willBeNil(channel.truncatedAt)
            AssertAsync.willBeFalse(channel.needsRefreshQueries)
        }
        
        checkChannelClearedOutProperly(channel: channel1)
        checkChannelClearedOutProperly(channel: channel2)
    }
    
    func test_cleanupChannelList_updatesChannels() throws {
        let filter1 = Filter<_ChannelListFilterScope<ExtraData>>.query(.cid, text: .unique)
        let query1 = _ChannelListQuery<ExtraData>(filter: filter1)
        try database.createChannelListQuery(filter: filter1)
        
        let filter2 = Filter<_ChannelListFilterScope<ExtraData>>.query(.cid, text: .unique)
        let query2 = _ChannelListQuery<ExtraData>(filter: filter2)
        try database.createChannelListQuery(filter: filter2)
        
        channelListCleanupUpdater?.cleanupChannelList()
        
        AssertAsync.willBeEqual(
            channelListUpdater.update_queries,
            [query1, query2]
        )
    }
}

extension _ChannelListQuery: Equatable {
    public static func == (lhs: _ChannelListQuery<ExtraData>, rhs: _ChannelListQuery<ExtraData>) -> Bool {
        lhs.filter == rhs.filter &&
            lhs.messagesLimit == rhs.messagesLimit &&
            lhs.options == rhs.options &&
            lhs.pagination == rhs.pagination
    }
}
