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

        let eventPayload = EventPayload(
            eventType: .notificationAddedToChannel,
            connectionId: .unique,
            cid: channelPayload.channel.cid,
            channel: channelPayload.channel
        )

        // Save the event payload to DB
        try database.writeSynchronously { session in
            try session.saveEvent(payload: eventPayload)
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
        if let member = channelPayload.channel.members?.first {
            var loadedMember: ChatUser? {
                try? database.viewContext.member(userId: member.userId, cid: channelId)?.asModel()
            }

            AssertAsync.willBeEqual(loadedMember?.id, member.userId)
        }
    }

    func test_messageData_isSavedToDatabase() throws {
        // Prepare an Event payload with a message data
        let channelId: ChannelId = .unique
        let messageId: MessageId = .unique

        let channelPayload: ChannelDetailPayload = dummyPayload(with: channelId).channel

        let userPayload: UserPayload = .init(
            id: .unique,
            name: .unique,
            imageURL: .unique(),
            role: .admin,
            createdAt: .unique,
            updatedAt: .unique,
            deactivatedAt: nil,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            language: nil,
            extraData: [:]
        )

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

        let eventPayload: EventPayload = .init(
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
        try database.writeSynchronously { session in
            try session.saveEvent(payload: eventPayload)
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

    func test_saveEvent_unreadCountFromEventPayloadIsApplied() throws {
        let eventPayload = EventPayload(
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
        let currentUser = database.viewContext.currentUser

        // Assert unread count is taken from event payload
        XCTAssertEqual(Int64(eventPayload.unreadCount!.messages!), currentUser?.unreadMessagesCount)
        XCTAssertEqual(Int64(eventPayload.unreadCount!.channels!), currentUser?.unreadChannelsCount)
        XCTAssertEqual(Int64(eventPayload.unreadCount!.threads!), currentUser?.unreadThreadsCount)
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
        // Create event payload with missing `createdAt`
        let eventPayload = EventPayload(
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

        let eventPayload = EventPayload(
            eventType: .messageUpdated,
            connectionId: .unique,
            cid: channelId,
            currentUser: .dummy(
                userId: userId,
                role: .user,
                unreadCount: nil
            ),
            message: .dummy(messageId: messageId, authorUserId: userId),
            unreadCount: .dummy,
            createdAt: nil
        )

        try database.writeSynchronously { session in
            try session.saveEvent(payload: eventPayload)
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

        let eventPayload = EventPayload(
            eventType: .messageDeleted,
            connectionId: .unique,
            cid: channelId,
            currentUser: .dummy(
                userId: userId,
                role: .user,
                unreadCount: nil
            ),
            message: .dummy(messageId: messageId, authorUserId: userId),
            unreadCount: .dummy,
            createdAt: nil,
            hardDelete: true
        )

        let messageBeforeEvent = database.viewContext.message(id: messageId)

        XCTAssertNotNil(messageBeforeEvent)

        try database.writeSynchronously { session in
            try session.saveEvent(payload: eventPayload)
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

        let eventPayload = EventPayload(
            eventType: .messageDeleted,
            connectionId: .unique,
            cid: channelId,
            currentUser: .dummy(
                userId: userId,
                role: .user,
                unreadCount: nil
            ),
            message: .dummy(messageId: messageId, authorUserId: userId),
            unreadCount: .dummy,
            createdAt: nil,
            hardDelete: false
        )

        let messageBeforeEvent = database.viewContext.message(id: messageId)

        XCTAssertNotNil(messageBeforeEvent)

        try database.writeSynchronously { session in
            try session.saveEvent(payload: eventPayload)
        }

        let messageAfterEvent = database.viewContext.message(id: messageId)

        XCTAssertNotNil(messageAfterEvent)
    }

    func test_saveEvent_whenMessageDeletedEventHasPreviewMessage_updatesChannelPreview() throws {
        // GIVEN
        let previousMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique
        )

        let previewMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: previousMessage.createdAt.addingTimeInterval(10)
        )

        let channel: ChannelPayload = .dummy(
            messages: [
                previousMessage,
                previewMessage
            ]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let messageDeletedEvent = EventPayload(
            eventType: .messageDeleted,
            cid: channel.channel.cid,
            message: previewMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(payload: messageDeletedEvent)
        }

        // THEN
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: channel.channel.cid))
        XCTAssertEqual(channelDTO.previewMessage?.id, previewMessage.id)
    }

    func test_saveEvent_whenMessageNewEventComes_updatesChannelPreview() throws {
        // GIVEN
        let previewMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique
        )

        let channel: ChannelPayload = .dummy(
            messages: [previewMessage]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let newMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: previewMessage.createdAt.addingTimeInterval(10)
        )

        let messageNewEvent = EventPayload(
            eventType: .messageNew,
            cid: channel.channel.cid,
            message: newMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(payload: messageNewEvent)
        }

        // THEN
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: channel.channel.cid))
        XCTAssertEqual(channelDTO.previewMessage?.id, newMessage.id)
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

        let messageNewEvent = EventPayload(
            eventType: .messageNew,
            cid: channel.channel.cid,
            message: newMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(payload: messageNewEvent)
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

        let messageNewEvent = EventPayload(
            eventType: .notificationMessageNew,
            cid: channel.channel.cid,
            message: newMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(payload: messageNewEvent)
        }

        // THEN
        let messageDTO = try XCTUnwrap(database.viewContext.message(id: newMessage.id))
        XCTAssertEqual(messageDTO.showInsideThread, true)
    }

    func test_saveEvent_whenMessageNewEventComes_whenUpdateIsOlderThanCurrentPreview_DoesNotUpdateChannelPreview() throws {
        // GIVEN
        let previousPreviewMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique
        )

        let channel: ChannelPayload = .dummy(
            messages: [previousPreviewMessage]
        )

        let previousMessageMessageNewEvent = EventPayload(
            eventType: .messageNew,
            cid: channel.channel.cid,
            channel: channel.channel,
            message: previousPreviewMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(payload: previousMessageMessageNewEvent)
        }

        // WHEN
        let newMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: previousPreviewMessage.createdAt.addingTimeInterval(-10)
        )

        let messageNewEvent = EventPayload(
            eventType: .messageNew,
            cid: channel.channel.cid,
            channel: channel.channel,
            message: newMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(payload: messageNewEvent)
        }

        // THEN
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: channel.channel.cid))
        XCTAssertEqual(channelDTO.previewMessage?.id, previousPreviewMessage.id)
    }

    func test_saveEvent_whenNotificationMessageNewEventComes_updatesChannelPreview() throws {
        // GIVEN
        let previewMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique
        )

        let channel: ChannelPayload = .dummy(
            messages: [previewMessage]
        )

        // WHEN
        let newMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: previewMessage.createdAt.addingTimeInterval(10)
        )

        let notificationMessageNewEvent = EventPayload(
            eventType: .notificationMessageNew,
            cid: channel.channel.cid,
            channel: channel.channel,
            message: newMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(payload: notificationMessageNewEvent)
        }

        // THEN
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: channel.channel.cid))
        XCTAssertEqual(channelDTO.previewMessage?.id, newMessage.id)
    }

    func test_saveEvent_whenNotificationMessageNewEventComes_whenUpdateIsOlderThanCurrentPreview_DoesNotUpdateChannelPreview() throws {
        // GIVEN
        let previousPreviewMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique
        )

        let channel: ChannelPayload = .dummy(
            messages: [previousPreviewMessage]
        )

        let previousNotificationMessageNewEvent = EventPayload(
            eventType: .notificationMessageNew,
            cid: channel.channel.cid,
            channel: channel.channel,
            message: previousPreviewMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(payload: previousNotificationMessageNewEvent)
        }

        // WHEN
        let newMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: previousPreviewMessage.createdAt.addingTimeInterval(-10)
        )

        let notificationMessageNewEvent = EventPayload(
            eventType: .notificationMessageNew,
            cid: channel.channel.cid,
            channel: channel.channel,
            message: newMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(payload: notificationMessageNewEvent)
        }

        // THEN
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: channel.channel.cid))
        XCTAssertEqual(channelDTO.previewMessage?.id, previousPreviewMessage.id)
    }

    func test_saveEvent_whenChannelTruncatedEventComesWithMessage_updatesChannelPreview() throws {
        // GIVEN
        let previewMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique
        )

        let channel: ChannelPayload = .dummy(
            messages: [previewMessage]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let systemMessage: MessagePayload = .dummy(
            type: .system,
            messageId: .unique,
            authorUserId: .unique,
            createdAt: previewMessage.createdAt.addingTimeInterval(10)
        )

        let channelTruncatedEvent = EventPayload(
            eventType: .channelTruncated,
            cid: channel.channel.cid,
            channel: .dummy(truncatedAt: systemMessage.createdAt),
            message: systemMessage
        )

        try database.writeSynchronously { session in
            try session.saveEvent(payload: channelTruncatedEvent)
        }

        // THEN
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: channel.channel.cid))
        XCTAssertEqual(channelDTO.previewMessage?.id, systemMessage.id)
    }

    func test_saveEvent_whenChannelTruncatedEventComesWithoutMessage_resetsChannelPreview() throws {
        // GIVEN
        let previewMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique
        )

        let channel: ChannelPayload = .dummy(
            messages: [previewMessage]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let channelTruncatedEventWithoutMessage = EventPayload(
            eventType: .channelTruncated,
            cid: channel.channel.cid,
            channel: .dummy(truncatedAt: previewMessage.createdAt.addingTimeInterval(1)),
            message: nil
        )

        try database.writeSynchronously { session in
            try session.saveEvent(payload: channelTruncatedEventWithoutMessage)
        }

        // THEN
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: channel.channel.cid))
        XCTAssertNil(channelDTO.previewMessage)
    }
    
    func test_saveEvent_whenPollVoteRemoved_deletesTheVote() throws {
        // GIVEN
        let pollOptionId = "345"
        let pollId = "123"
        var voteId: String!
        let currentUserId = String.unique
        
        let payload = XCTestCase().dummyPollVotePayload(optionId: pollOptionId, pollId: pollId)
        
        try database.createCurrentUser(id: currentUserId)
        
        try database.writeSynchronously { session in
            let poll = XCTestCase().dummyPollPayload(id: pollId, user: .dummy(userId: currentUserId))
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
        let event = EventPayload(eventType: .pollVoteRemoved, vote: votePayload)
        
        try database.writeSynchronously { session in
            try session.saveEvent(payload: event)
        }
        
        // THEN
        XCTAssertNil(try database.viewContext.pollVote(id: voteId, pollId: pollId))
    }
    
    func test_saveEvent_whenVoteChanged_updatesTheVote() throws {
        // GIVEN
        let pollOptionId = "345"
        let pollId = "123"
        var voteId: String!
        let currentUserId = String.unique
        let secondOptionId = "789"
        let firstOption = PollOptionPayload(id: pollOptionId, text: "First", custom: [:])
        let secondOption = PollOptionPayload(id: secondOptionId, text: "Second", custom: [:])
        
        let payload = XCTestCase().dummyPollVotePayload(optionId: pollOptionId, pollId: pollId)
        
        try database.createCurrentUser(id: currentUserId)
        
        try database.writeSynchronously { session in
            let poll = XCTestCase().dummyPollPayload(
                id: pollId,
                options: [firstOption, secondOption],
                user: .dummy(userId: currentUserId)
            )
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
        let event = EventPayload(eventType: .pollVoteChanged, vote: votePayload)
        
        try database.writeSynchronously { session in
            try session.saveEvent(payload: event)
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
        let firstOption = PollOptionPayload(id: pollOptionId, text: "First", custom: [:])
                
        try database.createCurrentUser(id: currentUserId)
        
        try database.writeSynchronously { session in
            let poll = XCTestCase().dummyPollPayload(
                id: pollId,
                options: [firstOption],
                user: .dummy(userId: currentUserId)
            )
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
        let event = EventPayload(eventType: .pollVoteCasted, vote: votePayload)
        
        try database.writeSynchronously { session in
            try session.saveEvent(payload: event)
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
        
        try database.writeSynchronously { session in
            let poll = XCTestCase().dummyPollPayload(
                id: pollId,
                user: .dummy(userId: currentUserId)
            )
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
        let event = EventPayload(eventType: .pollVoteCasted, vote: votePayload)
        
        try database.writeSynchronously { session in
            try session.saveEvent(payload: event)
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
        let updatedEvent = EventPayload(eventType: .pollVoteCasted, vote: updatedVotePayload)
        
        try database.writeSynchronously { session in
            try session.saveEvent(payload: updatedEvent)
        }
        
        // THEN
        vote = try database.viewContext.pollVote(id: voteId, pollId: pollId)
        XCTAssertNotNil(vote)
        XCTAssertEqual(vote?.id, voteId)
        XCTAssertEqual(vote?.answerText, secondAnswer)
    }
    
    func test_saveEvent_whenPollCreated_addThePoll() throws {
        // GIVEN
        let pollId = "123"
        let currentUserId = String.unique
                
        try database.createCurrentUser(id: currentUserId)
        
        // WHEN
        let poll = XCTestCase().dummyPollPayload(
            id: pollId,
            user: .dummy(userId: currentUserId)
        )
        let event = EventPayload(eventType: .pollCreated, poll: poll)
        
        try database.writeSynchronously { session in
            try session.saveEvent(payload: event)
        }
        
        // THEN
        let pollDto = try database.viewContext.poll(id: pollId)
        XCTAssertNotNil(pollDto)
        XCTAssertEqual(pollDto?.id, pollId)
    }
}
