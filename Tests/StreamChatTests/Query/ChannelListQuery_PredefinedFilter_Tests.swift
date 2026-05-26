//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelListQuery_PredefinedFilter_Tests: XCTestCase {
    func test_predefinedFilterKeyMapping_includeEveryHardcodedChannelListFilterKey() {
        let expectedKeys: Set<String> = [
            FilterKey<ChannelListFilterScope, ChannelId>.cid.rawValue,
            FilterKey<ChannelListFilterScope, String>.id.rawValue,
            FilterKey<ChannelListFilterScope, String>.name.rawValue,
            FilterKey<ChannelListFilterScope, URL>.imageURL.rawValue,
            FilterKey<ChannelListFilterScope, ChannelType>.type.rawValue,
            FilterKey<ChannelListFilterScope, Date>.lastMessageAt.rawValue,
            FilterKey<ChannelListFilterScope, UserId>.createdBy.rawValue,
            FilterKey<ChannelListFilterScope, Date>.createdAt.rawValue,
            FilterKey<ChannelListFilterScope, Date>.updatedAt.rawValue,
            FilterKey<ChannelListFilterScope, Date>.deletedAt.rawValue,
            FilterKey<ChannelListFilterScope, Bool>.hidden.rawValue,
            FilterKey<ChannelListFilterScope, Bool>.frozen.rawValue,
            FilterKey<ChannelListFilterScope, Bool>.disabled.rawValue,
            FilterKey<ChannelListFilterScope, Bool>.blocked.rawValue,
            FilterKey<ChannelListFilterScope, Bool>.archived.rawValue,
            FilterKey<ChannelListFilterScope, Bool>.pinned.rawValue,
            FilterKey<ChannelListFilterScope, UserId>.members.rawValue,
            FilterKey<ChannelListFilterScope, Int>.memberCount.rawValue,
            FilterKey<ChannelListFilterScope, TeamId?>.team.rawValue,
            FilterKey<ChannelListFilterScope, Bool>.joined.rawValue,
            FilterKey<ChannelListFilterScope, Bool>.muted.rawValue,
            FilterKey<ChannelListFilterScope, InviteFilterValue>.invite.rawValue,
            FilterKey<ChannelListFilterScope, String>.memberName.rawValue,
            FilterKey<ChannelListFilterScope, Date>.lastUpdatedAt.rawValue,
            FilterKey<ChannelListFilterScope, String>.channelRole.rawValue,
            FilterKey<ChannelListFilterScope, String>.filterTags.rawValue,
            FilterKey<ChannelListFilterScope, Bool>.hasUnread.rawValue
        ]

        XCTAssertEqual(Set(ChannelListFilterScope.predefinedFilterKeyMapping.keys), expectedKeys)
    }

    func test_predefinedFilterSortingKeys_includeEveryHardcodedChannelListSortingKey() {
        let expectedKeys: Set<String> = [
            ChannelListSortingKey.default.remoteKey,
            ChannelListSortingKey.createdAt.remoteKey,
            ChannelListSortingKey.updatedAt.remoteKey,
            ChannelListSortingKey.lastMessageAt.remoteKey,
            ChannelListSortingKey.pinnedAt.remoteKey,
            ChannelListSortingKey.memberCount.remoteKey,
            ChannelListSortingKey.cid.remoteKey,
            ChannelListSortingKey.hasUnread.remoteKey,
            ChannelListSortingKey.unreadCount.remoteKey
        ]

        XCTAssertEqual(Set(ChannelListSortingKey.predefinedSortingKeyMapping.keys), expectedKeys)
        XCTAssertTrue(ChannelListSortingKey.predefinedSortingKeyMapping.values.allSatisfy { $0.localKey != nil })
    }

    func test_predefinedFilter_fromJSONData_implicitEqual_attachesKeyPathAndValueMapper() throws {
        let json = #"{"type":"messaging"}"#.data(using: .utf8)!

        let filter = try Filter<ChannelListFilterScope>.predefinedFilter(fromJSONData: json)

        XCTAssertEqual(filter.operator, FilterOperator.equal.rawValue)
        XCTAssertEqual(filter.key, "type")
        XCTAssertEqual(filter.value as? String, "messaging")
        XCTAssertEqual(filter.keyPathString, #keyPath(ChannelDTO.typeRawValue))
        XCTAssertNotNil(filter.valueMapper)
        XCTAssertNotNil(filter.predicate)
    }

    func test_predefinedFilter_fromJSONData_inOperator_attachesKeyPath() throws {
        let json = #"{"members":{"$in":["r2-d2"]}}"#.data(using: .utf8)!

        let filter = try Filter<ChannelListFilterScope>.predefinedFilter(fromJSONData: json)

        XCTAssertEqual(filter.operator, FilterOperator.in.rawValue)
        XCTAssertEqual(filter.key, "members")
        XCTAssertEqual(filter.value as? [String], ["r2-d2"])
        XCTAssertEqual(filter.keyPathString, #keyPath(ChannelDTO.members.user.id))
    }

    func test_predefinedFilter_fromJSONData_groupOperator_enrichesAllChildrenMixedForms() throws {
        let json = #"{"$and":[{"type":"messaging"},{"members":{"$in":["r2-d2"]}}]}"#.data(using: .utf8)!

        let filter = try Filter<ChannelListFilterScope>.predefinedFilter(fromJSONData: json)

        XCTAssertEqual(filter.operator, FilterOperator.and.rawValue)
        let children = try XCTUnwrap(filter.value as? [Filter<ChannelListFilterScope>])
        XCTAssertEqual(children.count, 2)

        let typeChild = try XCTUnwrap(children.first { $0.key == "type" })
        XCTAssertEqual(typeChild.operator, FilterOperator.equal.rawValue)
        XCTAssertEqual(typeChild.keyPathString, #keyPath(ChannelDTO.typeRawValue))

        let membersChild = try XCTUnwrap(children.first { $0.key == "members" })
        XCTAssertEqual(membersChild.operator, FilterOperator.in.rawValue)
        XCTAssertEqual(membersChild.keyPathString, #keyPath(ChannelDTO.members.user.id))
    }

    func test_predefinedFilter_fromJSONData_multiKeyObject_decodesAsImplicitAnd() throws {
        let json = #"{"members":{"$in":["r2-d2"]},"type":"messaging"}"#.data(using: .utf8)!

        let filter = try Filter<ChannelListFilterScope>.predefinedFilter(fromJSONData: json)

        XCTAssertEqual(filter.operator, FilterOperator.and.rawValue)
        let children = try XCTUnwrap(filter.value as? [Filter<ChannelListFilterScope>])
        XCTAssertEqual(children.count, 2)
        XCTAssertNotNil(children.first { $0.key == "members" })
        XCTAssertNotNil(children.first { $0.key == "type" })
    }

    func test_predefinedFilter_fromJSONData_nullValue_decodesNilTeam() throws {
        let json = #"{"team":null}"#.data(using: .utf8)!

        let filter = try Filter<ChannelListFilterScope>.predefinedFilter(fromJSONData: json)

        XCTAssertEqual(filter.operator, FilterOperator.equal.rawValue)
        XCTAssertEqual(filter.key, "team")
        XCTAssertNil(filter.value as? TeamId)
        XCTAssertEqual(filter.keyPathString, #keyPath(ChannelDTO.team))
        XCTAssertNotNil(filter.predicate)
    }

    func test_predefinedFilter_fromJSONData_unknownKey_passesThrough() throws {
        let json = #"{"made_up_field":"x"}"#.data(using: .utf8)!

        let filter = try Filter<ChannelListFilterScope>.predefinedFilter(fromJSONData: json)

        XCTAssertEqual(filter.operator, FilterOperator.equal.rawValue)
        XCTAssertEqual(filter.key, "made_up_field")
        XCTAssertEqual(filter.value as? String, "x")
        XCTAssertNil(filter.keyPathString)
    }

    func test_predefinedFilter_fromJSONData_predicateMapperKey_isPreserved() throws {
        let json = #"{"archived":true}"#.data(using: .utf8)!

        let filter = try Filter<ChannelListFilterScope>.predefinedFilter(fromJSONData: json)

        XCTAssertEqual(filter.operator, FilterOperator.equal.rawValue)
        XCTAssertEqual(filter.key, "archived")
        XCTAssertNotNil(filter.predicateMapper)

        let predicate = try XCTUnwrap(filter.predicate)
        XCTAssertTrue(
            predicate.predicateFormat.contains("archivedAt"),
            "Expected predicate to reference archivedAt; got: \(predicate.predicateFormat)"
        )
        XCTAssertTrue(
            predicate.predicateFormat.contains("!= nil"),
            "Expected archived=true to map to `archivedAt != nil`; got: \(predicate.predicateFormat)"
        )
    }

    func test_predefinedFilterSort_decodesKnownFields() throws {
        let json = #"""
        [
          {"field": "last_message_at", "direction": -1},
          {"field": "created_at", "direction": 1}
        ]
        """#.data(using: .utf8)!

        let sort = try [Sorting<ChannelListSortingKey>].predefinedFilterSort(fromJSONData: json)

        XCTAssertEqual(sort.count, 2)
        XCTAssertEqual(sort[0].key.remoteKey, ChannelListSortingKey.lastMessageAt.remoteKey)
        XCTAssertEqual(sort[0].direction, -1)
        XCTAssertEqual(sort[1].key.remoteKey, ChannelListSortingKey.createdAt.remoteKey)
        XCTAssertEqual(sort[1].direction, 1)
    }

    func test_predefinedFilterSort_dropsUnknownFields() throws {
        let json = #"""
        [
          {"field": "made_up_field", "direction": -1},
          {"field": "last_message_at", "direction": -1}
        ]
        """#.data(using: .utf8)!

        let sort = try [Sorting<ChannelListSortingKey>].predefinedFilterSort(fromJSONData: json)

        XCTAssertEqual(sort.count, 1)
        XCTAssertEqual(sort.first?.key.remoteKey, ChannelListSortingKey.lastMessageAt.remoteKey)
    }

    func test_predefinedFilterSort_handlesExtraJSONFields() throws {
        let json = #"""
        [
          {"field": "last_message_at", "direction": -1, "type": "string"}
        ]
        """#.data(using: .utf8)!

        let sort = try [Sorting<ChannelListSortingKey>].predefinedFilterSort(fromJSONData: json)

        XCTAssertEqual(sort.count, 1)
        XCTAssertEqual(sort.first?.key.remoteKey, ChannelListSortingKey.lastMessageAt.remoteKey)
        XCTAssertEqual(sort.first?.direction, -1)
    }
}
