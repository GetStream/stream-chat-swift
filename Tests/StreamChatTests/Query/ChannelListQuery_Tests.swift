//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelListQuery_Tests: XCTestCase {
    private lazy var channelPayload: ChannelPayload! = {
        try! ChannelPayload(
            channel: .dummy(
                cid: .init(cid: "team:10"),
                name: "Channel 10",
                imageURL: .init(string: "https://getstream.io"),
                lastMessageAt: Date(timeIntervalSince1970: 10),
                createdAt: Date(timeIntervalSince1970: 5),
                deletedAt: Date(timeIntervalSince1970: 11),
                updatedAt: Date(timeIntervalSince1970: 7),
                createdBy: .dummy(userId: "100"),
                isFrozen: true,
                members: [
                    .dummy(user: .dummy(userId: "100")),
                    .dummy(user: .dummy(userId: "200"))
                ],
                team: "team1"
            ),
            watcherCount: 1,
            watchers: [
                .dummy(userId: "300")
            ],
            members: [
                .dummy(user: .dummy(userId: "100", name: "User100")),
                .dummy(user: .dummy(userId: "200", name: "User200"))
            ],
            membership: .dummy(role: .owner),
            messages: [
                .dummy(messageId: "1000", authorUserId: "100"),
                .dummy(messageId: "2000", authorUserId: "200")
            ],
            pinnedMessages: [
                .dummy(messageId: "3000", authorUserId: "200"),
                .dummy(messageId: "4000", authorUserId: "100")
            ],
            channelReads: [
                .init(user: .dummy(userId: "100"), lastReadAt: .init(timeIntervalSince1970: 0), unreadMessagesCount: 0)
            ],
            isHidden: true
        )
    }()

    override func tearDownWithError() throws {
        channelPayload = nil
        try super.tearDownWithError()
    }

    func test_channelListQuery_encodedCorrectly() throws {
        let cid = ChannelId.unique
        let filter = Filter<ChannelListFilterScope>.equal(.cid, to: cid)
        let sort = Sorting<ChannelListSortingKey>.init(key: .cid)
        let pageSize = Int.channelsPageSize
        let messagesLimit = Int.messagesPageSize
        let membersLimit = Int.channelMembersPageSize

        // Create ChannelListQuery
        var query = ChannelListQuery(
            filter: filter,
            sort: [sort],
            pageSize: pageSize,
            messagesLimit: messagesLimit,
            membersLimit: membersLimit
        )
        query.options = .watch

        let expectedData: [String: Any] = [
            "limit": pageSize,
            "message_limit": messagesLimit,
            "member_limit": membersLimit,
            "sort": [["field": "cid", "direction": -1]],
            "filter_conditions": ["cid": ["$eq": cid.rawValue]],
            "watch": true
        ]

        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)

        // Assert ChannelListQuery encoded correctly
        AssertJSONEqual(expectedJSON, encodedJSON)
    }

    // MARK: - KeyValueMapping

    func test_channelListQuery_filterKey_members_hasCorrectlyConfiguredKeyValueMapper() {
        assertArrayKeyValueMapper(
            .members,
            expected: ["100", "200"]
        )
    }

    func test_channelListQuery_filterKey_cid_hasCorrectlyConfiguredKeyValueMapper() {
        assertKeyValueMapper(
            .cid,
            expected: try! .init(cid: "team:10")
        )
    }

    func test_channelListQuery_filterKey_id_hasCorrectlyConfiguredKeyValueMapper() {
        assertKeyValueMapper(
            .id,
            expected: "team:10"
        )
    }

    func test_channelListQuery_filterKey_name_hasCorrectlyConfiguredKeyValueMapper() {
        assertKeyValueMapper(
            .name,
            expected: "Channel 10"
        )
    }

    func test_channelListQuery_filterKey_imageURL_hasCorrectlyConfiguredKeyValueMapper() {
        assertKeyValueMapper(
            .imageURL,
            expected: .init(string: "https://getstream.io")!
        )
    }

    func test_channelListQuery_filterKey_type_hasCorrectlyConfiguredKeyValueMapper() {
        assertKeyValueMapper(
            .type,
            expected: .team
        )
    }

    func test_channelListQuery_filterKey_lastMessageAt_hasCorrectlyConfiguredKeyValueMapper() {
        assertKeyValueMapper(
            .lastMessageAt,
            expected: Date(timeIntervalSince1970: 10)
        )
    }

    func test_channelListQuery_filterKey_createdBy_hasCorrectlyConfiguredKeyValueMapper() {
        assertKeyValueMapper(
            .createdBy,
            expected: "100"
        )
    }

    func test_channelListQuery_filterKey_createdAt_hasCorrectlyConfiguredKeyValueMapper() {
        assertKeyValueMapper(
            .createdAt,
            expected: Date(timeIntervalSince1970: 5)
        )
    }

    func test_channelListQuery_filterKey_updatedAt_hasCorrectlyConfiguredKeyValueMapper() {
        assertKeyValueMapper(
            .updatedAt,
            expected: Date(timeIntervalSince1970: 7)
        )
    }

    func test_channelListQuery_filterKey_deletedAt_hasCorrectlyConfiguredKeyValueMapper() {
        assertKeyValueMapper(
            .deletedAt,
            expected: Date(timeIntervalSince1970: 11)
        )
    }

    func test_channelListQuery_filterKey_hidden_hasCorrectlyConfiguredKeyValueMapper() {
        assertKeyValueMapper(
            .hidden,
            expected: true
        )
    }

    func test_channelListQuery_filterKey_frozen_hasCorrectlyConfiguredKeyValueMapper() {
        assertKeyValueMapper(
            .frozen,
            expected: true
        )
    }

    func test_channelListQuery_filterKey_memberCount_hasCorrectlyConfiguredKeyValueMapper() {
        assertKeyValueMapper(
            .memberCount,
            expected: 2
        )
    }

    func test_channelListQuery_filterKey_team_hasCorrectlyConfiguredKeyValueMapper() {
        assertKeyValueMapper(
            .team,
            expected: "team1"
        )
    }

    func test_channelListQuery_filterKey_joined_hasCorrectlyConfiguredKeyValueMapper() {
        assertKeyValueMapper(
            .joined,
            expected: true
        )
    }

    func test_channelListQuery_filterKey_memberName_hasCorrectlyConfiguredKeyValueMapper() {
        assertArrayKeyValueMapper(
            .memberName,
            expected: ["User100", "User200"]
        )
    }

    func test_channelListQuery_filterKey_lastUpdatedAt_hasCorrectlyConfiguredKeyValueMapper() {
        assertKeyValueMapper(
            .lastUpdatedAt,
            expected: Date(timeIntervalSince1970: 10)
        )
    }

    // MARK: - Private Helpers

    private func assertArrayKeyValueMapper<Value: FilterValue & Equatable>(
        _ key: FilterKey<ChannelListFilterScope, Value>,
        expected: @autoclosure () -> [Value]
    ) {
        let actual = key.keyToValueMapper?(channelPayload as Any) as? [Value]
        XCTAssertEqual(actual, expected())
    }

    private func assertKeyValueMapper<Value: FilterValue & Equatable>(
        _ key: FilterKey<ChannelListFilterScope, Value>,
        expected: @autoclosure () -> Value
    ) {
        let actual = key.keyToValueMapper?(channelPayload as Any) as? Value
        XCTAssertEqual(actual, expected())
    }
}
