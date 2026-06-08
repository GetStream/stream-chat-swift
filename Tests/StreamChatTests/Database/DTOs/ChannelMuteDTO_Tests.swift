//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelMuteDTO_Tests: XCTestCase {
    var database: DatabaseContainer!

    override func setUp() {
        super.setUp()

        database = DatabaseContainer_Spy()
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        database = nil
        super.tearDown()
    }

    func test_channelMutePayload_isStoredAndLoadedFromDB() throws {
        let currentUserResponse: OwnUserResponse = .dummy(
            userId: .unique,
            role: .user
        )

        let mutePayload: ChannelMute = .dummy(
            channel: .dummy(cid: .unique),
            createdAt: .unique,
            updatedAt: .unique,
            user: currentUserResponse.asUserResponse()
        )
        mutePayload.expires = .unique
        let mutedChannel = try XCTUnwrap(mutePayload.channel)

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUserResponse)
            try session.saveChannelMute(payload: mutePayload)
        }

        let channel: ChatChannel = try XCTUnwrap(database.viewContext.channel(cid: try ChannelId(cid: mutedChannel.cid))?.asModel())
        XCTAssertEqual(channel.muteDetails?.createdAt, mutePayload.createdAt)
        XCTAssertEqual(channel.muteDetails?.updatedAt, mutePayload.updatedAt)
        XCTAssertEqual(channel.muteDetails?.expiresAt, mutePayload.expires)

        let currentUser: CurrentChatUser = try XCTUnwrap(database.viewContext.currentUser?.asModel())
        XCTAssertEqual(currentUser.mutedChannels, [channel])
    }

    func test_saveChannelMute_whenThereIsNoCurrentUser_throws() throws {
        // GIVEN
        let mute: ChannelMute = .dummy(
            channel: .dummy(cid: .unique),
            createdAt: .unique,
            updatedAt: .unique,
            user: UserResponse.dummy(userId: .unique)
        )
        mute.expires = .unique

        // WHEN
        XCTAssertThrowsError(try database.viewContext.saveChannelMute(payload: mute)) { error in
            // THEN
            XCTAssertTrue(error is ClientError.CurrentUserDoesNotExist)
        }
    }

    func test_saveChannelMute_whenMuteDoesNotExist_createsIt() throws {
        // GIVEN
        let currentUser: OwnUserResponse = .dummy(userId: .unique, role: .user)
        let channel: ChannelResponse = .dummy(cid: .unique)
        let mute: ChannelMute = .dummy(
            channel: channel,
            createdAt: .unique,
            updatedAt: .unique,
            user: currentUser.asUserResponse()
        )
        mute.expires = .unique

        var loadedMuteDTO: ChannelMuteDTO? {
            ChannelMuteDTO.load(cid: try! ChannelId(cid: channel.cid), context: database.viewContext)
        }
        XCTAssertNil(loadedMuteDTO)

        // WHEN
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            try session.saveChannelMute(payload: mute)
        }

        // THEN
        let muteDTO = try XCTUnwrap(loadedMuteDTO)
        XCTAssertEqual(muteDTO.createdAt.bridgeDate, mute.createdAt)
        XCTAssertEqual(muteDTO.updatedAt.bridgeDate, mute.updatedAt)
        XCTAssertEqual(muteDTO.expiresAt?.bridgeDate, mute.expires)
        XCTAssertEqual(muteDTO.currentUser.user.id, currentUser.id)
        XCTAssertEqual(muteDTO.channel.cid, channel.cid)
    }

    func test_saveChannelMute_whenMuteExists_updatesIt() throws {
        // GIVEN
        let currentUser: OwnUserResponse = .dummy(userId: .unique, role: .user)
        let channel: ChannelResponse = .dummy(cid: .unique)
        let initialMute: ChannelMute = .dummy(
            channel: channel,
            createdAt: .unique,
            updatedAt: .unique,
            user: currentUser.asUserResponse()
        )
        initialMute.expires = .unique

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            try session.saveChannelMute(payload: initialMute)
        }

        // WHEN
        let updatedMute: ChannelMute = .dummy(
            channel: channel,
            createdAt: .unique,
            updatedAt: .unique,
            user: currentUser.asUserResponse()
        )
        updatedMute.expires = .unique
        try database.writeSynchronously { session in
            try session.saveChannelMute(payload: updatedMute)
        }

        // THEN
        let muteDTO = try XCTUnwrap(
            ChannelMuteDTO.load(cid: try! ChannelId(cid: channel.cid), context: database.viewContext)
        )
        XCTAssertEqual(muteDTO.createdAt.bridgeDate, updatedMute.createdAt)
        XCTAssertEqual(muteDTO.updatedAt.bridgeDate, updatedMute.updatedAt)
        XCTAssertEqual(muteDTO.expiresAt?.bridgeDate, updatedMute.expires)
        XCTAssertEqual(muteDTO.currentUser.user.id, currentUser.id)
        XCTAssertEqual(muteDTO.channel.cid, channel.cid)
    }
}
