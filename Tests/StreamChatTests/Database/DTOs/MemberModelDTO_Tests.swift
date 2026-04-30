//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MemberModelDTO_Tests: XCTestCase {
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

    func test_memberPayload_isStoredAndLoadedFromDB() throws {
        let userId = UUID().uuidString
        let channelId = ChannelId(type: .init(rawValue: "messsaging"), id: UUID().uuidString)

        let userPayload: UserPayload = .init(
            id: userId,
            name: .unique,
            imageURL: .unique(),
            role: .admin,
            teamsRole: ["ios": "guest"],
            createdAt: .unique,
            updatedAt: .unique,
            deactivatedAt: nil,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            teams: ["RED", "GREEN"],
            language: "pt",
            extraData: ["k": .string("v")]
        )

        let payload: MemberPayload = .init(
            user: userPayload,
            userId: userPayload.id,
            role: .moderator,
            createdAt: .unique,
            updatedAt: .unique,
            banExpiresAt: .unique,
            isBanned: true,
            isShadowBanned: true,
            notificationsMuted: true,
            extraData: ["is_premium": .bool(true)]
        )

        // Asynchronously save the payload to the db
        try database.writeSynchronously { session in
            try! session.saveMember(payload: payload, channelId: channelId)
        }

        // Load the member from the db and check it's the same member
        var loadedMember: ChatChannelMember? {
            try? database.viewContext.member(userId: userId, cid: channelId)?.asModel()
        }
        let payloadUser = try XCTUnwrap(payload.userPayload)

        AssertAsync {
            Assert.willBeEqual(payload.memberRole, loadedMember?.memberRole)
            Assert.willBeEqual(payload.createdAt, loadedMember?.memberCreatedAt)
            Assert.willBeEqual(payload.updatedAt, loadedMember?.memberUpdatedAt)
            Assert.willBeEqual(payload.isBanned, loadedMember?.isBannedFromChannel)
            Assert.willBeEqual(payload.banExpiresAt, loadedMember?.banExpiresAt)
            Assert.willBeEqual(payload.isShadowBanned, loadedMember?.isShadowBannedFromChannel)
            Assert.willBeEqual(payload.notificationsMuted, loadedMember?.notificationsMuted)

            Assert.willBeEqual(payloadUser.id, loadedMember?.id)
            Assert.willBeEqual(payloadUser.isOnline, loadedMember?.isOnline)
            Assert.willBeEqual(payloadUser.isBanned, loadedMember?.isBanned)
            Assert.willBeEqual(payloadUser.userRole, loadedMember?.userRole)
            Assert.willBeEqual(payloadUser.createdAt, loadedMember?.userCreatedAt)
            Assert.willBeEqual(payloadUser.updatedAt, loadedMember?.userUpdatedAt)
            Assert.willBeEqual(payloadUser.lastActiveAt, loadedMember?.lastActiveAt)
            Assert.willBeEqual(payloadUser.extraData, loadedMember?.extraData)
            Assert.willBeEqual(Set(payloadUser.teams), loadedMember?.teams)
            Assert.willBeEqual(payloadUser.language, loadedMember?.language?.languageCode)
            Assert.willBeEqual(true, loadedMember?.memberExtraData["is_premium"]?.boolValue)
            Assert.willBeEqual(payloadUser.teamsRolePayload, loadedMember?.teamsRole)
        }
    }

    func test_defaultExtraDataIsUsed_whenExtraDataDecodingFails() throws {
        let userId: UserId = .unique
        let channelId: ChannelId = .unique

        let userPayload: UserPayload = .init(
            id: userId,
            name: .unique,
            imageURL: .unique(),
            role: .admin,
            teamsRole: ["ios": "guest"],
            createdAt: .unique,
            updatedAt: .unique,
            deactivatedAt: nil,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            language: nil,
            extraData: .init()
        )

        let payload: MemberPayload = .init(
            user: userPayload,
            userId: userPayload.id,
            role: .moderator,
            createdAt: .unique,
            updatedAt: .unique
        )

        try database.writeSynchronously { session in
            // Save the member
            let memberDTO = try! session.saveMember(payload: payload, channelId: channelId)
            // Make the extra data JSON invalid
            memberDTO.user.extraData = #"{"invalid": json}"#.data(using: .utf8)!
        }

        let loadedMember: ChatChannelMember? = try? database.viewContext.member(userId: userId, cid: channelId)?.asModel()
        XCTAssertEqual(loadedMember?.extraData, [:])
    }

    func test_saveMember_savesQuery_and_linksMember_ifQueryIsProvided() throws {
        let userId: UserId = .unique
        let cid: ChannelId = .unique

        // Create member and query.
        let member: MemberPayload = .dummy(user: .dummy(userId: userId))
        let query = ChannelMemberListQuery(cid: cid, filter: .equal("id", to: userId))

        // Save channel, then member, and pass the query in.
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid))
            try session.saveMember(payload: member, channelId: cid, query: query, cache: nil)
        }

        // Assert query and member exists in the database and linked.
        let loadedQuery = try XCTUnwrap(database.viewContext.channelMemberListQuery(queryHash: query.queryHash))
        let loadedMember = try XCTUnwrap(database.viewContext.member(userId: userId, cid: cid))
        XCTAssertTrue(loadedQuery.members.contains(loadedMember))
    }

    func test_saveMembers_whenFirstPage_clearPreviousMembersFromQuery() throws {
        let cid: ChannelId = .unique
        let members: ChannelMemberListPayload = .init(members: [.dummy(), .dummy()])
        let query = ChannelMemberListQuery(cid: cid, filter: .equal(.isModerator, to: true))

        // Save previous members
        let previousMembers = try saveDummyMembers(toQuery: query, cid: cid)
        XCTAssertEqual(previousMembers.count, 4)

        // Save new members
        nonisolated(unsafe) var newMembers: [ChatChannelMember] = []
        try database.writeSynchronously { session in
            newMembers = try session.saveMembers(payload: members, channelId: cid, query: query)
                .map { try $0.asModel() }
        }

        // Assert the members in the DB are only the new members.
        let loadedQuery = try XCTUnwrap(database.viewContext.channelMemberListQuery(queryHash: query.queryHash))
        XCTAssertEqual(Set(loadedQuery.members.map(\.user.id)), Set(newMembers.map(\.id)))
    }

    func test_saveMembers_whenAnotherPage_doesNotClearPreviousMembersFromQuery() throws {
        let cid: ChannelId = .unique
        let members: ChannelMemberListPayload = .init(members: [.dummy(), .dummy()])
        nonisolated(unsafe) var query = ChannelMemberListQuery(cid: cid)
        query.pagination = .init(pageSize: 20, offset: 25)

        // Save previous members
        let previousMembers = try saveDummyMembers(toQuery: query, cid: cid)
        XCTAssertEqual(previousMembers.count, 4)

        // Save new members
        nonisolated(unsafe) var newMembers: [ChatChannelMember] = []
        try database.writeSynchronously { session in
            newMembers = try session.saveMembers(payload: members, channelId: cid, query: query)
                .map { try $0.asModel() }
        }

        // Assert the members in the DB contain the old and new members
        let loadedQuery = try XCTUnwrap(database.viewContext.channelMemberListQuery(queryHash: query.queryHash))
        let allMembers = previousMembers + newMembers
        XCTAssertEqual(Set(loadedQuery.members.map(\.user.id)), Set(allMembers.map(\.id)))
    }

    func test_asModel_whenModelTransformerProvided_transformsValues() throws {
        class CustomMemberTransformer: StreamModelsTransformer, @unchecked Sendable {
            var mockTransformedMember: ChatChannelMember = .mock(
                id: .unique,
                name: "transformed member"
            )

            func transform(member: ChatChannelMember) -> ChatChannelMember {
                mockTransformedMember
            }
        }

        // GIVEN
        let userId = UserId.unique
        let channelId = ChannelId(type: .messaging, id: .unique)
        let payload: MemberPayload = MemberPayload.dummy(user: UserPayload.dummy(userId: userId))

        let transformer = CustomMemberTransformer()
        var config = ChatClientConfig(apiKeyString: .unique)
        config.modelsTransformer = transformer
        database = DatabaseContainer_Spy(
            kind: .inMemory,
            chatClientConfig: config
        )
        
        try database.writeSynchronously { session in
            try session.saveMember(payload: payload, channelId: channelId)
        }
        
        // WHEN
        let member = try XCTUnwrap(database.viewContext.member(userId: userId, cid: channelId)?.asModel())
        
        // THEN
        XCTAssertEqual(member.name, "transformed member")
    }

    private func saveDummyMembers(
        _ members: [MemberPayload] = [.dummy(), .dummy(), .dummy(), .dummy()],
        toQuery query: ChannelMemberListQuery,
        cid: ChannelId
    ) throws -> [ChatChannelMember] {
        let members: ChannelMemberListPayload = .init(members: [.dummy(), .dummy(), .dummy(), .dummy()])
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid))
            session.saveMembers(payload: members, channelId: cid, query: query)
        }
        let loadedQuery = try XCTUnwrap(database.viewContext.channelMemberListQuery(queryHash: query.queryHash))
        return try loadedQuery.members.map { try $0.asModel() }
    }
}
