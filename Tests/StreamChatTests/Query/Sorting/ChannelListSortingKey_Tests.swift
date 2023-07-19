//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelListSortingKey_Tests: XCTestCase {
    private let jsonEncoder = JSONEncoder()

    func test_defaultSortingKeys_keyPaths_areValid() throws {
        let sortingKeys: [ChannelListSortingKey] = [
            .default,
            .createdAt,
            .updatedAt,
            .lastMessageAt,
            .memberCount,
            .cid,
            .hasUnread,
            .unreadCount
        ]

        for key in sortingKeys {
            switch key {
            case .default:
                XCTAssertNotNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(
                    key.localKey,
                    NSExpression(forKeyPath: \ChannelDTO.defaultSortingAt).keyPath
                )
                XCTAssertEqual(key.remoteKey, "updated_at")
                XCTAssertTrue(key.canUseAsDBSortDescriptor)
            case .createdAt:
                XCTAssertNotNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(
                    key.localKey,
                    NSExpression(forKeyPath: \ChannelDTO.createdAt).keyPath
                )
                XCTAssertEqual(key.remoteKey, "created_at")
                XCTAssertTrue(key.canUseAsDBSortDescriptor)
            case .updatedAt:
                XCTAssertNotNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(
                    key.localKey,
                    NSExpression(forKeyPath: \ChannelDTO.updatedAt).keyPath
                )
                XCTAssertEqual(key.remoteKey, "updated_at")
                XCTAssertTrue(key.canUseAsDBSortDescriptor)
            case .lastMessageAt:
                XCTAssertNotNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(
                    key.localKey,
                    NSExpression(forKeyPath: \ChannelDTO.lastMessageAt).keyPath
                )
                XCTAssertEqual(key.remoteKey, "last_message_at")
                XCTAssertTrue(key.canUseAsDBSortDescriptor)
            case .memberCount:
                XCTAssertNotNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(
                    key.localKey,
                    NSExpression(forKeyPath: \ChannelDTO.memberCount).keyPath
                )
                XCTAssertEqual(key.remoteKey, "member_count")
                XCTAssertTrue(key.canUseAsDBSortDescriptor)
            case .cid:
                XCTAssertNotNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(
                    key.localKey,
                    NSExpression(forKeyPath: \ChannelDTO.cid).keyPath
                )
                XCTAssertEqual(key.remoteKey, "cid")
                XCTAssertTrue(key.canUseAsDBSortDescriptor)
            case .hasUnread:
                XCTAssertNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(key.remoteKey, "has_unread")
                XCTAssertFalse(key.canUseAsDBSortDescriptor)
            case .unreadCount:
                XCTAssertNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(key.remoteKey, "unread_count")
                XCTAssertFalse(key.canUseAsDBSortDescriptor)
            default:
                XCTFail()
            }
            XCTAssertFalse(key.isCustom)
            XCTAssertEqual(jsonEncoder.encodedString(key), key.remoteKey)
        }
    }

    func test_customSortingKey_keyPath_isValid() throws {
        let key = ChannelListSortingKey.custom(keyPath: \.customScore, key: "score")
        XCTAssertTrue(key.isCustom)
        XCTAssertEqual(key.localKey, "customScore")
        XCTAssertEqual(key.remoteKey, "score")
        XCTAssertNil(key.sortDescriptor(isAscending: true))
        XCTAssertFalse(key.canUseAsDBSortDescriptor)
        XCTAssertEqual(jsonEncoder.encodedString(key), "score")
    }

    func test_customNestedSortingKey_keyPath_isValid() throws {
        let key = ChannelListSortingKey.custom(keyPath: \.customNestedName, key: "employee.name")
        XCTAssertTrue(key.isCustom)
        XCTAssertEqual(key.localKey, "customNestedName")
        XCTAssertEqual(key.remoteKey, "employee.name")
        XCTAssertNil(key.sortDescriptor(isAscending: true))
        XCTAssertFalse(key.canUseAsDBSortDescriptor)
        XCTAssertEqual(jsonEncoder.encodedString(key), "employee.name")
    }

    func test_sortingKeyArray_customSorting_returnsEmptyIfNoCustomKey() {
        let sorting = [
            Sorting(key: ChannelListSortingKey.updatedAt),
            Sorting(key: ChannelListSortingKey.memberCount)
        ]

        XCTAssertTrue(sorting.customSorting.isEmpty)
    }

    func test_sortingKeyArray_customSorting_returnsArrayIfCustomKey() {
        let sorting = [
            Sorting(key: ChannelListSortingKey.updatedAt),
            Sorting(key: ChannelListSortingKey.memberCount),
            Sorting(key: ChannelListSortingKey.custom(keyPath: \.customScore, key: "score"))
        ]

        XCTAssertEqual(sorting.customSorting.count, 3)
        XCTAssertTrue(sorting.customSorting.contains(where: { $0.keyPath == \ChatChannel.updatedAt }))
        XCTAssertTrue(sorting.customSorting.contains(where: { $0.keyPath == \ChatChannel.memberCount }))
        XCTAssertTrue(sorting.customSorting.contains(where: { $0.keyPath == \ChatChannel.customScore }))
    }
}

private extension ChatChannel {
    var customScore: Double {
        extraData["score"]?.numberValue ?? 0
    }

    var customNestedName: String {
        extraData["employee"]?["name"]?.stringValue ?? ""
    }
}
