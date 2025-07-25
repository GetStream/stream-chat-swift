//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
            .unreadCount,
            .pinnedAt
        ]

        for key in sortingKeys {
            switch key {
            case .default:
                XCTAssertNotNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(
                    key.localKey,
                    NSExpression(forKeyPath: \ChannelDTO.defaultSortingAt).keyPath
                )
                XCTAssertEqual(key.remoteKey, "last_updated")
                XCTAssertFalse(key.requiresRuntimeSorting)
            case .createdAt:
                XCTAssertNotNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(
                    key.localKey,
                    NSExpression(forKeyPath: \ChannelDTO.createdAt).keyPath
                )
                XCTAssertEqual(key.remoteKey, "created_at")
                XCTAssertFalse(key.requiresRuntimeSorting)
            case .updatedAt:
                XCTAssertNotNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(
                    key.localKey,
                    NSExpression(forKeyPath: \ChannelDTO.updatedAt).keyPath
                )
                XCTAssertEqual(key.remoteKey, "updated_at")
                XCTAssertFalse(key.requiresRuntimeSorting)
            case .lastMessageAt:
                XCTAssertNotNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(
                    key.localKey,
                    NSExpression(forKeyPath: \ChannelDTO.lastMessageAt).keyPath
                )
                XCTAssertEqual(key.remoteKey, "last_message_at")
                XCTAssertFalse(key.requiresRuntimeSorting)
            case .memberCount:
                XCTAssertNotNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(
                    key.localKey,
                    NSExpression(forKeyPath: \ChannelDTO.memberCount).keyPath
                )
                XCTAssertEqual(key.remoteKey, "member_count")
                XCTAssertFalse(key.requiresRuntimeSorting)
            case .cid:
                XCTAssertNotNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(
                    key.localKey,
                    NSExpression(forKeyPath: \ChannelDTO.cid).keyPath
                )
                XCTAssertEqual(key.remoteKey, "cid")
                XCTAssertFalse(key.requiresRuntimeSorting)
            case .hasUnread:
                XCTAssertNotNil(key.sortDescriptor(isAscending: false))
                XCTAssertEqual(key.localKey, "hasUnreadSorting")
                XCTAssertEqual(key.remoteKey, "has_unread")
                XCTAssertFalse(key.requiresRuntimeSorting)
            case .unreadCount:
                XCTAssertNotNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(key.remoteKey, "unread_count")
                XCTAssertFalse(key.requiresRuntimeSorting)
                XCTAssertEqual(
                    key.localKey,
                    NSExpression(forKeyPath: \ChannelDTO.currentUserUnreadMessagesCount).keyPath
                )
            case .pinnedAt:
                XCTAssertNotNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(key.remoteKey, "pinned_at")
                XCTAssertFalse(key.requiresRuntimeSorting)
                XCTAssertEqual(
                    key.localKey,
                    NSExpression(forKeyPath: \ChannelDTO.membership?.pinnedAt).keyPath
                )
            default:
                XCTFail()
            }
            XCTAssertEqual(jsonEncoder.encodedString(key), key.remoteKey)
        }
    }

    func test_runtimeSortingKey_keyPath_isValid() throws {
        let key = ChannelListSortingKey.custom(keyPath: \.customScore, key: "score")
        XCTAssertTrue(key.requiresRuntimeSorting)
        XCTAssertEqual(key.localKey, nil)
        XCTAssertEqual(key.remoteKey, "score")
        XCTAssertNil(key.sortDescriptor(isAscending: true))
        XCTAssertTrue(key.requiresRuntimeSorting)
        XCTAssertEqual(jsonEncoder.encodedString(key), "score")
    }

    func test_customNestedSortingKey_keyPath_isValid() throws {
        let key = ChannelListSortingKey.custom(keyPath: \.customNestedName, key: "employee.name")
        XCTAssertTrue(key.requiresRuntimeSorting)
        XCTAssertEqual(key.localKey, nil)
        XCTAssertEqual(key.remoteKey, "employee.name")
        XCTAssertNil(key.sortDescriptor(isAscending: true))
        XCTAssertTrue(key.requiresRuntimeSorting)
        XCTAssertEqual(jsonEncoder.encodedString(key), "employee.name")
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
