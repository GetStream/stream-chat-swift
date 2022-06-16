//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelListSortingKey_Tests: XCTestCase {
    func test_sortDescriptor_keyPaths_areValid() throws {
        // Put all `ChannelListSortingKey`s in an array
        // We don't use `CaseIterable` since we only need this for tests
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
        
        // Iterate over keys...
        for key in sortingKeys {
            switch key {
            case .default:
                XCTAssertNotNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(
                    key.rawValue,
                    NSExpression(forKeyPath: \ChannelDTO.defaultSortingAt).keyPath
                )
            case .createdAt:
                XCTAssertNotNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(
                    key.rawValue,
                    NSExpression(forKeyPath: \ChannelDTO.createdAt).keyPath
                )
            case .updatedAt:
                XCTAssertNotNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(
                    key.rawValue,
                    NSExpression(forKeyPath: \ChannelDTO.updatedAt).keyPath
                )
            case .lastMessageAt:
                XCTAssertNotNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(
                    key.rawValue,
                    NSExpression(forKeyPath: \ChannelDTO.lastMessageAt).keyPath
                )
            case .memberCount:
                XCTAssertNotNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(
                    key.rawValue,
                    NSExpression(forKeyPath: \ChannelDTO.memberCount).keyPath
                )
            case .cid:
                XCTAssertNotNil(key.sortDescriptor(isAscending: true))
                XCTAssertEqual(
                    key.rawValue,
                    NSExpression(forKeyPath: \ChannelDTO.cid).keyPath
                )
            case .hasUnread:
                XCTAssertNil(key.sortDescriptor(isAscending: true))
            case .unreadCount:
                XCTAssertNil(key.sortDescriptor(isAscending: true))
            }
        }
    }
}
