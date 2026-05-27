//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelListQueryDTO_Tests: XCTestCase {
    var database: DatabaseContainer!

    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        database = nil
        super.tearDown()
    }

    func test_saveQuery_withoutPredefinedFilter_writesFilterFromQueryAndLeavesSortNil() throws {
        let cid = ChannelId.unique
        let query = ChannelListQuery(filter: .equal(.cid, to: cid))

        try database.writeSynchronously { session in
            _ = (session as! NSManagedObjectContext).saveQuery(query: query)
        }

        try database.readSynchronously { session in
            let dto = try XCTUnwrap((session as! NSManagedObjectContext).channelListQuery(query: query))
            let savedFilter = try JSONDecoder.default.decode(Filter<ChannelListFilterScope>.self, from: dto.filterJSONData)
            XCTAssertEqual(savedFilter.filterHash, query.filter.filterHash)
            XCTAssertNil(dto.sortJSONData)
        }
    }

    func test_saveQuery_withPredefinedFilter_writesFilterAndSortFromResponse() throws {
        let query = ChannelListQuery(
            predefinedFilter: "user_per_channel_type_channels",
            filterValues: ["user_id": "r2-d2"]
        )
        let predefinedFilter = PredefinedFilterPayload(
            name: "user_per_channel_type_channels",
            filter: [
                "members": .dictionary(["$in": .array([.string("r2-d2")])]),
                "type": .string("messaging")
            ],
            sort: [
                ["direction": .number(-1), "field": .string("last_message_at"), "type": .string("string")],
                ["direction": .number(-1), "field": .string("created_at"), "type": .string("string")]
            ]
        )

        try database.writeSynchronously { session in
            _ = (session as! NSManagedObjectContext).saveQuery(query: query, predefinedFilter: predefinedFilter)
        }

        try database.readSynchronously { session in
            let dto = try XCTUnwrap((session as! NSManagedObjectContext).channelListQuery(query: query))
            let savedFilter = try JSONDecoder.default.decode([String: RawJSON].self, from: dto.filterJSONData)
            XCTAssertEqual(savedFilter, predefinedFilter.filter)

            let sortData = try XCTUnwrap(dto.sortJSONData)
            let savedSort = try JSONDecoder.default.decode([[String: RawJSON]].self, from: sortData)
            XCTAssertEqual(savedSort, predefinedFilter.sort)
        }
    }

    func test_saveQuery_withPredefinedFilter_overwritesExistingDTO() throws {
        let query = ChannelListQuery(
            predefinedFilter: "user_per_channel_type_channels",
            filterValues: ["user_id": "r2-d2"]
        )
        let first = PredefinedFilterPayload(
            name: "user_per_channel_type_channels",
            filter: ["type": .string("messaging")],
            sort: [["field": .string("last_message_at"), "direction": .number(-1)]]
        )
        let second = PredefinedFilterPayload(
            name: "user_per_channel_type_channels",
            filter: ["type": .string("livestream")],
            sort: [["field": .string("created_at"), "direction": .number(1)]]
        )

        try database.writeSynchronously { session in
            _ = (session as! NSManagedObjectContext).saveQuery(query: query, predefinedFilter: first)
        }
        try database.writeSynchronously { session in
            _ = (session as! NSManagedObjectContext).saveQuery(query: query, predefinedFilter: second)
        }

        try database.readSynchronously { session in
            let dto = try XCTUnwrap((session as! NSManagedObjectContext).channelListQuery(query: query))
            let savedFilter = try JSONDecoder.default.decode([String: RawJSON].self, from: dto.filterJSONData)
            XCTAssertEqual(savedFilter, second.filter)

            let sortData = try XCTUnwrap(dto.sortJSONData)
            let savedSort = try JSONDecoder.default.decode([[String: RawJSON]].self, from: sortData)
            XCTAssertEqual(savedSort, second.sort)
        }
    }

    func test_loadPredefinedFilter_persistedDTO_returnsQueryWithDecodedFilterAndSort() throws {
        let query = ChannelListQuery(
            predefinedFilter: "user_per_channel_type_channels",
            filterValues: ["user_id": "r2-d2"]
        )
        let payload = PredefinedFilterPayload(
            name: "user_per_channel_type_channels",
            filter: ["type": .string("messaging")],
            sort: [["field": .string("last_message_at"), "direction": .number(-1)]]
        )
        try database.writeSynchronously { session in
            _ = session.saveQuery(query: query, predefinedFilter: payload)
        }

        let updated = try XCTUnwrap(database.readAndWait { session in
            session.loadPredefinedFilter(for: query)
        })

        XCTAssertEqual(updated.filter.key, "type")
        XCTAssertEqual(updated.filter.value as? String, "messaging")
        XCTAssertEqual(updated.filter.keyPathString, #keyPath(ChannelDTO.typeRawValue))
        XCTAssertEqual(updated.sort.count, 1)
        XCTAssertEqual(updated.sort.first?.key.remoteKey, ChannelListSortingKey.lastMessageAt.remoteKey)
        XCTAssertEqual(updated.sort.first?.direction, -1)
    }

    func test_loadPredefinedFilter_noPersistedDTO_returnsNil() throws {
        let query = ChannelListQuery(predefinedFilter: "user_per_channel_type_channels")

        let updated = try database.readAndWait { session in
            session.loadPredefinedFilter(for: query)
        }

        XCTAssertNil(updated)
    }

    func test_loadPredefinedFilter_persistedDTOWithNilSort_returnsQueryWithDecodedFilterAndEmptySort() throws {
        let query = ChannelListQuery(predefinedFilter: "user_per_channel_type_channels")
        let payload = PredefinedFilterPayload(
            name: "user_per_channel_type_channels",
            filter: ["type": .string("messaging")],
            sort: []
        )
        try database.writeSynchronously { session in
            let dto = session.saveQuery(query: query, predefinedFilter: payload)
            dto.sortJSONData = nil
        }

        let updated = try XCTUnwrap(database.readAndWait { session in
            session.loadPredefinedFilter(for: query)
        })

        XCTAssertEqual(updated.filter.key, "type")
        XCTAssertEqual(updated.filter.value as? String, "messaging")
        XCTAssertTrue(updated.sort.isEmpty)
    }

    func test_loadPredefinedFilter_invalidPersistedJSON_returnsQueryUnchanged() throws {
        let query = ChannelListQuery(predefinedFilter: "user_per_channel_type_channels")
        try database.writeSynchronously { session in
            let dto = session.saveQuery(query: query, predefinedFilter: nil)
            dto.filterJSONData = Data("not-json".utf8)
            dto.sortJSONData = Data("not-json".utf8)
        }

        let updated = try XCTUnwrap(database.readAndWait { session in
            session.loadPredefinedFilter(for: query)
        })

        XCTAssertEqual(updated.filter.filterHash, query.filter.filterHash)
        XCTAssertEqual(updated.sort.map(\.description), query.sort.map(\.description))
        XCTAssertEqual(updated.predefinedFilter, query.predefinedFilter)
    }

    func test_loadPredefinedFilter_nonPredefinedQuery_returnsNil() throws {
        let query = ChannelListQuery(filter: .equal(.cid, to: .unique))

        let updated = try database.readAndWait { session in
            session.loadPredefinedFilter(for: query)
        }

        XCTAssertNil(updated)
    }
}
