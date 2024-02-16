//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class DatabaseSession_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!

    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        database = nil
        super.tearDown()
    }

    func test_eventPayloadChannelData_isSavedToDatabase() throws {
        // Prepare an Event payload with a channel data
        let channelId: ChannelId = .unique
        let channelPayload = dummyPayload(with: channelId)

        let event = NotificationAddedToChannelEvent(
            channelId: channelId.id,
            channelType: channelId.type.rawValue,
            cid: channelId.rawValue,
            createdAt: .unique,
            type: EventType.notificationAddedToChannel.rawValue,
            channel: channelPayload.channel
        )

        // Save the event payload to DB
        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        // Try to load the saved channel from DB
        var loadedChannel: ChatChannel? {
            try? database.viewContext.channel(cid: channelId)?.asModel()
        }

        AssertAsync.willBeEqual(loadedChannel?.cid, channelId)

        // Try to load a saved channel owner from DB
        if let userId = channelPayload.channel?.createdBy?.id {
            var loadedUser: ChatUser? {
                try? database.viewContext.user(id: userId)?.asModel()
            }

            AssertAsync.willBeEqual(loadedUser?.id, userId)
        }

        // Try to load the saved member from DB
        if let member = channelPayload.channel?.members?.first {
            var loadedMember: ChatUser? {
                try? database.viewContext.member(
                    userId: member?.userId ?? .unique,
                    cid: channelId
                )?.asModel()
            }

            AssertAsync.willBeEqual(loadedMember?.id, member?.userId)
        }
    }

    func test_messageData_isSavedToDatabase() throws {
        // Prepare an Event payload with a message data
        let channelId: ChannelId = .unique
        let messageId: MessageId = .unique

        let channelPayload = dummyPayload(with: channelId).channel

        let userPayload = UserObject(id: .unique, role: UserRole.admin.rawValue)

        let messagePayload = Message.dummy(
            type: .init(rawValue: "regular"),
            messageId: messageId,
            authorUserId: userPayload.id,
            text: "Some text",
            createdAt: channelPayload?.createdAt.addingTimeInterval(300),
            updatedAt: .unique
        )
        
        let event = MessageNewEvent(
            channelId: channelId.id,
            channelType: channelId.type.rawValue,
            cid: channelId.rawValue,
            createdAt: .unique,
            type: EventType.messageNew.rawValue,
            watcherCount: 0,
            message: messagePayload,
            user: userPayload
        )

        // Save the event payload to DB
        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        // Try to load the saved message from DB
        var loadedMessage: ChatMessage? {
            try? database.viewContext.message(id: messageId)?.asModel()
        }
        AssertAsync.willBeTrue(loadedMessage != nil)

        // Verify the channel has the message
        let loadedChannel: ChatChannel = try XCTUnwrap(database.viewContext.channel(cid: channelId)?.asModel())
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

    func test_pinMessage() throws {
        let channelId: ChannelId = .unique
        let messageId: MessageId = .unique

        // Create current user in the DB
        try database.createCurrentUser()

        // Create channel in the DB
        try database.createChannel(cid: channelId)

        // Save the message to the DB and remember the messageId
        try database.createMessage(id: messageId, cid: channelId)

        // Pin message
        let expireDate = Date.unique
        try database.writeSynchronously { session in
            let dto = try XCTUnwrap(session.message(id: messageId))
            try session.pin(message: dto, pinning: .expirationDate(expireDate))
        }

        let message = database.viewContext.message(id: messageId)
        XCTAssertNotNil(message)
        XCTAssertNotNil(message?.pinnedAt)
        XCTAssertNotNil(message?.pinnedBy)
        XCTAssertEqual(message?.pinned, true)
        XCTAssertEqual(message?.pinExpires?.bridgeDate, expireDate)
    }

    func test_pinMessage_whenNoCurrentUser_throwsError() throws {
        let channelId: ChannelId = .unique
        let messageId: MessageId = .unique

        // Create channel in the DB
        try database.createChannel(cid: channelId)

        // Save the message to the DB and remember the messageId
        try database.createMessage(id: messageId, cid: channelId)

        XCTAssertThrowsError(
            // Pin message
            try database.writeSynchronously { session in
                let dto = try XCTUnwrap(session.message(id: messageId))
                try session.pin(message: dto, pinning: MessagePinning(expirationDate: .unique))
            }
        ) { error in
            XCTAssertTrue(error is ClientError.CurrentUserDoesNotExist)
        }
    }

    func test_unpinMessage() throws {
        let channelId: ChannelId = .unique
        let messageId: MessageId = .unique

        // Create current user in the DB
        try database.createCurrentUser()

        // Create channel in the DB
        try database.createChannel(cid: channelId)

        // Save the message to the DB and remember the messageId
        try database.createMessage(id: messageId, cid: channelId)

        // Unpin message
        try database.writeSynchronously { session in
            let dto = try XCTUnwrap(session.message(id: messageId))
            try session.pin(message: dto, pinning: .expirationTime(300))
            session.unpin(message: dto)
        }

        let message = database.viewContext.message(id: messageId)
        XCTAssertNotNil(message)
        XCTAssertNil(message?.pinnedAt)
        XCTAssertNil(message?.pinnedBy)
        XCTAssertNil(message?.pinExpires)
        XCTAssertEqual(message?.pinned, false)
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

    func test_saveEvent_doesntResetLastReceivedEventDate_whenEventCreatedAtValueIsNil() throws {
        let channelId: ChannelId = .unique
        let messageId: MessageId = .unique

        let channelPayload = dummyPayload(with: channelId).channel

        let userPayload = UserObject(id: .unique, role: UserRole.admin.rawValue)

        let messagePayload = Message.dummy(
            type: .init(rawValue: "regular"),
            messageId: messageId,
            authorUserId: userPayload.id,
            text: "Some text",
            createdAt: channelPayload?.createdAt.addingTimeInterval(300),
            updatedAt: .unique
        )
        
        let event = MessageNewEvent(
            channelId: channelId.id,
            channelType: channelId.type.rawValue,
            cid: channelId.rawValue,
            createdAt: .unique,
            type: EventType.messageNew.rawValue,
            watcherCount: 0,
            message: messagePayload,
            user: userPayload
        )

        // Save the event payload to DB
        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }
        
        // Load current user
        let currentUser = database.viewContext.currentUser

        // Assert `lastReceivedEventDate` is nil
        XCTAssertNil(currentUser?.lastSynchedEventDate)
    }

    func test_saveEvent_whenMessageUpdated_shouldUpdateMessagesQuotingTheUpdatedMessage() throws {
        let userId: UserId = .unique
        let channelId: ChannelId = .unique
        let messageId: MessageId = .unique
        let quotingMessageId: MessageId = .unique

        // Create current user in the DB
        try database.createCurrentUser(id: userId)

        // Create channel in the DB
        try database.createChannel(cid: channelId)

        // Save the message to the DB
        try database.createMessage(id: messageId, authorId: userId, cid: channelId)

        // Save the message that is quoting the other message
        try database.createMessage(id: quotingMessageId, authorId: userId, cid: channelId, quotedMessageId: messageId)

        let event = MessageUpdatedEvent(
            channelId: channelId.id,
            channelType: channelId.type.rawValue,
            cid: channelId.rawValue,
            createdAt: .unique,
            type: EventType.messageUpdated.rawValue,
            message: .dummy(messageId: messageId, authorUserId: userId),
            user: .dummy(userId: userId)
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        let message = try XCTUnwrap(database.viewContext.message(id: messageId))
        let quotingMessage = try XCTUnwrap(database.viewContext.message(id: quotingMessageId))

        // We set the same updateAt to to both messages, to trigger a DB update
        XCTAssertEqual(message.updatedAt, quotingMessage.updatedAt)
    }

    func test_saveEvent_whenMessageDelete_whenHardDeleted_shouldHardDeleteMessageFromDatabase() throws {
        let userId: UserId = .unique
        let channelId: ChannelId = .unique
        let messageId: MessageId = .unique

        // Create current user in the DB
        try database.createCurrentUser(id: userId)

        // Create channel in the DB
        try database.createChannel(cid: channelId)

        // Save the message to the DB
        try database.createMessage(id: messageId, authorId: userId, cid: channelId)
        
        let event = MessageDeletedEvent(
            channelId: channelId.id,
            channelType: channelId.type.rawValue,
            cid: channelId.rawValue,
            createdAt: .unique,
            hardDelete: true,
            type: EventType.messageDeleted.rawValue,
            message: .dummy(messageId: messageId, authorUserId: userId),
            user: .dummy(userId: userId)
        )

        let messageBeforeEvent = database.viewContext.message(id: messageId)

        XCTAssertNotNil(messageBeforeEvent)

        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        let messageAfterEvent = database.viewContext.message(id: messageId)

        // XCTAssertNil(messageAfterEvent) This should be uncommented out after: https://stream-io.atlassian.net/browse/CIS-1963
        XCTAssertTrue(messageAfterEvent?.isHardDeleted == true)
    }

    func test_saveEvent_whenMessageDelete_whenNotHardDeleted_shouldNotHardDeleteMessageFromDatabase() throws {
        let userId: UserId = .unique
        let channelId: ChannelId = .unique
        let messageId: MessageId = .unique

        // Create current user in the DB
        try database.createCurrentUser(id: userId)

        // Create channel in the DB
        try database.createChannel(cid: channelId)

        // Save the message to the DB
        try database.createMessage(id: messageId, authorId: userId, cid: channelId)

        let event = MessageDeletedEvent(
            channelId: channelId.id,
            channelType: channelId.type.rawValue,
            cid: channelId.rawValue,
            createdAt: .unique,
            hardDelete: false,
            type: EventType.messageDeleted.rawValue,
            message: .dummy(messageId: messageId, authorUserId: userId),
            user: .dummy(userId: userId)
        )

        let messageBeforeEvent = database.viewContext.message(id: messageId)

        XCTAssertNotNil(messageBeforeEvent)

        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        let messageAfterEvent = database.viewContext.message(id: messageId)

        XCTAssertNotNil(messageAfterEvent)
    }

    func test_saveEvent_whenMessageDeletedEventHasPreviewMessage_updatesChannelPreview() throws {
        // GIVEN
        let previousMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique
        )

        let previewMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: previousMessage.createdAt.addingTimeInterval(10)
        )

        let channel: ChannelStateResponse = .dummy(
            messages: [
                previousMessage,
                previewMessage
            ]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let event = MessageDeletedEvent(
            channelId: channel.channel?.id ?? .unique,
            channelType: channel.channel?.type ?? "messaging",
            cid: channel.channel?.cid ?? .unique,
            createdAt: .unique,
            hardDelete: false,
            type: EventType.messageDeleted.rawValue,
            message: previewMessage,
            user: .dummy(userId: .unique)
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        // THEN
        let channelDTO = try XCTUnwrap(
            database.viewContext.channel(cid: try ChannelId(cid: channel.channel!.cid))
        )
        XCTAssertEqual(channelDTO.previewMessage?.id, previewMessage.id)
    }

    func test_saveEvent_whenMessageNewEventComes_updatesChannelPreview() throws {
        // GIVEN
        let previewMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique
        )

        let cid = ChannelId.unique
        let channel: ChannelStateResponse = .dummy(
            cid: cid,
            messages: [previewMessage]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let newMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: previewMessage.createdAt.addingTimeInterval(10)
        )

        let event = MessageNewEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.messageNew.rawValue,
            watcherCount: 0,
            message: .dummy()
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        // THEN
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))
        XCTAssertEqual(channelDTO.previewMessage?.id, newMessage.id)
    }

    func test_saveEvent_whenMessageNewEventComes_whenIsThreadReply_thenShowInsideThreadIsTrue() throws {
        // GIVEN
        let cid = ChannelId.unique
        let channel: ChannelStateResponse = .dummy(
            cid: cid,
            messages: []
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let newMessage: Message = .dummy(
            messageId: .unique,
            parentId: .unique,
            authorUserId: .unique,
            cid: cid
        )

        let event = MessageNewEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.messageNew.rawValue,
            watcherCount: 0,
            message: newMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        // THEN
        let messageDTO = try XCTUnwrap(database.viewContext.message(id: newMessage.id))
        XCTAssertEqual(messageDTO.showInsideThread, true)
    }

    func test_saveEvent_whenNotificationMessageNewEventComes_whenIsThreadReply_thenShowInsideThreadIsTrue() throws {
        // GIVEN
        let cid = ChannelId.unique
        let channel: ChannelStateResponse = .dummy(
            cid: cid,
            messages: []
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let newMessage: Message = .dummy(
            messageId: .unique,
            parentId: .unique,
            authorUserId: .unique,
            cid: cid
        )

        let event = NotificationNewMessageEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.messageNew.rawValue,
            message: newMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        // THEN
        let messageDTO = try XCTUnwrap(database.viewContext.message(id: newMessage.id))
        XCTAssertEqual(messageDTO.showInsideThread, true)
    }

    func test_saveEvent_whenMessageNewEventComes_whenUpdateIsOlderThanCurrentPreview_DoesNotUpdateChannelPreview() throws {
        // GIVEN
        let previousPreviewMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique
        )

        let cid = ChannelId.unique
        let channel: ChannelStateResponse = .dummy(
            messages: [previousPreviewMessage]
        )

        let event = MessageNewEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.messageNew.rawValue,
            watcherCount: 0,
            message: previousPreviewMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        // WHEN
        let newMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: previousPreviewMessage.createdAt.addingTimeInterval(-10)
        )

        let messageNewEvent = MessageNewEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: previousPreviewMessage.createdAt.addingTimeInterval(-10),
            type: EventType.messageNew.rawValue,
            watcherCount: 0,
            message: newMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: messageNewEvent)
        }

        // THEN
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))
        XCTAssertEqual(channelDTO.previewMessage?.id, previousPreviewMessage.id)
    }

    func test_saveEvent_whenNotificationMessageNewEventComes_updatesChannelPreview() throws {
        // GIVEN
        let previewMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique
        )

        let cid = ChannelId.unique
        let channel: ChannelStateResponse = .dummy(
            cid: cid,
            messages: [previewMessage]
        )

        // WHEN
        let newMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: previewMessage.createdAt.addingTimeInterval(10)
        )

        let event = NotificationNewMessageEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.messageNew.rawValue,
            message: newMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        // THEN
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))
        XCTAssertEqual(channelDTO.previewMessage?.id, newMessage.id)
    }

    func test_saveEvent_whenNotificationMessageNewEventComes_whenUpdateIsOlderThanCurrentPreview_DoesNotUpdateChannelPreview() throws {
        // GIVEN
        let previousPreviewMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique
        )

        let cid = ChannelId.unique
        let channel: ChannelStateResponse = .dummy(
            cid: cid,
            messages: [previousPreviewMessage]
        )

        let event = NotificationNewMessageEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.messageNew.rawValue,
            message: previousPreviewMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        // WHEN
        let newMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: previousPreviewMessage.createdAt.addingTimeInterval(-10)
        )

        let notificationMessageNewEvent = NotificationNewMessageEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.messageNew.rawValue,
            message: newMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: notificationMessageNewEvent)
        }

        // THEN
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))
        XCTAssertEqual(channelDTO.previewMessage?.id, previousPreviewMessage.id)
    }

    func test_saveEvent_whenChannelTruncatedEventComesWithMessage_updatesChannelPreview() throws {
        // GIVEN
        let previewMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique
        )

        let cid = ChannelId.unique
        let channel: ChannelStateResponse = .dummy(
            cid: cid,
            messages: [previewMessage]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let systemMessage: Message = .dummy(
            type: .system,
            messageId: .unique,
            authorUserId: .unique,
            createdAt: previewMessage.createdAt.addingTimeInterval(10)
        )

        // TODO: missing a message.
        let channelTruncatedEvent = ChannelTruncatedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.channelTruncated.rawValue,
            channel: channel.channel
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: channelTruncatedEvent)
        }

        // THEN
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))
        XCTAssertEqual(channelDTO.previewMessage?.id, systemMessage.id)
    }

    func test_saveEvent_whenChannelTruncatedEventComesWithoutMessage_resetsChannelPreview() throws {
        // GIVEN
        let previewMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique
        )

        let cid = ChannelId.unique
        let channel: ChannelStateResponse = .dummy(
            cid: cid,
            messages: [previewMessage]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let channelTruncatedEvent = ChannelTruncatedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.channelTruncated.rawValue,
            channel: channel.channel
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: channelTruncatedEvent)
        }

        // THEN
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))
        XCTAssertNil(channelDTO.previewMessage)
    }
}
