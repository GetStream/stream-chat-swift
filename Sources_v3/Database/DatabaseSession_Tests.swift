//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class DatabaseSession_Tests: StressTestCase {
    var database: DatabaseContainerMock!
    
    override func setUp() {
        super.setUp()
        database = try! DatabaseContainerMock(kind: .inMemory)
    }
    
    func test_eventPayloadChannelData_isSavedToDatabase() {
        // Prepare an Event payload with a channel data
        let channelId: ChannelId = .unique
        let channelPayload = dummyPayload(with: channelId)
        
        let eventPayload = EventPayload(
            eventType: .notificationAddedToChannel,
            connectionId: .unique,
            cid: channelPayload.channel.cid,
            channel: channelPayload.channel
        )
        
        // Save the event payload to DB
        database.write { session in
            try session.saveEvent(payload: eventPayload)
        }
        
        // Try to load the saved channel from DB
        var loadedChannel: _ChatChannel<DefaultExtraData>? {
            database.viewContext.channel(cid: channelId)?.asModel()
        }
        
        AssertAsync.willBeEqual(loadedChannel?.cid, channelId)
        
        // Try to load a saved channel owner from DB
        if let userId = channelPayload.channel.createdBy?.id {
            var loadedUser: _ChatUser<DefaultExtraData.User>? {
                database.viewContext.user(id: userId)?.asModel()
            }
            
            AssertAsync.willBeEqual(loadedUser?.id, userId)
        }
        
        // Try to load the saved member from DB
        if let member = channelPayload.channel.members?.first {
            var loadedMember: _ChatUser<DefaultExtraData.User>? {
                database.viewContext.member(userId: member.user.id, cid: channelId)?.asModel()
            }
            
            AssertAsync.willBeEqual(loadedMember?.id, member.user.id)
        }
    }
    
    func test_messageData_isSavedToDatabase() throws {
        // Prepare an Event payload with a message data
        let channelId: ChannelId = .unique
        let messageId: MessageId = .unique
        
        let channelPayload: ChannelDetailPayload<DefaultExtraData> = dummyPayload(with: channelId).channel
        
        let userPayload: UserPayload<NameAndImageExtraData> = .init(
            id: .unique,
            role: .admin,
            createdAt: .unique,
            updatedAt: .unique,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            extraData: .init(
                name: "Anakin",
                imageURL: URL(string: UUID().uuidString)
            )
        )
        
        let messagePayload = MessagePayload<DefaultExtraData>(
            id: messageId,
            type: .regular,
            user: userPayload,
            createdAt: .unique,
            updatedAt: .unique,
            text: "No, I am your father 🤯",
            showReplyInChannel: false,
            mentionedUsers: [],
            replyCount: 0,
            extraData: .init(),
            reactionScores: [:],
            isSilent: false
        )
        
        let eventPayload: EventPayload<DefaultExtraData> = .init(
            eventType: .messageNew,
            connectionId: .unique,
            cid: channelId,
            currentUser: nil,
            user: nil,
            createdBy: nil,
            memberContainer: nil,
            channel: channelPayload,
            message: messagePayload,
            reaction: nil,
            watcherCount: nil,
            unreadCount: nil,
            createdAt: nil,
            isChannelHistoryCleared: false,
            banReason: nil,
            banExpiredAt: nil
        )
        
        // Save the event payload to DB
        database.write { session in
            try session.saveEvent(payload: eventPayload)
        }
        
        // Try to load the saved message from DB
        var loadedMessage: _ChatMessage<DefaultExtraData>? {
            database.viewContext.message(id: messageId)?.asModel()
        }
        AssertAsync.willBeTrue(loadedMessage != nil)
        
        // Verify the channel has the message
        let loadedChannel: _ChatChannel<DefaultExtraData> = try XCTUnwrap(database.viewContext.channel(cid: channelId)?.asModel())
        let message = try XCTUnwrap(loadedMessage)
        XCTAssert(loadedChannel.latestMessages.contains(message))
    }
    
    func test_deleteMessage() throws {
        let channelId: ChannelId = .unique
        let messageId: MessageId = .unique

        // Create current user in the DB
        try database.createCurrentUser()
        
        // Create channel in the DB
        try database.createChannel(cid: channelId)
        
        // Save the message to the DB and remember the messageId
        try database.createMessage(id: messageId, cid: channelId)
        
        // Delete the message from the DB
        try database.writeSynchronously { session in
            let dto = try XCTUnwrap(session.message(id: messageId))
            session.delete(message: dto)
        }
        
        // Assert message is deleted
        XCTAssertNil(database.viewContext.message(id: messageId))
    }
    
    func test_saveEvent_unreadCountFromEventPayloadIsApplied() throws {
        let eventPayload = EventPayload<DefaultExtraData>(
            eventType: .messageNew,
            connectionId: .unique,
            cid: .unique,
            currentUser: .dummy(
                userId: .unique,
                role: .user,
                unreadCount: nil
            ),
            unreadCount: .dummy
        )
        
        try database.writeSynchronously { session in
            try session.saveEvent(payload: eventPayload)
        }
        
        // Load current user
        let currentUser = database.viewContext.currentUser()
        
        // Assert unread count is taken from event payload
        XCTAssertEqual(Int16(eventPayload.unreadCount!.messages), currentUser?.unreadMessagesCount)
        XCTAssertEqual(Int16(eventPayload.unreadCount!.channels), currentUser?.unreadChannelsCount)
    }
    
    func test_saveCurrentUserUnreadCount_failsIfThereIsNoCurrentUser() throws {
        func saveUnreadCountWithoutUser() throws {
            try database.writeSynchronously {
                try $0.saveCurrentUserUnreadCount(count: .dummy)
            }
        }
        
        XCTAssertThrowsError(try saveUnreadCountWithoutUser()) { error in
            XCTAssertTrue(error is ClientError.CurrentUserDoesNotExist)
        }
    }
    
    func test_saveEvent_resetsLastReceivedEventDate_withEventCreatedAtValue() throws {
        // Create event payload with specific `createdAt` date
        let eventPayload = EventPayload<DefaultExtraData>(
            eventType: .messageNew,
            connectionId: .unique,
            cid: .unique,
            currentUser: .dummy(
                userId: .unique,
                role: .user,
                unreadCount: nil
            ),
            unreadCount: .dummy,
            createdAt: .unique
        )
        
        // Save event to the database
        try database.writeSynchronously { session in
            try session.saveEvent(payload: eventPayload)
        }
        
        // Load current user
        let currentUser = database.viewContext.currentUser()
        
        // Assert `eventPayload.createdAt` is taked as last received event date
        XCTAssertEqual(currentUser?.lastReceivedEventDate, eventPayload.createdAt)
    }
    
    func test_saveEvent_doesntResetLastReceivedEventDate_whenEventCreatedAtValueIsNil() throws {
        // Create event payload with missing `createdAt`
        let eventPayload = EventPayload<DefaultExtraData>(
            eventType: .messageNew,
            connectionId: .unique,
            cid: .unique,
            currentUser: .dummy(
                userId: .unique,
                role: .user,
                unreadCount: nil
            ),
            unreadCount: .dummy,
            createdAt: nil
        )
        
        // Save event to the database
        try database.writeSynchronously { session in
            try session.saveEvent(payload: eventPayload)
        }
        
        // Load current user
        let currentUser = database.viewContext.currentUser()
        
        // Assert `lastReceivedEventDate` is nil
        XCTAssertNil(currentUser?.lastReceivedEventDate)
    }
}
