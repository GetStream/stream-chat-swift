//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class MemberModelDTO_Tests: XCTestCase {
    var database: DatabaseContainer!
    
    override func setUp() {
        super.setUp()
        database = try! DatabaseContainer(kind: .inMemory)
    }
    
    func test_memberPayload_isStoredAndLoadedFromDB() throws {
        let userId = UUID().uuidString
        let channelId = ChannelId(type: .init(rawValue: "messsaging"), id: UUID().uuidString)
        
        let userPayload: UserPayload<NameAndImageExtraData> = .init(
            id: userId,
            role: .admin,
            createdAt: .init(timeIntervalSince1970: 1000),
            updatedAt: .init(timeIntervalSince1970: 2000),
            lastActiveAt: .init(timeIntervalSince1970: 3000),
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            extraData: .init(
                name: "Luke",
                imageURL: URL(
                    string: UUID()
                        .uuidString
                )
            )
        )
        
        let payload: MemberPayload<NameAndImageExtraData> = .init(
            user: userPayload,
            role: .moderator,
            createdAt: .init(timeIntervalSince1970: 4000),
            updatedAt: .init(timeIntervalSince1970: 5000)
        )
        
        // Asynchronously save the payload to the db
        database.write { session in
            try! session.saveMember(payload: payload, channelId: channelId)
        }
        
        // Load the member from the db and check it's the same member
        var loadedMember: _ChatChannelMember<NameAndImageExtraData>? {
            database.viewContext.member(userId: userId, cid: channelId)?.asModel()
        }
        
        AssertAsync {
            Assert.willBeEqual(payload.user.id, loadedMember?.id)
            Assert.willBeEqual(payload.user.isOnline, loadedMember?.isOnline)
            Assert.willBeEqual(payload.user.isBanned, loadedMember?.isBanned)
            Assert.willBeEqual(payload.user.role, loadedMember?.userRole)
            Assert.willBeEqual(payload.user.createdAt, loadedMember?.userCreatedAt)
            Assert.willBeEqual(payload.user.updatedAt, loadedMember?.userUpdatedAt)
            Assert.willBeEqual(payload.user.lastActiveAt, loadedMember?.lastActiveAt)
            Assert.willBeEqual(payload.user.extraData, loadedMember?.extraData)
            Assert.willBeEqual(payload.role, loadedMember?.memberRole)
            Assert.willBeEqual(payload.createdAt, loadedMember?.memberCreatedAt)
            Assert.willBeEqual(payload.updatedAt, loadedMember?.memberUpdatedAt)
        }
    }
    
    func test_memberPayload_withNoExtraData_isStoredAndLoadedFromDB() throws {
        let userId = UUID().uuidString
        let channelId = ChannelId(type: .init(rawValue: "messsaging"), id: UUID().uuidString)
        
        let userPayload: UserPayload<NoExtraData> = .init(
            id: userId,
            role: .admin,
            createdAt: .init(timeIntervalSince1970: 1000),
            updatedAt: .init(timeIntervalSince1970: 2000),
            lastActiveAt: .init(timeIntervalSince1970: 3000),
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            extraData: .init()
        )
        
        let payload: MemberPayload<NoExtraData> = .init(
            user: userPayload,
            role: .moderator,
            createdAt: .init(timeIntervalSince1970: 4000),
            updatedAt: .init(timeIntervalSince1970: 5000)
        )
        
        // Asynchronously save the payload to the db
        database.write { session in
            try! session.saveMember(payload: payload, channelId: channelId)
        }
        
        // Load the member from the db and check it's the same member
        var loadedMember: _ChatChannelMember<NameAndImageExtraData>? {
            database.viewContext.member(userId: userId, cid: channelId)?.asModel()
        }
        
        AssertAsync {
            Assert.willBeEqual(payload.user.id, loadedMember?.id)
            Assert.willBeEqual(payload.user.isOnline, loadedMember?.isOnline)
            Assert.willBeEqual(payload.user.isBanned, loadedMember?.isBanned)
            Assert.willBeEqual(payload.user.role, loadedMember?.userRole)
            Assert.willBeEqual(payload.user.createdAt, loadedMember?.userCreatedAt)
            Assert.willBeEqual(payload.user.updatedAt, loadedMember?.userUpdatedAt)
            Assert.willBeEqual(payload.user.lastActiveAt, loadedMember?.lastActiveAt)
            Assert.willBeEqual(payload.role, loadedMember?.memberRole)
            Assert.willBeEqual(payload.createdAt, loadedMember?.memberCreatedAt)
            Assert.willBeEqual(payload.updatedAt, loadedMember?.memberUpdatedAt)
        }
    }
    
    func test_defaultExtraDataIsUsed_whenExtraDataDecodingFails() throws {
        let userId: UserId = .unique
        let channelId: ChannelId = .unique
        
        let userPayload: UserPayload<DefaultExtraData.User> = .init(
            id: userId,
            role: .admin,
            createdAt: .unique,
            updatedAt: .unique,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            extraData: .init()
        )
        
        let payload: MemberPayload<DefaultExtraData.User> = .init(
            user: userPayload,
            role: .moderator,
            createdAt: .unique,
            updatedAt: .unique
        )
        
        try database.writeSynchronously { session in
            // Save the member
            let memberDTO = try! session.saveMember(payload: payload, channelId: channelId)
            // Make the extra data JSON invalid
            memberDTO.user.extraData = #"{"invalid": json}"# .data(using: .utf8)!
        }
        
        let loadedMember: ChatChannelMember? = database.viewContext.member(userId: userId, cid: channelId)?.asModel()
        XCTAssertEqual(loadedMember?.extraData, .defaultValue)
    }
    
    func test_saveMember_savesQuery_and_linksMember_ifQueryIsProvided() throws {
        let userId: UserId = .unique
        let cid: ChannelId = .unique

        // Create member and query.
        let member: MemberPayload<DefaultExtraData.User> = .dummy(userId: userId)
        let query = ChannelMemberListQuery<NameAndImageExtraData>(cid: cid, filter: .equal("id", to: userId))

        // Save channel, then member, and pass the query in.
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid))
            try session.saveMember(payload: member, channelId: cid, query: query)
        }
        
        // Assert query and member exists in the database and linked.
        let loadedQuery = try XCTUnwrap(database.viewContext.channelMemberListQuery(queryHash: query.queryHash))
        let loadedMember = try XCTUnwrap(database.viewContext.member(userId: userId, cid: cid))
        XCTAssertTrue(loadedQuery.members.contains(loadedMember))
    }
}
