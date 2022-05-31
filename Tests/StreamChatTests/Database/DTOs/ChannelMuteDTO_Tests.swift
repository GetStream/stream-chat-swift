//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
    
    func test_saveChannelMute_whenThereIsNoCurrentUser_throws() throws {
        // GIVEN
        let mute: MutedChannelPayload = .init(
            mutedChannel: .dummy(cid: .unique),
            user: .dummy(userId: .unique),
            createdAt: .unique,
            updatedAt: .unique
        )
        
        // WHEN
        XCTAssertThrowsError(try database.viewContext.saveChannelMute(payload: mute)) { error in
            // THEN
            XCTAssertTrue(error is ClientError.CurrentUserDoesNotExist)
        }
    }
    
    func test_saveChannelMute_whenMuteDoesNotExist_createsIt() throws {
        // GIVEN
        let currentUser: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        let channel: ChannelDetailPayload = .dummy(cid: .unique)
        let mute: MutedChannelPayload = .init(
            mutedChannel: channel,
            user: currentUser,
            createdAt: .unique,
            updatedAt: .unique
        )
        
        var loadedMuteDTO: ChannelMuteDTO? {
            ChannelMuteDTO.load(cid: mute.mutedChannel.cid, context: database.viewContext)
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
        XCTAssertEqual(muteDTO.currentUser.user.id, currentUser.id)
        XCTAssertEqual(muteDTO.channel.cid, channel.cid.rawValue)
    }
    
    func test_saveChannelMute_whenMuteExists_updatesIt() throws {
        // GIVEN
        let currentUser: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        let channel: ChannelDetailPayload = .dummy(cid: .unique)
        let initialMute: MutedChannelPayload = .init(
            mutedChannel: channel,
            user: currentUser,
            createdAt: .unique,
            updatedAt: .unique
        )
        
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            try session.saveChannelMute(payload: initialMute)
        }
        
        // WHEN
        let updatedMute: MutedChannelPayload = .init(
            mutedChannel: channel,
            user: currentUser,
            createdAt: .unique,
            updatedAt: .unique
        )
        try database.writeSynchronously { session in
            try session.saveChannelMute(payload: updatedMute)
        }
        
        // THEN
        let muteDTO = try XCTUnwrap(
            ChannelMuteDTO.load(cid: initialMute.mutedChannel.cid, context: database.viewContext)
        )
        XCTAssertEqual(muteDTO.createdAt.bridgeDate, updatedMute.createdAt)
        XCTAssertEqual(muteDTO.updatedAt.bridgeDate, updatedMute.updatedAt)
        XCTAssertEqual(muteDTO.currentUser.user.id, currentUser.id)
        XCTAssertEqual(muteDTO.channel.cid, channel.cid.rawValue)
    }
}
