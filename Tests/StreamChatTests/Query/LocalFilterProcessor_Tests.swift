//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class LocalFilterProcessor_Tests: XCTestCase {
    private var items: [ChannelPayload]!

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    // MARK: -

    // MARK: containsMembers

    func test_filter_channelList_containMembers_singleMemberFilter_returnsExpectedChannels() throws {
        try populateItemsWithAllVariationsOfMembers()

        assertChannelFilter(
            .containMembers(userIds: ["12"]),
            expected: [
                "team:0",
                "team:1",
                "team:3",
                "team:4"
            ]
        )

        assertChannelFilter(
            .containMembers(userIds: ["13"]),
            expected: [
                "team:0",
                "team:2",
                "team:3",
                "team:5"
            ]
        )

        assertChannelFilter(
            .containMembers(userIds: ["14"]),
            expected: [
                "team:0",
                "team:1",
                "team:2",
                "team:6"
            ]
        )
    }

    func test_filter_channelList_containMembers_multipleAllMembersFilter_returnsExpectedChannels() throws {
        try populateItemsWithAllVariationsOfMembers()

        assertChannelFilter(
            .containMembers(userIds: ["12", "13"]),
            expected: [
                "team:0",
                "team:3"
            ]
        )

        assertChannelFilter(
            .containMembers(userIds: ["12", "14"]),
            expected: [
                "team:0",
                "team:1"
            ]
        )

        assertChannelFilter(
            .containMembers(userIds: ["13", "14"]),
            expected: [
                "team:0",
                "team:2"
            ]
        )

        assertChannelFilter(
            .containMembers(userIds: ["12", "13", "14"]),
            expected: [
                "team:0"
            ]
        )
    }

    // MARK: doesn't contain any of the provided members

    func test_filter_channelList_doesNotContainMembers_singleMemberFilter_returnsExpectedChannels() throws {
        try populateItemsWithAllVariationsOfMembers()

        assertChannelFilter(
            .notIn(.members, values: ["12"]),
            expected: [
                "team:2",
                "team:5",
                "team:6",
                "team:7"
            ]
        )
    }
}

extension LocalFilterProcessor_Tests {
    private func makeChannel(
        _ index: Int,
        cid: String? = nil,
        name: String? = nil,
        lastMessageAt: Date? = nil,
        team: String? = nil,
        memberIds: [String]
    ) -> ChannelPayload {
        ChannelPayload.dummy(
            channel: .dummy(
                cid: .init(type: .team, id: cid ?? "\(index)"),
                name: name ?? "Channel_\(index)",
                lastMessageAt: lastMessageAt,
                team: team
            ),
            members: memberIds.map { .dummy(user: .dummy(userId: $0)) }
        )
    }

    private func populateItems(
        with channels: [ChannelPayload]
    ) throws {
        items = channels
    }

    private func populateItemsWithAllVariationsOfMembers() throws {
        try populateItems(with: [
            makeChannel(0, memberIds: ["12", "13", "14"]),
            makeChannel(1, memberIds: ["12", "14"]),
            makeChannel(2, memberIds: ["13", "14"]),
            makeChannel(3, memberIds: ["12", "13"]),
            makeChannel(4, memberIds: ["12"]),
            makeChannel(5, memberIds: ["13"]),
            makeChannel(6, memberIds: ["14"]),
            makeChannel(7, memberIds: [])
        ])
    }

    private func assertChannelFilter(
        _ filter: @autoclosure () -> Filter<ChannelListFilterScope>,
        expected: @autoclosure () -> [UserId],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let processor = LocalFilterProcessor<ChannelListFilterScope, ChannelPayload>(filter: filter())

        let sortedReceivedIds = processor.execute(items)
            .map(\.channel.cid.rawValue)
            .sorted()
        let sortedExpectedIds = expected().sorted()

        XCTAssertEqual(sortedExpectedIds, sortedReceivedIds, file: file, line: line)
    }
}
