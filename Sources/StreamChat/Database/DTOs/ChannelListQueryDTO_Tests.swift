//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelListQueryDTO_Tests: XCTestCase {
    var database: DatabaseContainer!

    override func setUp() {
        super.setUp()
        
        database = DatabaseContainerMock()
    }

    func test_saveQuery_createsCorrectQueryInDatabase() throws {
        // Save query to database
        let query = ChannelListQuery(
            filter: .and([.exists(.cid), .in(.cid, values: [.unique, .unique])]),
            sort: [
                .init(key: .updatedAt),
                .init(key: .memberCount, isAscending: true)
            ]
        )
        try database.writeSynchronously { session in
            _ = session.saveQuery(query: query)
        }
        
        // Load all queries
        let allQueriesRequest = NSFetchRequest<ChannelListQueryDTO>(entityName: ChannelListQueryDTO.entityName)
        let allQueries = try database.viewContext.fetch(allQueriesRequest)
        
        // Assert a single query is exists in database
        XCTAssertEqual(allQueries.count, 1)
        
        try assert(queryDTO: allQueries[0], matches: query)
    }
    
    func test_channelListQuery_loadsCorrectQuery() throws {
        // Save query to database
        let query = ChannelListQuery(
            filter: .and([.exists(.cid), .in(.cid, values: [.unique, .unique])]),
            sort: [
                .init(key: .updatedAt),
                .init(key: .memberCount, isAscending: true)
            ]
        )
        try database.createChannelListQuery(query)
        
        // Load query from database
        let queryDTO = try XCTUnwrap(database.viewContext.channelListQuery(queryHash: query.queryHash))
        
        // Assert database query has correct fields
        try assert(queryDTO: queryDTO, matches: query)
    }
    
    func test_loadAllQueries_returnsAllLocallyExistedQueries() throws {
        // Save 2 queries to database
        let query1 = ChannelListQuery(
            filter: .and([.exists(.cid), .in(.cid, values: [.unique, .unique])]),
            sort: [
                .init(key: .updatedAt),
                .init(key: .memberCount, isAscending: true)
            ]
        )
        let query2 = ChannelListQuery(
            filter: .exists(.cid)
        )
        try database.createChannelListQuery(query1)
        try database.createChannelListQuery(query2)
        
        // Load all queries
        let queryDTOs = database.viewContext.loadChannelListQueries()
        
        // Assert correct queries are loaded
        XCTAssertEqual(queryDTOs.count, 2)
        let query1DTO = try XCTUnwrap(queryDTOs.first(where: { $0.queryHash == query1.queryHash }))
        let query2DTO = try XCTUnwrap(queryDTOs.first(where: { $0.queryHash == query2.queryHash }))
        try assert(queryDTO: query1DTO, matches: query1)
        try assert(queryDTO: query2DTO, matches: query2)
    }
    
    func test_asModel_returnsModelWithCorrectHashAndEncoding() throws {
        // Save query to database
        let query = ChannelListQuery(
            filter: .and([.exists(.cid), .in(.cid, values: [.unique, .unique])]),
            sort: [
                .init(key: .memberCount, isAscending: true),
                .init(key: .lastMessageAt, isAscending: false)
            ]
        )
        try database.createChannelListQuery(query)
        
        // Load a query from database and parse a model
        let request = NSFetchRequest<ChannelListQueryDTO>(entityName: ChannelListQueryDTO.entityName)
        request.predicate = NSPredicate(format: "queryHash == %@", query.queryHash)
        let queryDTO = try XCTUnwrap(try database.viewContext.fetch(request).first)
        let queryModel = try XCTUnwrap(queryDTO.asModel())
        
        // Assert hash matches
        XCTAssertEqual(queryModel.queryHash, query.queryHash)
        // Assert query encoding matches
        XCTAssertEqual(
            try JSONEncoder.default.encode(queryModel),
            try JSONEncoder.default.encode(query)
        )
    }
    
    private func assert(queryDTO: ChannelListQueryDTO, matches query: ChannelListQuery) throws {
        XCTAssertEqual(queryDTO.queryHash, query.queryHash)
        XCTAssertEqual(queryDTO.filterJSONData, try JSONEncoder.default.encode(query.filter))
        XCTAssertEqual(queryDTO.sortingJSONData, try JSONEncoder.default.encode(query.sort))
    }
}
