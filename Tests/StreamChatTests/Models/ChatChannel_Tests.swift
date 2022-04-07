//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChatChannel_Tests: XCTestCase {
    func test_isUnread_whenUnreadCountIsNotZero_returnsTrue() {
        let counts: [ChannelUnreadCount] = [
            .init(
                messages: 1,
                mentioningMessages: 0,
                silentMessages: 0,
                threadReplies: 0
            ),
            .init(
                messages: 0,
                mentioningMessages: 1,
                silentMessages: 0,
                threadReplies: 0
            ),
            .init(
                messages: 0,
                mentioningMessages: 0,
                silentMessages: 1,
                threadReplies: 0
            ),
            .init(
                messages: 0,
                mentioningMessages: 0,
                silentMessages: 0,
                threadReplies: 1
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
}
