//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import XCTest

extension Array where Element == ChatChannel {
    /// Returns a dummy array of `ChatChannel`.
    static func dummy() -> [ChatChannel] {
        let channel = ChatChannel.mock(
            cid: .unique,
            name: "Channel 1",
            imageURL: XCTestCase.TestImages.yoda.url,
            lastMessageAt: .init(timeIntervalSince1970: 1_611_951_526_000)
        )
        let channelWithOnlineIndicator = ChatChannel.mockDMChannel(
            lastMessageAt: .init(timeIntervalSince1970: 1_611_951_527_000),
            lastActiveMembers: [.mock(id: .unique, name: "Darth Vader", imageURL: XCTestCase.TestImages.vader.url, isOnline: true)]
        )
        let channelWithLongTextAndUnreadCount = ChatChannel.mock(
            cid: .init(type: .messaging, id: "test_channel3"),
            name: "This is a channel with a big name. Really big.",
            imageURL: XCTestCase.TestImages.yoda.url,
            lastMessageAt: .init(timeIntervalSince1970: 1_611_951_528_000),
            unreadCount: .mock(messages: 4),
            latestMessages: [
                ChatMessage.mock(
                    id: "1", cid: .unique, text: "This is a long message. How the UI will adjust?", author: .mock(id: "Vader2")
                )
            ]
        )
        let channelWithMultipleMessages = ChatChannel.mock(
            cid: .init(type: .messaging, id: "test_channel4"),
            name: "Channel 4",
            imageURL: XCTestCase.TestImages.vader.url,
            lastMessageAt: .init(timeIntervalSince1970: 1_611_951_529_000),
            latestMessages: [
                ChatMessage.mock(id: "2", cid: .unique, text: "Hello", author: .mock(id: "Vader")),
                ChatMessage.mock(id: "1", cid: .unique, text: "Hello2", author: .mock(id: "Vader2"))
            ]
        )

        return [
            channel,
            channelWithOnlineIndicator,
            channelWithLongTextAndUnreadCount,
            channelWithMultipleMessages
        ]
    }
}
