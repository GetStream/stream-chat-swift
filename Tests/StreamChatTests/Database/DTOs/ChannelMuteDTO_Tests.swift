//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
        let currentUserPayload: OwnUser = .dummy(
            userId: .unique,
            role: .user
        )

        let mutePayload = ChannelMute(
            createdAt: .unique,
            updatedAt: .unique,
            expires: .unique,
            channel: .dummy(cid: .unique),
            user: currentUserPayload.toUser
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUserPayload)
            try session.saveChannelMute(payload: mutePayload)
        }

        let channel: ChatChannel = try XCTUnwrap(database.viewContext.channel(cid: try ChannelId(cid: mutePayload.channel!.cid))?.asModel())
        XCTAssertEqual(channel.muteDetails?.createdAt, mutePayload.createdAt)
        XCTAssertEqual(channel.muteDetails?.updatedAt, mutePayload.updatedAt)
        XCTAssertEqual(channel.muteDetails?.expiresAt, mutePayload.expires)

        let currentUser: CurrentChatUser = try XCTUnwrap(database.viewContext.currentUser?.asModel())
        XCTAssertEqual(currentUser.mutedChannels, [channel])
    }

    func test_saveChannelMute_whenThereIsNoCurrentUser_throws() throws {
        // GIVEN
        let mute = ChannelMute(
            createdAt: .unique,
            updatedAt: .unique,
            expires: .unique,
            channel: .dummy(cid: .unique),
            user: .dummy(userId: .unique)
        )

        // WHEN
        XCTAssertThrowsError(try database.viewContext.saveChannelMute(payload: mute)) { error in
            // THEN
            XCTAssertTrue(error is ClientError.CurrentUserDoesNotExist)
        }
    }

    func test_saveChannelMute_whenMuteDoesNotExist_createsIt() throws {
        // GIVEN
        let currentUser: OwnUser = .dummy(userId: .unique, role: .user)
        let channel: ChannelResponse = .dummy(cid: .unique)
        let mute = ChannelMute(
            createdAt: .unique,
            updatedAt: .unique,
            expires: .unique,
            channel: channel,
            user: currentUser.toUser
        )

        var loadedMuteDTO: ChannelMuteDTO? {
            ChannelMuteDTO.load(
                cid: try! ChannelId(cid: mute.channel!.cid),
                context: database.viewContext
            )
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
        let currentUser: OwnUser = .dummy(userId: .unique, role: .user)
        let channel: ChannelResponse = .dummy(cid: .unique)
        let initialMute = ChannelMute(
            createdAt: .unique,
            updatedAt: .unique,
            expires: .unique,
            channel: channel,
            user: currentUser.toUser
        )
        
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            try session.saveChannelMute(payload: initialMute)
        }

        // WHEN
        let updatedMute = ChannelMute(
            createdAt: .unique,
            updatedAt: .unique,
            expires: .unique,
            channel: channel,
            user: currentUser.toUser
        )
        
        try database.writeSynchronously { session in
            try session.saveChannelMute(payload: updatedMute)
        }

        // THEN
        let muteDTO = try XCTUnwrap(
            ChannelMuteDTO.load(cid: try! ChannelId(cid: initialMute.channel!.cid), context: database.viewContext)
        )
        XCTAssertEqual(muteDTO.createdAt.bridgeDate, updatedMute.createdAt)
        XCTAssertEqual(muteDTO.updatedAt.bridgeDate, updatedMute.updatedAt)
        XCTAssertEqual(muteDTO.expiresAt?.bridgeDate, updatedMute.expires)
        XCTAssertEqual(muteDTO.currentUser.user.id, currentUser.id)
        XCTAssertEqual(muteDTO.channel.cid, channel.cid)
    }
}
