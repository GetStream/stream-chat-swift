//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

        let eventPayload = NotificationAddedToChannelEventDTO(
            channel: channelPayload.channel,
            cid: channelPayload.channel.cid,
            createdAt: .unique,
            custom: [:],
            member: .dummy()
        )

        // Save the event payload to DB
        try database.writeSynchronously { session in
            try session.saveEvent(event: .typeNotificationAddedToChannelEvent(eventPayload))
        }

        // Try to load the saved channel from DB
        var loadedChannel: ChatChannel? {
            try? database.viewContext.channel(cid: channelId)?.asModel()
        }

        AssertAsync.willBeEqual(loadedChannel?.cid, channelId)

        // Try to load a saved channel owner from DB
        if let userId = channelPayload.channel.createdBy?.id {
            var loadedUser: ChatUser? {
                try? database.viewContext.user(id: userId)?.asModel()
            }

            AssertAsync.willBeEqual(loadedUser?.id, userId)
        }

        // Try to load the saved member from DB
        if let member = channelPayload.channel.members?.first, let memberId = member.memberId {
            var loadedMember: ChatUser? {
                try? database.viewContext.member(userId: memberId, cid: channelId)?.asModel()
            }

            AssertAsync.willBeEqual(loadedMember?.id, memberId)
        }
    }

    func test_messageData_isSavedToDatabase() throws {
        // Prepare an Event payload with a message data
        let channelId: ChannelId = .unique
        let messageId: MessageId = .unique

        let channelPayload: ChannelDetailPayload = dummyPayload(with: channelId).channel

        let userPayload: UserPayload = .dummy(userId: .unique, teams: [], isBanned: true)

        let messagePayload = MessagePayload(
            id: messageId,
            type: .regular,
            user: userPayload,
            createdAt: channelPayload.createdAt.addingTimeInterval(300),
            updatedAt: .unique,
            text: "No, I am your father 🤯",
            showReplyInChannel: false,
            mentionedUsers: [],
            replyCount: 0,
            extraData: [:],
            reactionScores: [:],
            reactionCounts: [:],
            isSilent: false,
            isShadowed: false,
            attachments: []
        )

        let eventPayload = MessageNewEventDTO(
            channel: channelPayload,
            channelMessageCount: 5,
            cid: channelId,
            createdAt: .unique,
            custom: [:],
            message: messagePayload,
            watcherCount: 0
        )

        // Save the event payload to DB
        try database.writeSynchronously { session in
            try session.saveEvent(event: .typeMessageNewEvent(eventPayload))
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
        XCTAssertEqual(loadedChannel.messageCount, 5)
    }

    func test_eventPayloadUnreadChannelCountsByGroup_isSavedToDatabase() throws {
        let currentUserPayload = CurrentUserPayload.dummy(userPayload: .dummy(userId: .unique, role: .admin))
        let unreadChannelCountsByGroup: [String: Int] = [
            "direct": 1,
            "team": 4
        ]

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUserPayload)
            try session.saveEvent(event: .typeMessageNewEvent(MessageNewEventDTO(
                cid: .unique,
                createdAt: .unique,
                custom: [:],
                groupedUnreadChannels: unreadChannelCountsByGroup,
                message: .dummy(messageId: .unique, authorUserId: .unique),
                user: .dummy(userId: .unique),
                watcherCount: 0
            )))
        }

        XCTAssertEqual(database.viewContext.currentUser?.unreadChannelCountsByGroup, unreadChannelCountsByGroup)
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

    func test_saveEvent_unreadCountFromEventPayloadIsApplied() throws {
        let currentUserPayload = CurrentUserPayload.dummy(
            userId: .unique,
            role: .user,
            unreadCount: nil
        )
        let unreadMessages = Int.random(in: 0...Int.max)
        let unreadChannels = Int.random(in: 0...Int.max)
        let unreadThreads = Int.random(in: 0...Int.max)
        let eventPayload = NotificationMarkReadEventDTO(
            createdAt: .unique,
            custom: [:],
            totalUnreadCount: unreadMessages,
            unreadChannels: unreadChannels,
            unreadCount: 0,
            unreadThreads: unreadThreads
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: .typeHealthCheckEvent(HealthCheckEventDTO(
                connectionId: .unique,
                createdAt: .unique,
                custom: [:],
                me: currentUserPayload
            )))
            try session.saveEvent(event: .typeNotificationMarkReadEvent(eventPayload))
        }

        // Load current user
        let currentUser = database.viewContext.currentUser

        // Assert unread count is taken from event payload
        XCTAssertEqual(Int64(unreadMessages), currentUser?.unreadMessagesCount)
        XCTAssertEqual(Int64(unreadChannels), currentUser?.unreadChannelsCount)
        XCTAssertEqual(Int64(unreadThreads), currentUser?.unreadThreadsCount)
    }

    func test_saveEvent_mergesUnreadChannelCountsByGroupIntoExistingValues() throws {
        let userId = UserId.unique
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: userId, role: .user))
            try session.mergeCurrentUserUnreadChannelCountsByGroup(["all": 5, "old": 1])
        }

        let eventPayload = MessageNewEventDTO(
            cid: .unique,
            createdAt: .unique,
            custom: [:],
            groupedUnreadChannels: ["all": 7, "new": 2],
            message: .dummy(messageId: .unique, authorUserId: .unique)
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: .typeMessageNewEvent(eventPayload))
        }

        let counters = try database.readSynchronously { $0.currentUser?.unreadChannelCountsByGroup ?? [:] }
        XCTAssertEqual(["all": 7, "new": 2, "old": 1], counters)
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

        let eventPayload = MessageUpdatedEventDTO(
            cid: channelId,
            createdAt: .unique,
            custom: [:],
            message: .dummy(messageId: messageId, authorUserId: userId),
            messageId: messageId
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: .typeMessageUpdatedEvent(eventPayload))
        }

        let message = try XCTUnwrap(database.viewContext.message(id: messageId))
        let quotingMessage = try XCTUnwrap(database.viewContext.message(id: quotingMessageId))

        // We set the same updateAt to to both messages, to trigger a DB update
        XCTAssertEqual(message.updatedAt, quotingMessage.updatedAt)
    }
    
    func test_saveEvent_whenMessageUpdated_shouldSaveMessageWithRestrictedVisibilityLocally() throws {
        let currentUserId = UserId.unique
        let messageId = MessageId.unique
        let cid = ChannelId.unique
        try database.createCurrentUser(id: currentUserId)
        try database.createChannel(cid: cid, withMessages: false)
        
        let eventDTO = MessageUpdatedEventDTO(
            cid: cid,
            createdAt: .distantFuture,
            custom: [:],
            message: .dummy(
                messageId: messageId,
                restrictedVisibility: [currentUserId],
                cid: cid,
                pinned: true
            ),
            user: .dummy(userId: currentUserId)
        )
        try database.writeSynchronously { session in
            try session.saveEvent(event: .typeMessageUpdatedEvent(eventDTO))
        }
        try database.readSynchronously { session in
            let channelDTO = try XCTUnwrap(session.channel(cid: cid))
            // Message is associated with the channel
            XCTAssertTrue(channelDTO.messages.contains(where: { $0.id == messageId }))
            // And locally available
            let messageDTO = session.message(id: messageId)
            XCTAssertEqual(Set(arrayLiteral: currentUserId), messageDTO?.restrictedVisibility)
            // Ensure that we can create the local event message
            let event = eventDTO.toDomainEvent(session: session)
            XCTAssertNotNil(event, "Updated event must be created for restricted visibility messages")
            XCTAssertTrue(event is MessageUpdatedEvent)
        }
    }
    
    func test_saveEvent_whenMessageUpdated_shouldNotSaveMessageWithRestrictedVisibilityLocallyIfCurrentUserNotInTheList() throws {
        let currentUserId = UserId.unique
        let messageId = MessageId.unique
        let cid = ChannelId.unique
        try database.createCurrentUser(id: currentUserId)
        try database.createChannel(cid: cid, withMessages: false)
        
        let eventPayload = MessageUpdatedEventDTO(
            cid: cid,
            createdAt: .distantFuture,
            custom: [:],
            message: .dummy(
                messageId: messageId,
                restrictedVisibility: [.unique],
                cid: cid,
                pinned: true
            ),
            user: .dummy(userId: .unique)
        )
        try database.writeSynchronously { session in
            try session.saveEvent(event: .typeMessageUpdatedEvent(eventPayload))
        }
        try database.readSynchronously { session in
            let channelDTO = try XCTUnwrap(session.channel(cid: cid))
            // Message is not saved if the current user is not in the restricted visibility list
            XCTAssertFalse(channelDTO.messages.contains(where: { $0.id == messageId }))
        }
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

        let eventPayload = MessageDeletedEventDTO(
            cid: channelId,
            createdAt: .unique,
            custom: [:],
            hardDelete: true,
            message: .dummy(messageId: messageId, authorUserId: userId),
            messageId: messageId
        )

        let messageBeforeEvent = database.viewContext.message(id: messageId)

        XCTAssertNotNil(messageBeforeEvent)

        try database.writeSynchronously { session in
            try session.saveEvent(event: .typeMessageDeletedEvent(eventPayload))
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

        let eventPayload = MessageDeletedEventDTO(
            cid: channelId,
            createdAt: .unique,
            custom: [:],
            hardDelete: false,
            message: .dummy(messageId: messageId, authorUserId: userId),
            messageId: messageId
        )

        let messageBeforeEvent = database.viewContext.message(id: messageId)

        XCTAssertNotNil(messageBeforeEvent)

        try database.writeSynchronously { session in
            try session.saveEvent(event: .typeMessageDeletedEvent(eventPayload))
        }

        let messageAfterEvent = database.viewContext.message(id: messageId)

        XCTAssertNotNil(messageAfterEvent)
    }

    func test_saveEvent_whenMessageNewEventComes_whenIsThreadReply_thenShowInsideThreadIsTrue() throws {
        // GIVEN
        let channel: ChannelPayload = .dummy(
            messages: []
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let newMessage: MessagePayload = .dummy(
            messageId: .unique,
            parentId: .unique,
            authorUserId: .unique,
            cid: channel.channel.cid
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channel.channel.cid,
            createdAt: .unique,
            custom: [:],
            message: newMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: .typeMessageNewEvent(messageNewEvent))
        }

        // THEN
        let messageDTO = try XCTUnwrap(database.viewContext.message(id: newMessage.id))
        XCTAssertEqual(messageDTO.showInsideThread, true)
    }

    func test_saveEvent_whenNotificationMessageNewEventComes_whenIsThreadReply_thenShowInsideThreadIsTrue() throws {
        // GIVEN
        let channel: ChannelPayload = .dummy(
            messages: []
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let newMessage: MessagePayload = .dummy(
            messageId: .unique,
            parentId: .unique,
            authorUserId: .unique,
            cid: channel.channel.cid
        )

        let messageNewEvent = NotificationNewMessageEventDTO(
            channel: channel.channel,
            cid: channel.channel.cid,
            createdAt: .unique,
            custom: [:],
            message: newMessage,
            messageId: newMessage.id,
            watcherCount: 0
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: .typeNotificationNewMessageEvent(messageNewEvent))
        }

        // THEN
        let messageDTO = try XCTUnwrap(database.viewContext.message(id: newMessage.id))
        XCTAssertEqual(messageDTO.showInsideThread, true)
    }

    func test_saveEvent_whenMessageNewEventComes_whenMessageIsNotMarkedAsSent_markItAsSent() throws {
        // GIVEN
        let channel: ChannelPayload = .dummy(channel: .dummy(cid: .unique))

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let newMessage: MessagePayload = .dummy(
            messageId: .unique,
            parentId: .unique,
            authorUserId: .unique,
            cid: channel.channel.cid
        )

        // Save a message in pending state (SendMessageInterceptor use case)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
            let dto = try session.saveMessage(
                payload: newMessage,
                syncOwnReactions: false,
                skipDraftUpdate: true,
                cache: nil
            )
            dto.localMessageState = .sending
        }

        let messageNewEvent = MessageNewEventDTO(
            cid: channel.channel.cid,
            createdAt: .unique,
            custom: [:],
            message: newMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: .typeMessageNewEvent(messageNewEvent))
        }

        // THEN
        let messageDTO = try XCTUnwrap(database.viewContext.message(id: newMessage.id))
        XCTAssertEqual(messageDTO.showInsideThread, true)
        XCTAssertNil(messageDTO.localMessageState)
    }

    func test_saveEvent_whenMessageNewEventComes_latestMessagesFirstReflectsNewMessage() throws {
        // GIVEN
        let existingMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1000)
        )

        let channel: ChannelPayload = .dummy(
            messages: [existingMessage]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let newMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 2000)
        )

        let messageNewEvent = MessageNewEventDTO(
            channel: channel.channel,
            cid: channel.channel.cid,
            createdAt: .unique,
            custom: [:],
            message: newMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: .typeMessageNewEvent(messageNewEvent))
        }

        // THEN
        let channelModel = try XCTUnwrap(
            database.viewContext.channel(cid: channel.channel.cid)?.asModel()
        )
        XCTAssertEqual(channelModel.latestMessages.first?.id, newMessage.id)
    }

    func test_saveEvent_whenMessageNewEventComesWithoutChannelMessageCount_keepsExistingChannelMessageCount() throws {
        let existingMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique
        )
        let channel: ChannelPayload = .dummy(
            channel: .dummy(messageCount: 1),
            messages: [existingMessage]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        let newMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: existingMessage.createdAt.addingTimeInterval(10)
        )

        let messageNewEvent = MessageNewEventDTO(
            channel: channel.channel,
            cid: channel.channel.cid,
            createdAt: .unique,
            custom: [:],
            message: newMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: .typeMessageNewEvent(messageNewEvent))
        }

        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: channel.channel.cid))
        XCTAssertEqual(channelDTO.messageCount?.intValue, 1)
    }

    func test_saveEvent_whenNotificationMessageNewEventComesWithoutChannelMessageCount_keepsExistingChannelMessageCount() throws {
        let existingMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique
        )
        let channel: ChannelPayload = .dummy(
            channel: .dummy(messageCount: 1),
            messages: [existingMessage]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        let newMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: existingMessage.createdAt.addingTimeInterval(10)
        )

        let messageNewEvent = NotificationNewMessageEventDTO(
            channel: channel.channel,
            cid: channel.channel.cid,
            createdAt: .unique,
            custom: [:],
            message: newMessage,
            messageId: newMessage.id,
            watcherCount: 0
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: .typeNotificationNewMessageEvent(messageNewEvent))
        }

        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: channel.channel.cid))
        XCTAssertEqual(channelDTO.messageCount?.intValue, 1)
    }

    func test_saveEvent_whenMessageNewEventComesWithoutChannelMessageCountAndStoredCountIsMissing_keepsMessageCountNil() throws {
        let channel: ChannelPayload = .dummy(
            channel: .dummy(messageCount: nil),
            messages: []
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        let newMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique
        )

        let messageNewEvent = MessageNewEventDTO(
            channel: channel.channel,
            cid: channel.channel.cid,
            createdAt: .unique,
            custom: [:],
            message: newMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: .typeMessageNewEvent(messageNewEvent))
        }

        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: channel.channel.cid))
        XCTAssertNil(channelDTO.messageCount)
    }

    func test_saveEvent_whenMessageHardDeletedEvent_latestMessagesExcludesHardDeletedMessage() throws {
        // GIVEN
        let previousMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1000)
        )
        let message: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 2000)
        )

        let channel: ChannelPayload = .dummy(
            messages: [previousMessage, message]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let hardDeletedMessage: MessagePayload = .dummy(
            messageId: message.id,
            authorUserId: message.user.id,
            createdAt: message.createdAt,
            deletedAt: Date(timeIntervalSince1970: 3000)
        )

        let messageDeletedEvent = MessageDeletedEventDTO(
            cid: channel.channel.cid,
            createdAt: .unique,
            custom: [:],
            hardDelete: true,
            message: hardDeletedMessage,
            messageId: hardDeletedMessage.id
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: .typeMessageDeletedEvent(messageDeletedEvent))
        }

        // THEN
        let channelModel = try XCTUnwrap(
            database.viewContext.channel(cid: channel.channel.cid)?.asModel()
        )
        XCTAssertEqual(channelModel.latestMessages.map(\.id), [previousMessage.id])
        XCTAssertTrue(database.viewContext.message(id: message.id)?.isHardDeleted == true)
    }

    func test_saveEvent_whenMessageDeletedEvent_latestMessagesFirstStillReturnsDeletedMessage() throws {
        // GIVEN
        let message: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1000)
        )

        let channel: ChannelPayload = .dummy(
            messages: [message]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let deletedMessage: MessagePayload = .dummy(
            messageId: message.id,
            authorUserId: message.user.id,
            createdAt: message.createdAt,
            deletedAt: Date(timeIntervalSince1970: 2000)
        )

        let messageDeletedEvent = MessageDeletedEventDTO(
            cid: channel.channel.cid,
            createdAt: .unique,
            custom: [:],
            message: deletedMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: .typeMessageDeletedEvent(messageDeletedEvent))
        }

        // THEN
        let channelModel = try XCTUnwrap(
            database.viewContext.channel(cid: channel.channel.cid)?.asModel()
        )
        XCTAssertEqual(channelModel.latestMessages.first?.id, message.id)
        XCTAssertNotNil(channelModel.latestMessages.first?.deletedAt)
    }

    func test_saveEvent_whenChannelTruncatedEventWithMessage_latestMessagesFirstReturnsSystemMessage() throws {
        // GIVEN
        let existingMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1000)
        )

        let channel: ChannelPayload = .dummy(
            messages: [existingMessage]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let systemMessage: MessagePayload = .dummy(
            type: .system,
            messageId: .unique,
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 2000)
        )

        let channelTruncatedEvent = ChannelTruncatedEventDTO(
            channel: .dummy(cid: channel.channel.cid, truncatedAt: systemMessage.createdAt),
            cid: channel.channel.cid,
            createdAt: .unique,
            custom: [:],
            message: systemMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: .typeChannelTruncatedEvent(channelTruncatedEvent))
        }

        // THEN
        let channelModel = try XCTUnwrap(
            database.viewContext.channel(cid: channel.channel.cid)?.asModel()
        )
        XCTAssertEqual(channelModel.latestMessages.first?.id, systemMessage.id)
    }

    func test_saveEvent_whenPollVoteRemoved_deletesTheVote() throws {
        // GIVEN
        let pollOptionId = "345"
        let pollId = "123"
        nonisolated(unsafe) var voteId: String!
        let currentUserId = String.unique
        
        let payload = XCTestCase().dummyPollVotePayload(optionId: pollOptionId, pollId: pollId)
        
        try database.createCurrentUser(id: currentUserId)
        
        let poll = XCTestCase().dummyPollPayload(id: pollId, user: .dummy(userId: currentUserId))

        try database.writeSynchronously { session in
            try session.savePoll(payload: poll, cache: nil)
        }
        
        try database.writeSynchronously { session in
            let dto = try session.savePollVote(payload: payload, query: nil, cache: nil)
            voteId = dto.id
        }
        
        // THEN
        XCTAssertNotNil(try database.viewContext.pollVote(id: voteId, pollId: pollId))
        
        // WHEN
        let votePayload = XCTestCase().dummyPollVotePayload(id: voteId, optionId: pollOptionId, pollId: pollId)
        let event = WSEvent.typePollVoteRemovedEvent(
            PollVoteRemovedEventDTO(
                createdAt: .unique,
                custom: [:],
                poll: poll,
                pollVote: votePayload
            )
        )
        
        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }
        
        // THEN
        XCTAssertNil(try database.viewContext.pollVote(id: voteId, pollId: pollId))
    }
    
    func test_saveEvent_whenVoteChanged_updatesTheVote() throws {
        // GIVEN
        let pollOptionId = "345"
        let pollId = "123"
        nonisolated(unsafe) var voteId: String!
        let currentUserId = String.unique
        let secondOptionId = "789"
        let firstOption = PollOptionPayload(custom: [:], id: pollOptionId, text: "First")
        let secondOption = PollOptionPayload(custom: [:], id: secondOptionId, text: "Second")
        
        let payload = XCTestCase().dummyPollVotePayload(optionId: pollOptionId, pollId: pollId)
        
        try database.createCurrentUser(id: currentUserId)
        
        let poll = XCTestCase().dummyPollPayload(
            id: pollId,
            options: [firstOption, secondOption],
            user: .dummy(userId: currentUserId)
        )

        try database.writeSynchronously { session in
            try session.savePoll(payload: poll, cache: nil)
        }
        
        try database.writeSynchronously { session in
            let dto = try session.savePollVote(payload: payload, query: nil, cache: nil)
            voteId = dto.id
        }
        
        // THEN
        let initialVote = try database.viewContext.pollVote(id: voteId, pollId: pollId)
        XCTAssertNotNil(initialVote)
        XCTAssertEqual(initialVote?.optionId, pollOptionId)
        
        // WHEN
        let votePayload = XCTestCase().dummyPollVotePayload(
            id: voteId,
            optionId: secondOptionId,
            pollId: pollId,
            userId: currentUserId
        )
        let event = WSEvent.typePollVoteChangedEvent(
            PollVoteChangedEventDTO(
                createdAt: .unique,
                custom: [:],
                poll: poll,
                pollVote: votePayload
            )
        )
        
        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }
        
        // THEN
        let vote = try database.viewContext.pollVote(id: voteId, pollId: pollId)
        XCTAssertNotNil(vote)
        XCTAssertEqual(vote?.optionId, secondOptionId)
    }
    
    func test_saveEvent_whenVoteCasted_savesTheVote() throws {
        // GIVEN
        let pollOptionId = "345"
        let pollId = "123"
        let currentUserId = String.unique
        let firstOption = PollOptionPayload(custom: [:], id: pollOptionId, text: "First")
                
        try database.createCurrentUser(id: currentUserId)
        
        let poll = XCTestCase().dummyPollPayload(
            id: pollId,
            options: [firstOption],
            user: .dummy(userId: currentUserId)
        )

        try database.writeSynchronously { session in
            try session.savePoll(payload: poll, cache: nil)
        }
        
        // WHEN
        let voteId = String.unique
        let votePayload = XCTestCase().dummyPollVotePayload(
            id: voteId,
            optionId: pollOptionId,
            pollId: pollId,
            userId: currentUserId
        )
        let event = WSEvent.typePollVoteCastedEvent(
            PollVoteCastedEventDTO(
                createdAt: .unique,
                custom: [:],
                poll: poll,
                pollVote: votePayload
            )
        )
        
        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }
        
        // THEN
        let vote = try database.viewContext.pollVote(id: voteId, pollId: pollId)
        XCTAssertNotNil(vote)
        XCTAssertEqual(vote?.id, voteId)
        XCTAssertEqual(vote?.optionId, pollOptionId)
    }
    
    func test_saveEvent_whenAnswerCasted_updatesTheAnswer() throws {
        // GIVEN
        let pollId = "123"
        let currentUserId = String.unique
        let firstAnswer = "First"
        let secondAnswer = "Second"
                
        try database.createCurrentUser(id: currentUserId)
        
        let poll = XCTestCase().dummyPollPayload(
            id: pollId,
            user: .dummy(userId: currentUserId)
        )

        try database.writeSynchronously { session in
            try session.savePoll(payload: poll, cache: nil)
        }
        
        // WHEN
        let voteId = String.unique
        let votePayload = XCTestCase().dummyPollVotePayload(
            id: voteId,
            optionId: nil,
            pollId: pollId,
            answerText: firstAnswer,
            isAnswer: true,
            userId: currentUserId
        )
        let event = WSEvent.typePollVoteCastedEvent(
            PollVoteCastedEventDTO(
                createdAt: .unique,
                custom: [:],
                poll: poll,
                pollVote: votePayload
            )
        )
        
        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }
        
        // THEN
        var vote = try database.viewContext.pollVote(id: voteId, pollId: pollId)
        XCTAssertNotNil(vote)
        XCTAssertEqual(vote?.id, voteId)
        XCTAssertEqual(vote?.answerText, firstAnswer)
        
        // WHEN
        let updatedVotePayload = XCTestCase().dummyPollVotePayload(
            id: voteId,
            optionId: nil,
            pollId: pollId,
            answerText: secondAnswer,
            isAnswer: true,
            userId: currentUserId
        )
        let updatedEvent = WSEvent.typePollVoteCastedEvent(
            PollVoteCastedEventDTO(
                createdAt: .unique,
                custom: [:],
                poll: poll,
                pollVote: updatedVotePayload
            )
        )
        
        try database.writeSynchronously { session in
            try session.saveEvent(event: updatedEvent)
        }
        
        // THEN
        vote = try database.viewContext.pollVote(id: voteId, pollId: pollId)
        XCTAssertNotNil(vote)
        XCTAssertEqual(vote?.id, voteId)
        XCTAssertEqual(vote?.answerText, secondAnswer)
    }

    func test_saveEvent_whenMessageRead_savesUserChannelAndThread() throws {
        let channelId: ChannelId = .unique
        let channelPayload = dummyPayload(with: channelId).channel
        let userPayload: UserPayload = .dummy(userId: .unique)
        let parentMessageId: MessageId = .unique

        try database.writeSynchronously { session in
            try session.saveThread(
                payload: .dummy(
                    parentMessageId: parentMessageId,
                    channel: channelPayload,
                    replyCount: 1,
                    title: "Old Title"
                ),
                cache: nil
            )
        }

        let event = WSEvent.typeMessageReadEvent(
            MessageReadEventDTO(
                channel: channelPayload,
                cid: channelId,
                createdAt: .unique,
                custom: [:],
                thread: ThreadResponse(
                    channelCid: channelId.rawValue,
                    createdAt: .unique,
                    custom: [:],
                    parentMessageId: parentMessageId,
                    participantCount: 3,
                    replyCount: 10,
                    title: "New Title",
                    updatedAt: .unique
                ),
                user: userPayload
            )
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        try database.readSynchronously { session in
            XCTAssertNotNil(session.user(id: userPayload.id))
            XCTAssertNotNil(session.channel(cid: channelId))
            let thread = try XCTUnwrap(session.thread(parentMessageId: parentMessageId, cache: nil))
            XCTAssertEqual(thread.title, "New Title")
            XCTAssertEqual(thread.replyCount, 10)
        }
    }

    func test_saveEvent_whenNotificationThreadMessageNew_savesUnreadThreadsAndSkipsMissingMessage() throws {
        let channelId: ChannelId = .unique
        let channelPayload = dummyPayload(with: channelId).channel
        let message: MessagePayload = .dummy(messageId: .unique, authorUserId: .unique, cid: channelId)

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique)))
        }

        let event = WSEvent.typeNotificationThreadMessageNewEvent(
            NotificationThreadMessageNewEventDTO(
                channel: channelPayload,
                cid: channelId,
                createdAt: .unique,
                custom: [:],
                message: message,
                messageId: message.id,
                threadId: .unique,
                unreadThreads: 7,
                watcherCount: 0
            )
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        try database.readSynchronously { session in
            XCTAssertEqual(session.currentUser?.unreadThreadsCount, 7)
            XCTAssertNotNil(session.channel(cid: channelId))
            // The message is not stored locally, and this event must not create it.
            XCTAssertNil(session.message(id: message.id))
        }
    }

    func test_saveEvent_whenThreadUpdated_updatesExistingThread() throws {
        let channelId: ChannelId = .unique
        let channelPayload = dummyPayload(with: channelId).channel
        let parentMessageId: MessageId = .unique

        try database.writeSynchronously { session in
            try session.saveThread(
                payload: .dummy(
                    parentMessageId: parentMessageId,
                    channel: channelPayload,
                    replyCount: 1,
                    title: "Old Title"
                ),
                cache: nil
            )
        }

        let event = WSEvent.typeThreadUpdatedEvent(
            ThreadUpdatedEventDTO(
                cid: channelId,
                createdAt: .unique,
                custom: [:],
                thread: ThreadResponse(
                    channelCid: channelId.rawValue,
                    createdAt: .unique,
                    custom: [:],
                    parentMessageId: parentMessageId,
                    participantCount: 5,
                    replyCount: 12,
                    title: "New Title",
                    updatedAt: .unique
                )
            )
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        try database.readSynchronously { session in
            let thread = try XCTUnwrap(session.thread(parentMessageId: parentMessageId, cache: nil))
            XCTAssertEqual(thread.title, "New Title")
            XCTAssertEqual(thread.replyCount, 12)
            XCTAssertEqual(thread.participantCount, 5)
        }
    }

    func test_saveEvent_whenPollClosed_savesThePoll() throws {
        let pollId: String = .unique
        let poll = XCTestCase().dummyPollPayload(id: pollId, name: "Closed Poll", isClosed: true)

        try database.writeSynchronously { session in
            try session.saveEvent(event: .typePollClosedEvent(
                PollClosedEventDTO(createdAt: .unique, custom: [:], poll: poll)
            ))
        }

        try database.readSynchronously { session in
            let pollDTO = try XCTUnwrap(session.poll(id: pollId))
            XCTAssertEqual(pollDTO.name, "Closed Poll")
            XCTAssertTrue(pollDTO.isClosed)
        }
    }

    func test_saveEvent_whenPollDeleted_savesThePoll() throws {
        let pollId: String = .unique
        let poll = XCTestCase().dummyPollPayload(id: pollId, name: "Deleted Poll")

        try database.writeSynchronously { session in
            try session.saveEvent(event: .typePollDeletedEvent(
                PollDeletedEventDTO(createdAt: .unique, custom: [:], poll: poll)
            ))
        }

        try database.readSynchronously { session in
            let pollDTO = try XCTUnwrap(session.poll(id: pollId))
            XCTAssertEqual(pollDTO.name, "Deleted Poll")
        }
    }

    func test_saveEvent_whenPollUpdated_savesThePoll() throws {
        let pollId: String = .unique
        let poll = XCTestCase().dummyPollPayload(id: pollId, name: "Updated Poll")

        try database.writeSynchronously { session in
            try session.saveEvent(event: .typePollUpdatedEvent(
                PollUpdatedEventDTO(createdAt: .unique, custom: [:], poll: poll)
            ))
        }

        try database.readSynchronously { session in
            let pollDTO = try XCTUnwrap(session.poll(id: pollId))
            XCTAssertEqual(pollDTO.name, "Updated Poll")
        }
    }
}
