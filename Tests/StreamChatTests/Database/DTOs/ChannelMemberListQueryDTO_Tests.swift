//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelMemberListQueryDTO_Tests: XCTestCase {
    var database: DatabaseContainer!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        database = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func test_channelMemberListQuery_loadsCorrectQuery() throws {
        // Create the query.
        let query = ChannelMemberListQuery(cid: .unique, filter: .query(.id, text: .unique))
        
        // Save the query to the database.
        try database.writeSynchronously {
            let dto = ChannelMemberListQueryDTO(context: $0 as! NSManagedObjectContext)
            dto.filterJSONData = try JSONEncoder.default.encode(query.filter)
            dto.queryHash = query.queryHash
        }
        
        // Load dto and assert it is correct.
        let queryDTO = try XCTUnwrap(database.viewContext.channelMemberListQuery(queryHash: query.queryHash))
        assert(queryDTO, match: query)
    }
    
    func test_saveQuery_savesQueryCorrectly_ifChannelExists() throws {
        // Create the query.
        let query = ChannelMemberListQuery(cid: .unique, filter: .query(.id, text: .unique))
        
        // Save channel to the database.
        try database.createChannel(cid: query.cid)
        
        // Save query to the database.
        try database.createMemberListQuery(query: query)
        
        // Load dto and assert it is correct.
        let queryDTO = try XCTUnwrap(database.viewContext.channelMemberListQuery(queryHash: query.queryHash))
        assert(queryDTO, match: query)
    }
    
    func test_saveQuery_throwsError_ifChannelDoesNotExist() throws {
        // Create the query.
        let query = ChannelMemberListQuery(cid: .unique, filter: .query(.id, text: .unique))
        
        // Try to save query to the database.
        XCTAssertThrowsError(try database.createMemberListQuery(query: query)) { error in
            // Assert `ClientError.ChannelDoesNotExist` is thrown
            XCTAssertTrue(error is ClientError.ChannelDoesNotExist)
        }
    }
    
    // MARK: - Tests

    private func assert(_ dto: ChannelMemberListQueryDTO, match query: ChannelMemberListQuery) {
        XCTAssertEqual(dto.queryHash, query.queryHash)
        
        if let filterJSONData = dto.filterJSONData {
            let filter = try? JSONDecoder.default.decode(
                Filter<MemberListFilterScope>.self,
                from: filterJSONData
            )
            XCTAssertEqual(filter?.filterHash, query.filter?.filterHash)
        }
    }
}
