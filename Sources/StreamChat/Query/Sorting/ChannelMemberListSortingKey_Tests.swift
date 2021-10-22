//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelMemberListSortingKey_Tests: XCTestCase {
    func test_sortDescriptor_keyPaths_areValid() throws {
        // Put all `ChannelMemberListSortingKey`s in an array
        // We don't use `CaseIterable` since we only need this for tests
        let sortingKeys: [ChannelMemberListSortingKey] = [.createdAt, .name]
        
        // Iterate over keys...
        for key in sortingKeys {
            switch key {
            case .createdAt:
                // ... and make sure all keys correspond to a valid KeyPath
                XCTAssertEqual(key.rawValue, NSExpression(forKeyPath: \MemberDTO.memberCreatedAt).keyPath)
            case .name:
                XCTAssertEqual(
                    ChannelMemberListSortingKey.name.rawValue,
                    NSExpression(forKeyPath: \MemberDTO.user.name).keyPath
                )
            }
        }
    }
}
