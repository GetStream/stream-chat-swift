//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class DatabaseCleanupUpdater_Tests: StressTestCase {
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
            Assert.canBeReleased(&database)
            Assert.canBeReleased(&webSocketClient)
            Assert.canBeReleased(&apiClient)
        }
        
        super.tearDown()
    }
    
//    func test_syncChannelListQueries_happyPath() throws {
//        // Create current user in database
//        let currentUserId: UserId = .unique
//        try database.createCurrentUser(id: currentUserId)
//
//        // Create first query in database
//        let cid1: ChannelId = .unique
//        let cid2: ChannelId = .unique
//        let query1 = ChannelListQuery(filter: .in(.cid, values: [cid1, cid2]))
//        try database.createChannelListQuery(query1)
//
//        // Create secon query in database
//        let cid3: ChannelId = .unique
//        let cid4: ChannelId = .unique
//        let query2 = ChannelListQuery(filter: .in(.cid, values: [cid3, cid4]))
//        try database.createChannelListQuery(query2)
//
//        // Trigger queries sync
//        let cids = [cid1, cid2, cid3, cid4]
//        databaseCleanupUpdater?.syncChannelListQueries(syncedChannelIDs: .init(cids))
//
//        // Assert api client is triggered for all queries
//        AssertAsync.willBeEqual(
//            Set(channelListUpdater.fetch_channelListQueries.map(\.queryHash)),
//            Set([query1, query2].map(\.queryHash))
//        )
//
//        // Simulate response for query 1
//        let query1NewCid: ChannelId = .unique
//        let query1FirstPageCIDs = [query1NewCid, cid1]
//        let query1Index = try XCTUnwrap(channelListUpdater.fetch_channelListQueries.firstIndex(of: query1))
//        channelListUpdater.fetch_completions[query1Index](.success(.mock(cids: query1FirstPageCIDs)))
//
//        // Simulate response for query 2
//        let query2NewCid: ChannelId = .unique
//        let query2FirstPageCIDs = [query2NewCid, cid3]
//        let query2Index = try XCTUnwrap(channelListUpdater.fetch_channelListQueries.firstIndex(of: query2))
//        channelListUpdater.fetch_completions[query2Index](.success(.mock(cids: query2FirstPageCIDs)))
//
//        var query1CIDs: Set<ChannelId> {
//            Set(
//                database.viewContext
//                    .channelListQuery(queryHash: query1.queryHash)!
//                    .channels
//                    .map(\.channelId)
//            )
//        }
//
//        var query2CIDs: Set<ChannelId> {
//            Set(
//                database.viewContext
//                    .channelListQuery(queryHash: query2.queryHash)!
//                    .channels
//                    .map(\.channelId)
//            )
//        }
//
//        AssertAsync {
//            Assert.willBeEqual(query1CIDs, Set(query1FirstPageCIDs))
//            Assert.willBeEqual(query2CIDs, Set(query2FirstPageCIDs))
//        }
//    }
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
            truncatedAt == nil &&
            !needsRefreshQueries
    }
}
