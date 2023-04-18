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

    /// This is a test that was created after receiving multiple reports of crashes with the following description:
    /// `*** Terminating app due to uncaught exception ‘NSInvalidArgumentException’, reason: ‘can’t use NULL on left hand side’`
    /// The root cause of this issue can be found on ChatChannel.create(fromDTO:), when creating a block to lazily get
    /// its unread count. To get the data, there is a predicate that looks as follows: `NSPredicate(format: "%@ IN mentionedUsers", currentUser.user)`.
    /// Whenever `currentUser.user` is invalid, this would directly crash as we cannot create a predicate with nil on the left hand side
    /// This test verifies that this code is not executed when `currentUser.user` is invalid
    func test_createFromDTO_accessingUnreadCount_doesNotCrash() {
        let databaseContainer = ChatClient.mock.databaseContainer
        let context = databaseContainer.viewContext

        // We create a ChannelDTO with just the needed info not to crash on access.
        let cid = ChannelId(type: .messaging, id: "123")
        let dto = ChannelDTO.loadOrCreate(cid: cid, context: context, cache: nil)
        dto.reads = []
        dto.config = ChannelConfigDTO(context: context)

        // We set an invalid `currentUser` to the `context` so that whenever we access `unreadCount`,
        // `currentUser.user` is invalud
        context.userInfo["io.getStream.chat.core.context.current_user_key"] = CurrentUserDTO(context: context)

        do {
            let channel = try dto.asModel()
            // We call `unreadCount` to make sure `NSPredicate(format: "%@ IN mentionedUsers", currentUser.user)`
            // is not called when `currentUser` is invalid
            XCTAssertEqual(channel.unreadCount, .noUnread)
        } catch {
            XCTFail("Error converting ChannelDTO to ChatChannel")
        }
    }
}
