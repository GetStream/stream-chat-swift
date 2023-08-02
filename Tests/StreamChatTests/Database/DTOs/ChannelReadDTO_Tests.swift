//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelReadDTO_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!

    override func setUp() {
        super.setUp()

        database = DatabaseContainer_Spy()
    }

    override func tearDown() {
        database = nil

        super.tearDown()
    }

    // MARK: - markChannelAsRead

    func test_markChannelAsRead_whenReadExists_isIsUpdated() throws {
        // GIVEN
        let read = ChannelReadPayload(
            user: .dummy(userId: .unique),
            lastReadAt: .init(),
            unreadMessagesCount: 10
        )

        let channel: ChannelPayload = .dummy(
            members: [.dummy(user: read.user)],
            channelReads: [read]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let newLastReadAt = read.lastReadAt.addingTimeInterval(10)
        database.viewContext.markChannelAsRead(
            cid: channel.channel.cid,
            userId: read.user.id,
            at: newLastReadAt
        )

        // THEN
        let readDTO = try XCTUnwrap(
            ChannelReadDTO.load(cid: channel.channel.cid, userId: read.user.id, context: database.viewContext)
        )
        XCTAssertNearlySameDate(readDTO.lastReadAt.bridgeDate, newLastReadAt)
        XCTAssertEqual(readDTO.unreadMessageCount, 0)
    }

    func test_markChannelAsRead_whenReadDoesNotExistButCanBeCreated_isIsCreated() throws {
        // GIVEN
        let member: MemberPayload = .dummy()
        let channel: ChannelPayload = .dummy(
            members: [member],
            channelReads: []
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let readAt = Date()
        database.viewContext.markChannelAsRead(
            cid: channel.channel.cid,
            userId: member.userId,
            at: readAt
        )

        // THEN
        let createdReadDTO = try XCTUnwrap(
            ChannelReadDTO.load(cid: channel.channel.cid, userId: member.userId, context: database.viewContext)
        )
        XCTAssertNearlySameDate(createdReadDTO.lastReadAt.bridgeDate, readAt)
        XCTAssertEqual(createdReadDTO.unreadMessageCount, 0)
    }

    func test_markChannelAsRead_whenReadDoesNotExistAndCanNotBeCreated_doesNothing() throws {
        // GIVEN
        let member: MemberPayload = .dummy()
        let channel: ChannelPayload = .dummy(
            members: [member],
            channelReads: []
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let unkownMemberId: UserId = .unique
        database.viewContext.markChannelAsRead(
            cid: channel.channel.cid,
            userId: unkownMemberId,
            at: .init()
        )

        // THEN
        let readDTO = ChannelReadDTO.load(cid: channel.channel.cid, userId: member.userId, context: database.viewContext)
        XCTAssertNil(readDTO)
    }

    func test_markChannelAsRead_whenMemberReadExists_ownMessagesFromPreviousReadAreUpdated() throws {
        // GIVEN
        let anotherUser: UserPayload = .dummy(userId: .unique)
        let anotherUserMember: MemberPayload = .dummy(user: anotherUser)
        let anotherUserMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: anotherUser.id,
            createdAt: .init()
        )
        let anotherUserRead = ChannelReadPayload(
            user: anotherUser,
            lastReadAt: anotherUserMessage.createdAt.addingTimeInterval(-1),
            unreadMessagesCount: 0
        )

        let currentUser: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        let currentUserMember: MemberPayload = .dummy(user: currentUser)
        let ownMessageReadByAnotherUser: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: currentUser.id,
            createdAt: anotherUserRead.lastReadAt.addingTimeInterval(-5)
        )
        let ownMessageUnreadByAnotherUser: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: currentUser.id,
            createdAt: anotherUserRead.lastReadAt.addingTimeInterval(5)
        )

        let channel: ChannelPayload = .dummy(
            members: [anotherUserMember, currentUserMember],
            membership: currentUserMember,
            messages: [
                ownMessageReadByAnotherUser,
                ownMessageUnreadByAnotherUser
            ],
            channelReads: [
                anotherUserRead
            ]
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            try session.saveChannel(payload: channel)
        }

        let observer = MessageListObserver(cid: channel.channel.cid, context: database.viewContext)

        // WHEN
        try database.writeSynchronously { session in
            session.markChannelAsRead(
                cid: channel.channel.cid,
                userId: anotherUser.id,
                at: ownMessageUnreadByAnotherUser.createdAt
            )
        }

        // THEN
        XCTAssertEqual(observer.updatedMessageIDs, [ownMessageUnreadByAnotherUser.id])
    }

    func test_markChannelAsRead_whenMemberReadDoesNotExist_allOwnMessagesAreUpdated() throws {
        // GIVEN
        let anotherUser: UserPayload = .dummy(userId: .unique)
        let anotherUserMember: MemberPayload = .dummy(user: anotherUser)

        let currentUser: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        let currentUserMember: MemberPayload = .dummy(user: currentUser)

        let messageFromAnotherUser: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: anotherUser.id,
            createdAt: Date().addingTimeInterval(-3)
        )
        let ownMessage1: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: currentUser.id,
            createdAt: Date().addingTimeInterval(-2)
        )
        let ownMessage2: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: currentUser.id,
            createdAt: Date().addingTimeInterval(-1)
        )

        let channel: ChannelPayload = .dummy(
            members: [anotherUserMember, currentUserMember],
            membership: currentUserMember,
            messages: [messageFromAnotherUser, ownMessage1, ownMessage2]
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            try session.saveChannel(payload: channel)
        }

        let observer = MessageListObserver(cid: channel.channel.cid, context: database.viewContext)

        // WHEN
        let anotherUserReadDate = Date()
        try database.writeSynchronously { session in
            session.markChannelAsRead(
                cid: channel.channel.cid,
                userId: anotherUser.id,
                at: anotherUserReadDate
            )
        }

        // THEN
        XCTAssertEqual(observer.updatedMessageIDs, [ownMessage1.id, ownMessage2.id])
    }

    func test_markChannelAsRead_ownRead_doesNotTriggerOwnMessagesUpdate() throws {
        // GIVEN
        let anotherUser: UserPayload = .dummy(userId: .unique)
        let anotherUserMember: MemberPayload = .dummy(user: anotherUser)

        let currentUser: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        let currentUserMember: MemberPayload = .dummy(user: currentUser)

        let messageFromAnotherUser: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: anotherUser.id,
            createdAt: Date().addingTimeInterval(-3)
        )
        let ownMessage1: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: currentUser.id,
            createdAt: Date().addingTimeInterval(-2)
        )
        let ownMessage2: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: currentUser.id,
            createdAt: Date().addingTimeInterval(-1)
        )

        let channel: ChannelPayload = .dummy(
            members: [anotherUserMember, currentUserMember],
            membership: currentUserMember,
            messages: [messageFromAnotherUser, ownMessage1, ownMessage2]
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            try session.saveChannel(payload: channel)
        }

        let observer = MessageListObserver(cid: channel.channel.cid, context: database.viewContext)

        // WHEN
        let currentUserReadDate = Date()
        try database.writeSynchronously { session in
            session.markChannelAsRead(
                cid: channel.channel.cid,
                userId: currentUser.id,
                at: currentUserReadDate
            )
        }

        // THEN
        XCTAssertTrue(observer.updatedMessageIDs.isEmpty)
    }

    // MARK: - markChannelAsUnread - partial

    func test_markChannelAsUnreadPartial_whenReadDoesNotExist() throws {
        // GIVEN
        let cid = ChannelId.unique
        let userId = UserId.unique
        let messageId = MessageId.unique

        // WHEN
        try database.writeSynchronously { session in
            session.markChannelAsUnread(for: cid, userId: userId, from: messageId, lastReadAt: nil, unreadMessagesCount: nil)
        }

        // THEN
        XCTAssertEqual(database.writeSessionCounter, 1)
        XCTAssertNil(readDTO(cid: cid, userId: userId))
    }

    func test_markChannelAsUnreadPartial_whenMessageDoesNotExist() throws {
        // GIVEN
        let cid = ChannelId.unique
        let userId = UserId.unique
        let messageId = MessageId.unique

        let member: MemberPayload = .dummy(user: .dummy(userId: userId))
        let read = ChannelReadPayload(
            user: member.user!,
            lastReadAt: .init(),
            unreadMessagesCount: 10
        )

        let channel: ChannelPayload = .dummy(
            channel: .dummy(cid: cid),
            members: [member],
            channelReads: [read]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        database.writeSessionCounter = 0

        // WHEN
        try database.writeSynchronously { session in
            session.markChannelAsUnread(for: cid, userId: userId, from: messageId, lastReadAt: nil, unreadMessagesCount: nil)
        }

        // THEN
        XCTAssertEqual(database.writeSessionCounter, 1)
        XCTAssertNotNil(readDTO(cid: cid, userId: userId))
        XCTAssertNil(database.viewContext.message(id: messageId))
    }

    func test_markChannelAsUnreadPartial_whenMessagesExist_shouldUpdateReads() throws {
        // GIVEN
        let cid = ChannelId.unique
        let userId = UserId.unique
        let messageId = MessageId.unique

        let member: MemberPayload = .dummy(user: .dummy(userId: userId))
        let read = ChannelReadPayload(
            user: member.user!,
            lastReadAt: .init(),
            unreadMessagesCount: 10
        )
        let firstMessageDate = Date()
        let messages: [MessagePayload] = [messageId, .unique, .unique].enumerated().map { index, id in
            MessagePayload.dummy(messageId: id, authorUserId: .unique, createdAt: firstMessageDate.addingTimeInterval(TimeInterval(index)))
        }

        let channel: ChannelPayload = .dummy(
            channel: .dummy(cid: cid),
            members: [member],
            messages: messages,
            channelReads: [read]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        database.writeSessionCounter = 0

        // WHEN
        try database.writeSynchronously { session in
            session.markChannelAsUnread(for: cid, userId: userId, from: messageId, lastReadAt: nil, unreadMessagesCount: nil)
        }

        // THEN
        XCTAssertEqual(database.writeSessionCounter, 1)
        let readDTO = try XCTUnwrap(readDTO(cid: cid, userId: userId))
        XCTAssertNearlySameDate(readDTO.lastReadAt.bridgeDate, firstMessageDate)
        XCTAssertEqual(readDTO.unreadMessageCount, 3)
        XCTAssertNotNil(database.viewContext.message(id: messageId))
    }

    func test_markChannelAsUnreadPartial_whenMessagesExist_lastReadAndUnreadMessagesAreSent_shouldUpdateWithArgumentValue() throws {
        // GIVEN
        let cid = ChannelId.unique
        let userId = UserId.unique
        let messageId = MessageId.unique

        let member: MemberPayload = .dummy(user: .dummy(userId: userId))
        let read = ChannelReadPayload(
            user: member.user!,
            lastReadAt: .init(),
            unreadMessagesCount: 10
        )
        let firstMessageDate = Date()
        let messages: [MessagePayload] = [messageId, .unique, .unique].enumerated().map { index, id in
            MessagePayload.dummy(messageId: id, authorUserId: .unique, createdAt: firstMessageDate.addingTimeInterval(TimeInterval(index)))
        }

        let channel: ChannelPayload = .dummy(
            channel: .dummy(cid: cid),
            members: [member],
            messages: messages,
            channelReads: [read]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        database.writeSessionCounter = 0

        let passedLastReadAt = Date().addingTimeInterval(-1000)
        let passedUnreadMessagesCount = 100

        // WHEN
        try database.writeSynchronously { session in
            session.markChannelAsUnread(for: cid, userId: userId, from: messageId, lastReadAt: passedLastReadAt, unreadMessagesCount: passedUnreadMessagesCount)
        }

        // THEN
        XCTAssertEqual(database.writeSessionCounter, 1)
        let readDTO = try XCTUnwrap(readDTO(cid: cid, userId: userId))

        // Assert pre-calculated values are overridden by argument values
        XCTAssertNotEqual(readDTO.lastReadAt.bridgeDate, firstMessageDate)
        XCTAssertNotEqual(readDTO.unreadMessageCount, 3)

        // Assert passed values take precedence
        XCTAssertNearlySameDate(readDTO.lastReadAt.bridgeDate, passedLastReadAt)
        XCTAssertEqual(readDTO.unreadMessageCount, Int32(passedUnreadMessagesCount))

        XCTAssertNotNil(database.viewContext.message(id: messageId))
    }

    // MARK: - markChannelAsUnread - whole channel

    func test_markChannelAsUnread_whenReadExists_removesIt() throws {
        // GIVEN
        let member: MemberPayload = .dummy()
        let read = ChannelReadPayload(
            user: member.user!,
            lastReadAt: .init(),
            unreadMessagesCount: 10
        )

        let channel: ChannelPayload = .dummy(
            members: [member],
            channelReads: [read]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        var readDTO: ChannelReadDTO? {
            self.readDTO(cid: channel.channel.cid, userId: read.user.id)
        }
        XCTAssertNotNil(readDTO)

        // WHEN
        try database.writeSynchronously { session in
            session.markChannelAsUnread(cid: channel.channel.cid, by: member.userId)
        }

        // THEN
        XCTAssertNil(readDTO)
    }

    private func readDTO(cid: ChannelId, userId: UserId) -> ChannelReadDTO? {
        ChannelReadDTO.load(cid: cid, userId: userId, context: database.viewContext)
    }

    // MARK: - loadOrCreateChannelRead

    func test_loadOrCreateChannelRead_channelReadExists_returnsExpectedResult() throws {
        // GIVEN
        let lastReadAt = Date.unique
        let read = ChannelReadPayload(
            user: .dummy(userId: .unique),
            lastReadAt: lastReadAt,
            unreadMessagesCount: 10
        )

        let channel: ChannelPayload = .dummy(
            members: [.dummy(user: read.user)],
            channelReads: [read]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let loadedRead = try XCTUnwrap(
            database.viewContext.loadOrCreateChannelRead(
                cid: channel.channel.cid,
                userId: read.user.id
            )
        )

        // THEN
        XCTAssertEqual(loadedRead.user.id, read.user.id)
        XCTAssertEqual(loadedRead.lastReadAt.bridgeDate, read.lastReadAt)
        XCTAssertTrue(loadedRead.unreadMessageCount == read.unreadMessagesCount)
    }

    func test_loadOrCreateChannelRead_channelReadNotExist_returnsExpectedResult() throws {
        // GIVEN
        let user = UserPayload.dummy(userId: .unique)

        let channel: ChannelPayload = .dummy(
            members: [.dummy(user: user)],
            channelReads: []
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let loadedRead = try XCTUnwrap(
            database.viewContext.loadOrCreateChannelRead(
                cid: channel.channel.cid,
                userId: user.id
            )
        )

        // THEN
        XCTAssertEqual(loadedRead.user.id, user.id)
        XCTAssertTrue(loadedRead.unreadMessageCount == 0)
    }
}

// MARK: - Helpers

private class MessageListObserver {
    let databaseObserver: ListDatabaseObserver<MessageId, MessageDTO>

    var observedChanges: [ListChange<MessageId>] = []

    var updatedMessageIDs: Set<MessageId> {
        Set(
            observedChanges.compactMap {
                guard case let .update(messageId, _) = $0 else { return nil }
                return messageId
            }
        )
    }

    init(cid: ChannelId, context: NSManagedObjectContext, pageSize: Int = .messagesPageSize) {
        databaseObserver = .init(
            context: context,
            fetchRequest: MessageDTO.messagesFetchRequest(
                for: cid,
                pageSize: pageSize,
                deletedMessagesVisibility: .alwaysVisible,
                shouldShowShadowedMessages: false
            ),
            itemCreator: { $0.id }
        )

        databaseObserver.onChange = { [weak self] in
            self?.observedChanges.append(contentsOf: $0)
        }

        try! databaseObserver.startObserving()
    }
}
