//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelMuteDTO_Tests: XCTestCase {
    var database: DatabaseContainer!

    override func setUp() {
        super.setUp()

        database = DatabaseContainerMock()
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&database)

        super.tearDown()
    }

    func test_channelMutePayload_isStoredAndLoadedFromDB() throws {
        let currentUserPayload: CurrentUserPayload = .dummy(
            userId: .unique,
            role: .user
        )

        let mutePayload: MutedChannelPayload = .init(
            mutedChannel: .dummy(cid: .unique),
            user: currentUserPayload,
            createdAt: .unique,
            updatedAt: .unique
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUserPayload)
            try session.saveChannelMute(payload: mutePayload)
        }

        let channel: ChatChannel = try XCTUnwrap(database.viewContext.channel(cid: mutePayload.mutedChannel.cid)?.asModel())
        XCTAssertEqual(channel.muteDetails?.createdAt, mutePayload.createdAt)
        XCTAssertEqual(channel.muteDetails?.updatedAt, mutePayload.updatedAt)

        let currentUser: CurrentChatUser = try XCTUnwrap(database.viewContext.currentUser?.asModel())
        XCTAssertEqual(currentUser.mutedChannels, [channel])
    }

    func test_loadForUser() throws {
        // Create current user payload.
        let userId: UserId = .unique

        // Create channel mutes all for current user.
        let mutePayloads: [MutedChannelPayload] = [
            .init(
                mutedChannel: .dummy(cid: .unique),
                user: dummyUser(id: userId),
                createdAt: .unique,
                updatedAt: .unique
            ),
            .init(
                mutedChannel: .dummy(cid: .unique),
                user: dummyUser(id: userId),
                createdAt: .unique,
                updatedAt: .unique
            )
        ]

        try database.writeSynchronously { session in
            // Save channel mutes to database.
            for payload in mutePayloads {
                try session.saveChannelMute(payload: payload)
            }
        }

        try database.writeSynchronously { session in
            // Load channel mutes from the database.
            let channelMutes = session.loadChannelMutes(for: userId)

            // Assert the correct # of mutes is loaded.
            XCTAssertEqual(channelMutes.count, mutePayloads.count)

            // Assert mutes match payloads.
            for mute in channelMutes {
                let payload = try XCTUnwrap(mutePayloads.first(where: { $0.mutedChannel.cid.rawValue == mute.channel.cid }))
                XCTAssertEqual(mute.user.id, payload.user.id)
                XCTAssertEqual(mute.channel.cid, payload.mutedChannel.cid.rawValue)
                XCTAssertEqual(mute.createdAt, payload.createdAt)
                XCTAssertEqual(mute.updatedAt, payload.updatedAt)
            }
        }
    }

    func test_loadForChannel() throws {
        // Create channel id.
        let cid: ChannelId = .unique

        // Create channel mutes all for the channel with `cid`.
        let mutePayloads: [MutedChannelPayload] = [
            .init(
                mutedChannel: .dummy(cid: cid),
                user: dummyUser(id: .unique),
                createdAt: .unique,
                updatedAt: .unique
            ),
            .init(
                mutedChannel: .dummy(cid: cid),
                user: dummyUser(id: .unique),
                createdAt: .unique,
                updatedAt: .unique
            )
        ]

        try database.writeSynchronously { session in
            // Save channel mutes to database.
            for payload in mutePayloads {
                try session.saveChannelMute(payload: payload)
            }
        }

        try database.writeSynchronously { session in
            // Load channel mutes from the database.
            let channelMutes = session.loadChannelMutes(for: cid)

            // Assert the correct # of mutes is loaded.
            XCTAssertEqual(channelMutes.count, mutePayloads.count)

            // Assert mutes match payloads.
            for mute in channelMutes {
                let payload = try XCTUnwrap(mutePayloads.first(where: { $0.user.id == mute.user.id }))
                XCTAssertEqual(mute.user.id, payload.user.id)
                XCTAssertEqual(mute.channel.cid, payload.mutedChannel.cid.rawValue)
                XCTAssertEqual(mute.createdAt, payload.createdAt)
                XCTAssertEqual(mute.updatedAt, payload.updatedAt)
            }
        }
    }

    func test_loadForUserAndChannel() throws {
        let payload = MutedChannelPayload(
            mutedChannel: .dummy(cid: .unique),
            user: dummyUser(id: .unique),
            createdAt: .unique,
            updatedAt: .unique
        )

        try database.writeSynchronously { session in
            // Save channel mute to database.
            try session.saveChannelMute(payload: payload)
        }

        try database.writeSynchronously { session in
            // Load channel mute from the database.
            let mute = try XCTUnwrap(
                session.loadChannelMute(
                    cid: payload.mutedChannel.cid,
                    userId: payload.user.id
                )
            )
            // Assert correct mute is loaded.
            XCTAssertEqual(mute.user.id, payload.user.id)
            XCTAssertEqual(mute.channel.cid, payload.mutedChannel.cid.rawValue)
            XCTAssertEqual(mute.createdAt, payload.createdAt)
            XCTAssertEqual(mute.updatedAt, payload.updatedAt)
        }
    }
}
