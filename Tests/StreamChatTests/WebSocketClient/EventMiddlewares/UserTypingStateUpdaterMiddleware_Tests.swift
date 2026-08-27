//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelUserTypingStateUpdaterMiddleware_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!
    var middleware: UserTypingStateUpdaterMiddleware!

    override func setUp() {
        super.setUp()

        database = DatabaseContainer_Spy()
        middleware = UserTypingStateUpdaterMiddleware()
    }

    override func tearDown() {
        database = nil
        AssertAsync.canBeReleased(&database)
        super.tearDown()
    }

    func test_middleware_forwardsNonTypingEvents() throws {
        let event = TestEvent()

        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        XCTAssertEqual(forwardedEvent as! TestEvent, event)
    }

    func test_middleware_forwardsTypingEvent_ifDatabaseWriteGeneratesError() throws {
        let cid: ChannelId = .unique
        let userId: UserId = .unique

        try database.createChannel(cid: cid)
        try database.createUser(id: userId)

        let error = TestError()
        database.write_errorResponse = error

        let event = TypingEventDTO.startTyping(cid: cid, userId: userId)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        XCTAssertEqual(forwardedEvent as! TypingEventDTO, event)
    }

    func test_middleware_handlesTypingStartedEventCorrectly() throws {
        let cid: ChannelId = .unique
        let userId: UserId = .unique

        try database.createChannel(cid: cid)
        try database.createUser(id: userId)

        var channel = try self.channel(with: cid)
        XCTAssertTrue(channel.currentlyTypingUsers.isEmpty)

        let event = TypingEventDTO.startTyping(cid: cid, userId: userId)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        channel = try self.channel(with: cid)
        XCTAssertEqual(forwardedEvent as! TypingEventDTO, event)
        XCTAssertEqual(channel.currentlyTypingUsers.first?.id, userId)
        XCTAssertEqual(channel.currentlyTypingUsers.count, 1)
    }

    func test_middleware_handlesTypingStartedEvent_withMemberInfo() throws {
        let cid: ChannelId = .unique
        let userId: UserId = .unique
        let member = MemberInfoPayload(
            channelRole: .member,
            extraData: ["is_premium": .bool(true), "nickname": .string("Marty")]
        )

        try database.createChannel(cid: cid)

        let event = TypingEventDTO.startTyping(cid: cid, userId: userId, member: member)
        _ = middleware.handle(event: event, session: database.viewContext)

        let typingUser = try XCTUnwrap(try channel(with: cid).typingUsers.first)
        XCTAssertEqual(typingUser.user.id, userId)
        XCTAssertEqual(typingUser.memberInfo?.channelRole, .member)
        XCTAssertEqual(typingUser.memberInfo?.extraData["is_premium"], .bool(true))
        XCTAssertEqual(typingUser.memberInfo?.extraData["nickname"], .string("Marty"))
    }

    func test_middleware_handlesTypingFinishedEventCorrectly() throws {
        let cid: ChannelId = .unique
        let userId: UserId = .unique

        try database.createChannel(cid: cid)
        try database.createUser(id: userId)
        try database.writeSynchronously { session in
            let channel = try XCTUnwrap(session.channel(cid: cid))
            let user = try XCTUnwrap(session.user(id: userId))
            channel.currentlyTypingUsers.insert(user)
        }

        let event = TypingEventDTO.stopTyping(cid: cid, userId: userId)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        let channel = try self.channel(with: cid)
        XCTAssertEqual(forwardedEvent as! TypingEventDTO, event)
        XCTAssertTrue(channel.currentlyTypingUsers.isEmpty)
    }

    func test_middleware_handlesCleanUpTypingEventCorrectly() throws {
        let cid: ChannelId = .unique
        let userId: UserId = .unique

        try database.createChannel(cid: cid)
        try database.createUser(id: userId)
        try database.writeSynchronously { session in
            let channel = try XCTUnwrap(session.channel(cid: cid))
            let user = try XCTUnwrap(session.user(id: userId))
            channel.currentlyTypingUsers.insert(user)
        }

        let event = CleanUpTypingEvent(cid: cid, userId: userId)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        let channel = try self.channel(with: cid)
        XCTAssertEqual(forwardedEvent as! CleanUpTypingEvent, event)
        XCTAssertTrue(channel.currentlyTypingUsers.isEmpty)
    }

    func test_middleware_clearsMemberInfoWhenTypingStops() throws {
        let cid: ChannelId = .unique
        let userId: UserId = .unique
        let member = MemberInfoPayload(extraData: ["is_premium": .bool(true)])

        try database.createChannel(cid: cid)

        _ = middleware.handle(
            event: TypingEventDTO.startTyping(cid: cid, userId: userId, member: member),
            session: database.viewContext
        )
        _ = middleware.handle(
            event: TypingEventDTO.stopTyping(cid: cid, userId: userId),
            session: database.viewContext
        )

        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))
        XCTAssertTrue(channelDTO.typingMemberInfos.isEmpty)
        XCTAssertTrue(try channel(with: cid).typingUsers.isEmpty)
    }

    func test_middleware_scopesMemberInfoToTheChannel() throws {
        let cidA: ChannelId = .unique
        let cidB: ChannelId = .unique
        let userId: UserId = .unique
        let member = MemberInfoPayload(extraData: ["is_premium": .bool(true)])

        try database.createChannel(cid: cidA)
        try database.createChannel(cid: cidB)

        _ = middleware.handle(
            event: TypingEventDTO.startTyping(cid: cidA, userId: userId, member: member),
            session: database.viewContext
        )

        XCTAssertEqual(try channel(with: cidA).typingUsers.first?.memberInfo?.extraData["is_premium"], .bool(true))
        XCTAssertTrue(try channel(with: cidB).typingUsers.isEmpty)
        XCTAssertTrue(try XCTUnwrap(database.viewContext.channel(cid: cidB)).typingMemberInfos.isEmpty)
    }

    func test_middleware_clearsMemberInfoFromPreviousChannelWhenUserMoves() throws {
        let cidA: ChannelId = .unique
        let cidB: ChannelId = .unique
        let userId: UserId = .unique
        let member = MemberInfoPayload(extraData: ["is_premium": .bool(true)])

        try database.createChannel(cid: cidA)
        try database.createChannel(cid: cidB)
        try database.createUser(id: userId)

        _ = middleware.handle(
            event: TypingEventDTO.startTyping(cid: cidA, userId: userId, member: member),
            session: database.viewContext
        )
        _ = middleware.handle(
            event: TypingEventDTO.startTyping(cid: cidB, userId: userId, member: member),
            session: database.viewContext
        )

        let channelA = try XCTUnwrap(database.viewContext.channel(cid: cidA))
        let channelB = try XCTUnwrap(database.viewContext.channel(cid: cidB))
        XCTAssertTrue(channelA.typingMemberInfos.isEmpty)
        XCTAssertEqual(channelB.typingMemberInfos.count, 1)
        XCTAssertEqual(try channel(with: cidB).typingUsers.first?.memberInfo?.extraData["is_premium"], .bool(true))
    }
}

private extension ChannelUserTypingStateUpdaterMiddleware_Tests {
    func channel(with cid: ChannelId) throws -> ChatChannel {
        try XCTUnwrap(database.viewContext.channel(cid: cid)).asModel()
    }
}
