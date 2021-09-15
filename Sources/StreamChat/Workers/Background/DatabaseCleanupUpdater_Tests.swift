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
    
    func test_whenSync_allLocalQueriesAreFetched() throws {
        // Create first query in database
        let cid1: ChannelId = .unique
        let query1 = ChannelListQuery(filter: .in(.cid, values: [cid1]))
        try database.createChannelListQuery(query1)

        // Create secon query in database
        let cid2: ChannelId = .unique
        let query2 = ChannelListQuery(filter: .in(.cid, values: [cid2]))
        try database.createChannelListQuery(query2)

        let testCases: [Set<ChannelId>] = [
            [],
            [cid1],
            [cid1, cid2]
        ]
        
        for syncedChannels in testCases {
            // Trigger queries sync with specific list of synced channels
            databaseCleanupUpdater?.syncChannelListQueries(syncedChannelIDs: syncedChannels) { _ in }

            // Assert all queries are fetched no matter what synced channels are
            AssertAsync.willBeEqual(
                Set(channelListUpdater.fetch_channelListQueries.map(\.queryHash)),
                Set([query1, query2].map(\.queryHash))
            )
        }
    }

//
//    func test_whenFetchSucceeds_localQueriesAreProperlyUpdated() throws {
//        // Create 1st query with 2 channels in database
//        let query1 = ChannelListQuery(filter: .exists(.cid), sort: [.init(key: .updatedAt)])
//        let query1LocalCid1: ChannelId = .unique
//        let query1LocalCid2: ChannelId = .unique
//        try database.writeSynchronously { session in
//            for cid in [query1LocalCid1, query1LocalCid2] {
//                try session.saveChannel(payload: .dummy(cid: cid), query: query1)
//            }
//        }
//
//        // Create 2nd query with 2 channels in database
//        let query2 = ChannelListQuery(filter: .exists(.cid), sort: [.init(key: .lastMessageAt)])
//        let query2LocalCid1: ChannelId = .unique
//        let query2LocalCid2: ChannelId = .unique
//        try database.writeSynchronously { session in
//            for cid in [query2LocalCid1, query2LocalCid2] {
//                try session.saveChannel(payload: .dummy(cid: cid), query: query2)
//            }
//        }
//
//        // Trigger queries sync
//        let cids = [query1LocalCid1, query1LocalCid2, query2LocalCid1, query2LocalCid2]
//        databaseCleanupUpdater?.syncChannelListQueries(syncedChannelIDs: .init(cids)) { _ in }
//
//        // Wait both queries to be fetched
//        AssertAsync.willBeEqual(channelListUpdater.fetch_channelListQueries.count, 2)
//
//        // Simulate response for query 1
//        let query1NewCid: ChannelId = .unique
//        let query1FirstPageCIDs = [query1LocalCid1, query1NewCid]
//        let query1Index = try XCTUnwrap(channelListUpdater.fetch_channelListQueries.firstIndex(of: query1))
//        channelListUpdater.fetch_completions[query1Index](.success(
//            .init(channels: query1FirstPageCIDs.map { cid in
//                .init(
//                    channel: .dummy(cid: cid),
//                    watcherCount: 0,
//                    watchers: [],
//                    members: [],
//                    membership: nil,
//                    messages: [],
//                    pinnedMessages: [],
//                    channelReads: []
//                )
//            })
//        ))
//
//        // Simulate response for query 2
//        let query2NewCid: ChannelId = .unique
//        let query2FirstPageCIDs = [query2NewCid, query2LocalCid1]
//        let query2Index = try XCTUnwrap(channelListUpdater.fetch_channelListQueries.firstIndex(of: query2))
//        channelListUpdater.fetch_completions[query2Index](.success(
//            .init(channels: query2FirstPageCIDs.map { cid in
//                .init(
//                    channel: .dummy(cid: cid),
//                    watcherCount: 0,
//                    watchers: [],
//                    members: [],
//                    membership: nil,
//                    messages: [],
//                    pinnedMessages: [],
//                    channelReads: []
//                )
//            })
//        ))
//
//        var query1CIDs: Set<ChannelId> {
//            Set(
//                database.viewContext
//                    .channelListQuery(queryHash: query1.queryHash)!
//                    .channels
//                    .map { try! ChannelId(cid: $0.cid) }
//            )
//        }
//
//        var query2CIDs: Set<ChannelId> {
//            Set(
//                database.viewContext
//                    .channelListQuery(queryHash: query2.queryHash)!
//                    .channels
//                    .map { try! ChannelId(cid: $0.cid) }
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
