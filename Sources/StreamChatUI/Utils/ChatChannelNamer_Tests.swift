//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatChannelNamer_Tests: XCTestCase {
    var defaultMembers: [ChatChannelMember]!

    override func setUp() {
        super.setUp()
        
        defaultMembers = [
            .mock(
                id: .unique,
                name: "Darth Vader",
                imageURL: nil,
                isOnline: true
            ),
            .mock(
                id: .unique,
                name: "Darth Maul",
                imageURL: nil,
                isOnline: true
            ),
            .mock(
                id: .unique,
                name: "Kylo Ren",
                imageURL: nil,
                isOnline: true
            )
        ]
    }

    func test_defaultChannelNamer_whenChannelHasName_showsChannelName() {
        // Create channel and currentUserId
        let channel = ChatChannel.mock(
            cid: .unique,
            name: "Darth Channel",
            imageURL: TestImages.vader.url,
            lastActiveMembers: defaultMembers
        )

        let currentUserId: String = .unique
        let namer: ChatChannelNamer = DefaultChatChannelNamer()
        let nameForChannel = namer(channel, currentUserId)

        XCTAssertEqual(nameForChannel, "Darth Channel")
    }

    func test_defaultChannelNamer_directChannel_whenChannelHasNoName_andExactly2Members_showsCurrentMembers() {
        // Create channel and currentUserId

        defaultMembers = [
            .mock(
                id: .unique,
                name: "Darth Vader",
                imageURL: nil,
                isOnline: true
            ),
            .mock(
                id: .unique,
                name: "Darth Maul",
                imageURL: nil,
                isOnline: true
            )
        ]

        let channel = ChatChannel.mockDMChannel(
            name: nil,
            lastActiveMembers: defaultMembers
        )

        let currentUserId: String = .unique

        let namer: ChatChannelNamer = DefaultChatChannelNamer()
        let nameForChannel = namer(channel, currentUserId)

        XCTAssertEqual(nameForChannel, "Darth Maul and Darth Vader")
    }

    func test_defaultChannelNamer_directChannel_whenChannelHasNoName_whenChannelHasNoMembers_showsCurrentUserId() {
        // Create channel and currentUserId
        let channel = ChatChannel.mockDMChannel(
            name: nil
        )

        let currentUserId: String = .unique

        let namer: ChatChannelNamer = DefaultChatChannelNamer()
        let nameForChannel = namer(channel, currentUserId)

        XCTAssertEqual(nameForChannel, nil)
    }

    func test_defaultChannelNamer_directChannel_whenChannelHasNoName_whenChannelHasOnlyCurrentMember_showsCurrentMemberName() {
        // Create channel and currentUserId
        let currentUser: ChatChannelMember = .mock(id: .unique, name: "Luke Skywalker")

        let channel = ChatChannel.mockDMChannel(
            name: nil,
            lastActiveMembers: [currentUser]
        )

        let currentUserId: String = currentUser.id

        let namer: ChatChannelNamer = DefaultChatChannelNamer()
        let nameForChannel = namer(channel, currentUserId)

        XCTAssertEqual(nameForChannel, currentUser.name)
    }

    func test_defaultChannelNamer_directChannel_whenChannelHasNoName_andMoreThan2Members_showsMembersAndNMore() {
        // Create channel and currentUserId
        let channel = ChatChannel.mockDMChannel(
            name: nil,
            lastActiveMembers: defaultMembers
        )

        let currentUserId: String = .unique

        let namer: ChatChannelNamer = DefaultChatChannelNamer()
        let nameForChannel = namer(channel, currentUserId)

        XCTAssertEqual(nameForChannel, "Darth Maul, Darth Vader and 1 more")
    }
    
    func test_defaultChannelNamer_whenChannelHasNoName_AndNotDM_returnsNil() {
        // Create channel ID, channel and currentUserId
        let channelID: String = .unique

        let channel = ChatChannel.mock(
            cid: ChannelId(type: .gaming, id: channelID),
            name: nil
        )

        let currentUserId: String = .unique

        let namer: ChatChannelNamer = DefaultChatChannelNamer()
        let nameForChannel = namer(channel, currentUserId)

        XCTAssertEqual(nameForChannel, nil)
    }

    func test_defaultChannelNamer_withModifiedParameters_customSeparator() {
        // Create channel ID, channel and currentUserId

        let channel = ChatChannel.mockDMChannel(
            name: nil,
            lastActiveMembers: defaultMembers
        )

        let currentUserId: String = .unique

        let namer: ChatChannelNamer = DefaultChatChannelNamer(separator: " |")
        let nameForChannel = namer(channel, currentUserId)

        XCTAssertEqual(nameForChannel, "Darth Maul | Darth Vader and 1 more")
    }

    func test_defaultChannelNamer_withModifiedParameters_numberOfMaximumMembers() {
        defaultMembers = [
            .mock(
                id: .unique,
                name: "Darth Vader",
                imageURL: nil,
                isOnline: true
            ),
            .mock(
                id: .unique,
                name: "Darth Maul",
                imageURL: nil,
                isOnline: true
            ),
            .mock(
                id: .unique,
                name: "Kylo Ren",
                imageURL: nil,
                isOnline: true
            ),
            .mock(
                id: .unique,
                name: "Darth Bane",
                imageURL: nil,
                isOnline: true
            )
        ]
        // Create channel ID, channel and currentUserId
        let channel = ChatChannel.mockDMChannel(
            name: nil,
            lastActiveMembers: defaultMembers
        )

        let currentUserId: String = .unique

        let namer: ChatChannelNamer = DefaultChatChannelNamer(maxMemberNames: 4, separator: " |")
        let nameForChannel = namer(channel, currentUserId)

        XCTAssertEqual(nameForChannel, "Darth Bane | Darth Maul | Darth Vader | Kylo Ren")
    }
}
