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

        let channel = try XCTUnwrap(channelPayload.channel)
        let event: WSEvent = .typeNotificationAddedToChannelEvent(
            NotificationAddedToChannelEventDTO(
                channel: channel,
                cid: channelId.rawValue,
                createdAt: Date(),
                custom: [:],
                member: channel.members?.first ?? .dummy()
            )
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
                try? database.viewContext.member(userId: member.userId!, cid: channelId)?.asModel()
            }

            AssertAsync.willBeEqual(loadedMember?.id, member.userId!)
        }
    }

    func test_messageData_isSavedToDatabase() throws {
        // Prepare an Event payload with a message data
        let channelId: ChannelId = .unique
        let messageId: MessageId = .unique

        let channelPayload: ChannelResponse = dummyPayload(with: channelId).channel!

        let userPayload: UserResponse = .init(
            id: .unique,
            name: .unique,
            imageURL: .unique(),
            role: .admin,
            teamsRole: nil,
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

        let messagePayload = MessageResponse.dummy(
            messageId: messageId,
            attachments: [],
            authorUserId: userPayload.id,
            text: "No, I am your father 🤯",
            extraData: [:],
            createdAt: channelPayload.createdAt.addingTimeInterval(300),
            updatedAt: .unique,
            reactionScores: [:],
            reactionCounts: [:],
            mentionedUsers: []
        )

        let event: WSEvent = .typeMessageNewEvent(
            MessageNewEventDTO(
                channel: channelPayload,
                channelMessageCount: 5,
                cid: channelId.rawValue,
                createdAt: Date(),
                custom: [:],
                message: messagePayload,
                messageId: messageId,
                watcherCount: 0
            )
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
        XCTAssertEqual(loadedChannel.messageCount, 5)
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

        let event: WSEvent = .typeMessageUpdatedEvent(
            MessageUpdatedEventDTO(
                cid: channelId.rawValue,
                createdAt: Date(),
                custom: [:],
                message: .dummy(messageId: messageId, authorUserId: userId),
                messageId: messageId
            )
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
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
        
        let messagePayload: MessageResponse = .dummy(
            messageId: messageId,
            restrictedVisibility: [currentUserId],
            cid: cid,
            pinned: true
        )
        let dto = MessageUpdatedEventDTO(
            cid: cid.rawValue,
            createdAt: .distantFuture,
            custom: [:],
            message: messagePayload,
            messageId: messageId,
            user: UserResponseCommonFields(.dummy(userId: currentUserId))
        )
        try database.writeSynchronously { session in
            try session.saveEvent(event: .typeMessageUpdatedEvent(dto))
        }
        try database.readSynchronously { session in
            let channelDTO = try XCTUnwrap(session.channel(cid: cid))
            // Message is associated with the channel
            XCTAssertTrue(channelDTO.messages.contains(where: { $0.id == messageId }))
            // And locally available
            let messageDTO = session.message(id: messageId)
            XCTAssertEqual(Set(arrayLiteral: currentUserId), messageDTO?.restrictedVisibility)
            // Ensure that we can create the local event message
            let event = dto.toDomainEvent(session: session)
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

        let event: WSEvent = .typeMessageUpdatedEvent(
            MessageUpdatedEventDTO(
                cid: cid.rawValue,
                createdAt: .distantFuture,
                custom: [:],
                message: .dummy(
                    messageId: messageId,
                    restrictedVisibility: [.unique],
                    cid: cid,
                    pinned: true
                ),
                messageId: messageId,
                user: UserResponseCommonFields(.dummy(userId: .unique))
            )
        )
        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
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

        let event: WSEvent = .typeMessageDeletedEvent(
            MessageDeletedEventDTO(
                cid: channelId.rawValue,
                createdAt: Date(),
                custom: [:],
                hardDelete: true,
                message: .dummy(messageId: messageId, authorUserId: userId),
                messageId: messageId
            )
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

        let event: WSEvent = .typeMessageDeletedEvent(
            MessageDeletedEventDTO(
                cid: channelId.rawValue,
                createdAt: Date(),
                custom: [:],
                hardDelete: false,
                message: .dummy(messageId: messageId, authorUserId: userId),
                messageId: messageId
            )
        )

        let messageBeforeEvent = database.viewContext.message(id: messageId)

        XCTAssertNotNil(messageBeforeEvent)

        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        let messageAfterEvent = database.viewContext.message(id: messageId)

        XCTAssertNotNil(messageAfterEvent)
    }

    func test_saveEvent_whenMessageNewEventComes_whenIsThreadReply_thenShowInsideThreadIsTrue() throws {
        // GIVEN
        let channel: ChannelStateResponseFields = .dummy(
            messages: []
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let newMessage: MessageResponse = .dummy(
            messageId: .unique,
            parentId: .unique,
            authorUserId: .unique,
            cid: channel.channel?.channelId
        )

        let event: WSEvent = .typeMessageNewEvent(
            MessageNewEventDTO(
                cid: channel.channel?.channelId?.rawValue,
                createdAt: Date(),
                custom: [:],
                message: newMessage,
                messageId: newMessage.id,
                watcherCount: 0
            )
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
        let channel: ChannelStateResponseFields = .dummy(
            messages: []
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let newMessage: MessageResponse = .dummy(
            messageId: .unique,
            parentId: .unique,
            authorUserId: .unique,
            cid: channel.channel?.channelId
        )

        let event: WSEvent = .typeNotificationNewMessageEvent(
            NotificationNewMessageEventDTO(
                channel: channel.channel!,
                cid: channel.channel?.cid,
                createdAt: Date(),
                custom: [:],
                message: newMessage,
                messageId: newMessage.id,
                watcherCount: 0
            )
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        // THEN
        let messageDTO = try XCTUnwrap(database.viewContext.message(id: newMessage.id))
        XCTAssertEqual(messageDTO.showInsideThread, true)
    }

    func test_saveEvent_whenMessageNewEventComes_whenMessageIsNotMarkedAsSent_markItAsSent() throws {
        // GIVEN
        let channel: ChannelStateResponseFields = .dummy(channel: .dummy(cid: .unique))

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let newMessage: MessageResponse = .dummy(
            messageId: .unique,
            parentId: .unique,
            authorUserId: .unique,
            channel: channel.channel
        )

        // Save a message in pending state (SendMessageInterceptor use case)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
            let dto = try session.saveMessage(
                payload: newMessage,
                for: channel.channel?.channelId,
                syncOwnReactions: false,
                skipDraftUpdate: true,
                cache: nil
            )
            dto.localMessageState = .sending
        }

        let event: WSEvent = .typeMessageNewEvent(
            MessageNewEventDTO(
                cid: channel.channel?.cid,
                createdAt: Date(),
                custom: [:],
                message: newMessage,
                messageId: newMessage.id,
                watcherCount: 0
            )
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        // THEN
        let messageDTO = try XCTUnwrap(database.viewContext.message(id: newMessage.id))
        XCTAssertEqual(messageDTO.showInsideThread, true)
        XCTAssertNil(messageDTO.localMessageState)
    }

    func test_saveEvent_whenMessageNewEventComes_latestMessagesFirstReflectsNewMessage() throws {
        // GIVEN
        let existingMessage: MessageResponse = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1000)
        )

        let channel: ChannelStateResponseFields = .dummy(
            messages: [existingMessage]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let newMessage: MessageResponse = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 2000)
        )

        let event: WSEvent = .typeMessageNewEvent(
            MessageNewEventDTO(
                channel: channel.channel,
                cid: channel.channel?.cid,
                createdAt: Date(),
                custom: [:],
                message: newMessage,
                messageId: newMessage.id,
                watcherCount: 0
            )
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        // THEN
        let channelModel = try XCTUnwrap(
            database.viewContext.channel(cid: channel.channel!.channelId!)?.asModel()
        )
        XCTAssertEqual(channelModel.latestMessages.first?.id, newMessage.id)
    }

    func test_saveEvent_whenMessageDeletedEvent_latestMessagesFirstStillReturnsDeletedMessage() throws {
        // GIVEN
        let message: MessageResponse = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1000)
        )

        let channel: ChannelStateResponseFields = .dummy(
            messages: [message]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let deletedMessage: MessageResponse = .dummy(
            messageId: message.id,
            authorUserId: message.user.id,
            createdAt: message.createdAt,
            deletedAt: Date(timeIntervalSince1970: 2000)
        )

        let event: WSEvent = .typeMessageDeletedEvent(
            MessageDeletedEventDTO(
                cid: channel.channel?.cid,
                createdAt: Date(),
                custom: [:],
                hardDelete: false,
                message: deletedMessage,
                messageId: deletedMessage.id
            )
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        // THEN
        let channelModel = try XCTUnwrap(
            database.viewContext.channel(cid: channel.channel!.channelId!)?.asModel()
        )
        XCTAssertEqual(channelModel.latestMessages.first?.id, message.id)
        XCTAssertNotNil(channelModel.latestMessages.first?.deletedAt)
    }

    func test_saveEvent_whenChannelTruncatedEventWithMessage_latestMessagesFirstReturnsSystemMessage() throws {
        // GIVEN
        let existingMessage: MessageResponse = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1000)
        )

        let channel: ChannelStateResponseFields = .dummy(
            messages: [existingMessage]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let systemMessage: MessageResponse = .dummy(
            type: .system,
            messageId: .unique,
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 2000)
        )

        let event: WSEvent = .typeChannelTruncatedEvent(
            ChannelTruncatedEventDTO(
                channel: .dummy(cid: channel.channel?.channelId ?? .unique, truncatedAt: systemMessage.createdAt),
                cid: channel.channel?.cid,
                createdAt: Date(),
                custom: [:],
                message: systemMessage
            )
        )

        try database.writeSynchronously { session in
            try session.saveEvent(event: event)
        }

        // THEN
        let channelModel = try XCTUnwrap(
            database.viewContext.channel(cid: channel.channel!.channelId!)?.asModel()
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
        let event: WSEvent = .typePollVoteRemovedEvent(
            PollVoteRemovedEventDTO(
                createdAt: Date(),
                custom: [:],
                poll: XCTestCase().dummyPollPayload(id: pollId),
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
        let firstOption = PollOptionResponseData(custom: [:], id: pollOptionId, text: "First")
        let secondOption = PollOptionResponseData(custom: [:], id: secondOptionId, text: "Second")
        
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
        let event: WSEvent = .typePollVoteChangedEvent(
            PollVoteChangedEventDTO(
                createdAt: Date(),
                custom: [:],
                poll: XCTestCase().dummyPollPayload(id: pollId),
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
        let firstOption = PollOptionResponseData(custom: [:], id: pollOptionId, text: "First")
                
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
        let event: WSEvent = .typePollVoteCastedEvent(
            PollVoteCastedEventDTO(
                createdAt: Date(),
                custom: [:],
                poll: XCTestCase().dummyPollPayload(id: pollId),
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
        let event: WSEvent = .typePollVoteCastedEvent(
            PollVoteCastedEventDTO(
                createdAt: Date(),
                custom: [:],
                poll: XCTestCase().dummyPollPayload(id: pollId),
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
        let updatedEvent: WSEvent = .typePollVoteCastedEvent(
            PollVoteCastedEventDTO(
                createdAt: Date(),
                custom: [:],
                poll: XCTestCase().dummyPollPayload(id: pollId),
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
}
