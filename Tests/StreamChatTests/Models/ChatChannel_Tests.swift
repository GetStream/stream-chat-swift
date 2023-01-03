//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChatChannel_Tests: XCTestCase {
    func test_isUnread_whenUnreadCountIsNotZero_returnsTrue() {
        let counts: [ChannelUnreadCount] = [
            .init(
                messages: 1,
                mentions: 0
            ),
            .init(
                messages: 0,
                mentions: 1
            )
        ]

        for unreadCount in counts {
            let channel: ChatChannel = .mock(
                cid: .unique,
                unreadCount: unreadCount
            )

            XCTAssertTrue(channel.isUnread)
        }
    }

    func test_isUnread_whenUnreadCountIsZero_returnsFalse() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            unreadCount: .noUnread
        )

        XCTAssertFalse(channel.isUnread)
    }

    func test_ownCapabilities() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            ownCapabilities: [.banChannelMembers, .createCall, .deleteAnyMessage],
            unreadCount: .noUnread
        )

        XCTAssertTrue(channel.ownCapabilities.contains(.banChannelMembers))
        XCTAssertTrue(channel.ownCapabilities.contains(.createCall))
        XCTAssertTrue(channel.ownCapabilities.contains(.deleteAnyMessage))
        XCTAssertFalse(channel.ownCapabilities.contains(.freezeChannel))
    }
}
