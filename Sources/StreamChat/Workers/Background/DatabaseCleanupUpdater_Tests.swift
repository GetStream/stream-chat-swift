//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class DatabaseCleanupUpdater_Tests: XCTestCase {
    var database: DatabaseContainerMock!
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    
    var databaseCleanupUpdater: DatabaseCleanupUpdater?
    var channelListUpdater: ChannelListUpdaterMock!
    
    override func setUp() {
        super.setUp()
        
        database = DatabaseContainerMock()
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        channelListUpdater = ChannelListUpdaterMock(database: database, apiClient: apiClient)
        
        databaseCleanupUpdater = DatabaseCleanupUpdater(
            database: database,
            apiClient: apiClient,
            channelListUpdater: channelListUpdater
        )
    }
    
    override func tearDown() {
        apiClient.cleanUp()
        
        AssertAsync {
            Assert.canBeReleased(&databaseCleanupUpdater)
            Assert.canBeReleased(&webSocketClient)
        }
        
        super.tearDown()
    }
    
    func test_resetExistingChannelsData_cleansChannelsData() throws {
        let cid1 = ChannelId.unique
        let cid2 = ChannelId.unique
        
        try database.createChannel(
            cid: cid1,
            withMessages: true,
            withQuery: true,
            hiddenAt: .unique
        )
        
        try database.createChannel(
            cid: cid2,
            withMessages: true,
            withQuery: true,
            hiddenAt: .unique
        )
        
        try databaseCleanupUpdater?.resetExistingChannelsData(session: database.viewContext)
        
        let channel1 = try XCTUnwrap(database.viewContext.channel(cid: cid1))
        let channel2 = try XCTUnwrap(database.viewContext.channel(cid: cid2))
        
        AssertAsync {
            Assert.willBeTrue(channel1.isClearedOutProperly)
            Assert.willBeTrue(channel2.isClearedOutProperly)
        }
    }
    
    func test_refetchExistingChannelListQueries_updateQueries() throws {
        let filter1 = Filter<ChannelListFilterScope>.query(.cid, text: .unique)
        let query1 = ChannelListQuery(filter: filter1)
        try database.createChannelListQuery(filter: filter1)
        
        let filter2 = Filter<ChannelListFilterScope>.query(.cid, text: .unique)
        let query2 = ChannelListQuery(filter: filter2)
        try database.createChannelListQuery(filter: filter2)
        
        databaseCleanupUpdater?.refetchExistingChannelListQueries()
        
        AssertAsync.willBeEqual(
            channelListUpdater.update_queries,
            [query1, query2]
        )
    }
        
    func test_refetchExistingChannelListQueries_whenDatabaseCleanupUpdaterIsDeallocated_doesNotUpdateQueries() throws {
        // Create a channel list query to be refetched.
        try database.createChannelListQuery(filter: .query(.cid, text: .unique))
    
        // Initiate channel list queries refetch.
        databaseCleanupUpdater?.refetchExistingChannelListQueries()
        
        // Simulate database-cleanup-updater deallocation.
        databaseCleanupUpdater = nil
        
        // Assert the `channelListUpdater` was not asked to update queries.
        AssertAsync.staysTrue(
            channelListUpdater.update_queries.isEmpty
        )
    }
}

extension ChannelListQuery: Equatable {
    public static func == (lhs: ChannelListQuery, rhs: ChannelListQuery) -> Bool {
        lhs.filter == rhs.filter &&
            lhs.messagesLimit == rhs.messagesLimit &&
            lhs.options == rhs.options &&
            lhs.pagination == rhs.pagination
    }
}

extension ChannelDTO {
    var isClearedOutProperly: Bool {
        messages.isEmpty &&
            currentlyTypingUsers.isEmpty &&
            watchers.isEmpty &&
            members.isEmpty &&
            attachments.isEmpty &&
            pinnedMessages.isEmpty &&
            reads.isEmpty &&
            queries.isEmpty &&
            oldestMessageAt == nil &&
            hiddenAt == nil &&
            truncatedAt == nil
    }
}
