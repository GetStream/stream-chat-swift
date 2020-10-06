//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest
import CoreData

final class ChannelMemberListQueryDTO_Tests: XCTestCase {
    var database: DatabaseContainer!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        database = try! DatabaseContainer(kind: .inMemory)
    }
    
    override func tearDown() {
        database = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func test_channelMemberListQuery_loadsCorrectQuery() throws {
        // Create the query.
        let query = ChannelMemberListQuery(cid: .unique, filter: .contains("name", String.unique))
        
        // Save the query to the database.
        try database.writeSynchronously {
            let dto = ChannelMemberListQueryDTO(context: $0 as! NSManagedObjectContext)
            dto.filterJSONData = try JSONEncoder.default.encode(query.filter)
            dto.queryHash = query.hash
        }
        
        // Load dto and assert it is correct.
        let queryDTO = try XCTUnwrap(database.viewContext.channelMemberListQuery(queryHash: query.hash))
        assert(queryDTO, match: query)
    }
    
    func test_saveQuery_savesQueryCorrectly_ifChannelExists() throws {
        // Create the query.
        let query = ChannelMemberListQuery(cid: .unique, filter: .contains("name", String.unique))
        
        // Save channel to the database.
        try database.createChannel(cid: query.cid)
        
        // Save query to the database.
        try database.createMemberListQuery(query: query)
        
        // Load dto and assert it is correct.
        let queryDTO = try XCTUnwrap(database.viewContext.channelMemberListQuery(queryHash: query.hash))
        assert(queryDTO, match: query)
    }
    
    func test_saveQuery_throwsError_ifChannelDoesNotExist() throws {
        // Create the query.
        let query = ChannelMemberListQuery(cid: .unique, filter: .contains("name", String.unique))
        
        // Try to save query to the database.
        XCTAssertThrowsError(try database.createMemberListQuery(query: query)) { error in
            // Assert `ClientError.ChannelDoesNotExist` is thrown
            XCTAssertTrue(error is ClientError.ChannelDoesNotExist)
        }
    }
    
    // MARK: - Tests

    private func assert(_ dto: ChannelMemberListQueryDTO, match query: ChannelMemberListQuery) {
        let filter = try? JSONDecoder.default.decode(Filter.self, from: dto.filterJSONData)
        XCTAssertEqual(dto.queryHash, query.hash)
        XCTAssertEqual(filter?.filterHash, query.filter.filterHash)
    }
}
