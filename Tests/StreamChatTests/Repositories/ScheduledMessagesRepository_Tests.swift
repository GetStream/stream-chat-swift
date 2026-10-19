//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ScheduledMessagesRepository_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer_Spy!
    var repository: ScheduledMessagesRepository!
    var cid: ChannelId!
    var userId: UserId!

    override func setUp() {
        super.setUp()

        client = ChatClient.mock
        apiClient = client.mockAPIClient
        database = client.mockDatabaseContainer
        cid = .unique
        userId = .unique
        client.currentUserId_mock = userId
        repository = ScheduledMessagesRepository(client: client, database: database, apiClient: apiClient)
    }

    override func tearDown() {
        apiClient.cleanUp()
        repository = nil
        database = nil
        apiClient = nil
        client = nil
        cid = nil
        userId = nil

        super.tearDown()
    }

    // MARK: - Schedule

    func test_schedule_sendsTheMessageWithTheScheduleDate() throws {
        let scheduledAt = Date().addingTimeInterval(3600)
        let content = ScheduledMessageContent(
            text: "Hi @mentioned",
            attachments: [],
            mentionedUserIds: ["mentioned"],
            quotedMessageId: "quoted",
            parentId: "parent",
            showReplyInChannel: true,
            extraData: ["key": .string("value")]
        )
        apiClient.test_mockUnmanagedResponseResult(.success(sendMessageResponse(.dummy(id: "scheduled-id"))))

        _ = try waitFor {
            repository.schedule(id: "scheduled-id", cid: cid, content: content, scheduledAt: scheduledAt, completion: $0)
        }.get()

        let expectedEndpoint: Endpoint<SendMessageResponsePayload> = .sendMessage(
            type: cid.type.rawValue,
            id: cid.id,
            sendMessageRequest: SendMessageRequest(
                message: MessageRequest(
                    attachments: [],
                    custom: ["key": .string("value")],
                    id: "scheduled-id",
                    mentionedUsers: ["mentioned"],
                    parentId: "parent",
                    quotedMessageId: "quoted",
                    showInChannel: true,
                    text: "Hi @mentioned"
                ),
                scheduledAt: scheduledAt
            )
        )
        XCTAssertEqual(apiClient.unmanagedRequest_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(apiClient.request_endpoint)
    }

    func test_schedule_returnsTheScheduledMessage_andAddsItToTheList() throws {
        let scheduledAt = Date().addingTimeInterval(3600)
        apiClient.test_mockUnmanagedResponseResult(.success(sendMessageResponse(.dummy(id: "scheduled-id", cid: cid, scheduledAt: scheduledAt))))

        let message = try schedule(id: "scheduled-id", scheduledAt: scheduledAt).get()

        XCTAssertEqual(message.id, "scheduled-id")
        XCTAssertEqual(message.cid, cid)
        XCTAssertEqual(message.scheduledAt, scheduledAt)
        XCTAssertEqual(message.status, .scheduled)
        XCTAssertEqual(repository.scheduledMessages, [message])
    }

    func test_schedule_withoutScheduledMessageInTheResponse_fails() {
        apiClient.test_mockUnmanagedResponseResult(.success(sendMessageResponse(nil)))

        let result = schedule()

        XCTAssertNotNil(result.error)
        XCTAssertEqual(repository.scheduledMessages, [])
    }

    func test_schedule_whenTheRequestFails_failsAndKeepsTheList() {
        let error = ClientError(with: APIError(code: 4, message: "Pick a time at least 1 minute from now", statusCode: 400))
        apiClient.test_mockUnmanagedResponseResult(Result<SendMessageResponsePayload, Error>.failure(error))

        let result = schedule(scheduledAt: Date().addingTimeInterval(30))

        XCTAssertEqual((result.error as? ClientError)?.localizedDescription, error.localizedDescription)
        XCTAssertEqual(repository.scheduledMessages, [])
    }

    // MARK: - Message to render

    func test_asModel_exposesTheMessageToRenderAuthoredByTheScheduler() throws {
        let scheduledAt = Date().addingTimeInterval(3600)
        let response = ScheduledMessageResponse.dummy(
            id: "scheduled-id",
            cid: cid,
            user: .dummy(userId: userId, name: "Alice"),
            message: .dummy(
                text: "Hi @mentioned",
                custom: ["key": .string("value")],
                mentionedUsers: ["mentioned"],
                parentId: "parent",
                quotedMessageId: "quoted",
                showInChannel: true
            ),
            scheduledAt: scheduledAt
        )

        let message = try XCTUnwrap(model(from: response))

        XCTAssertEqual(message.message.id, "scheduled-id")
        XCTAssertEqual(message.message.cid, cid)
        XCTAssertEqual(message.message.author.id, userId)
        XCTAssertEqual(message.message.author.name, "Alice")
        XCTAssertTrue(message.message.isSentByCurrentUser)
        XCTAssertEqual(message.message.createdAt, scheduledAt)
        XCTAssertEqual(message.message.type, .reply)
        XCTAssertEqual(message.message.parentMessageId, "parent")
        XCTAssertTrue(message.message.showReplyInChannel)
        XCTAssertEqual(message.message.mentionedUsers.map(\.id), ["mentioned"])
        XCTAssertEqual(message.message.extraData["key"], .string("value"))
        XCTAssertEqual(message.quotedMessageId, "quoted")
    }

    func test_asModel_resolvesTheMentionsAndTheQuotedMessageFromTheDatabase() throws {
        try database.createCurrentUser(id: userId)
        try database.createChannel(cid: cid)
        let mentionedId = UserId.unique
        let quotedId = MessageId.unique
        try database.createUser(id: mentionedId)
        let mentionedName = try XCTUnwrap(database.viewContext.user(id: mentionedId)?.name)
        try database.createMessage(id: quotedId, authorId: userId, cid: cid, text: "Quoted")
        let response = ScheduledMessageResponse.dummy(
            cid: cid,
            user: .dummy(userId: userId),
            message: .dummy(mentionedUsers: [mentionedId], quotedMessageId: quotedId)
        )

        let message = try XCTUnwrap(model(from: response))

        XCTAssertEqual(message.message.mentionedUsers.first?.name, mentionedName)
        XCTAssertEqual(message.message.quotedMessage?.id, quotedId)
        XCTAssertEqual(message.message.quotedMessage?.text, "Quoted")
    }

    func test_asModel_exposesTheAttachments() throws {
        let response = ScheduledMessageResponse.dummy(
            id: "scheduled-id",
            cid: cid,
            message: .dummy(attachments: [
                .dummy(type: .image, title: "Photo", imageURL: URL(string: "https://example.com/image.png")!)
            ])
        )

        let message = try XCTUnwrap(model(from: response))

        let attachment = try XCTUnwrap(message.message.imageAttachments.first)
        XCTAssertEqual(attachment.imageURL, URL(string: "https://example.com/image.png"))
        XCTAssertEqual(attachment.title, "Photo")
        XCTAssertEqual(attachment.id.messageId, "scheduled-id")
    }

    func test_asModel_exposesTheChannelSummaryOfTheResponse() throws {
        let response = ScheduledMessageResponse.dummy(
            cid: cid,
            channel: .init(cid: cid.rawValue, id: cid.id, image: "https://example.com/channel.png", name: "General", type: cid.type.rawValue)
        )

        let message = try XCTUnwrap(model(from: response))

        XCTAssertEqual(message.channel.cid, cid)
        XCTAssertEqual(message.channel.type, cid.type)
        XCTAssertEqual(message.channel.id, cid.id)
        XCTAssertEqual(message.channel.name, "General")
        XCTAssertEqual(message.channel.imageURL, URL(string: "https://example.com/channel.png"))
    }

    func test_asModel_withoutChannelInTheResponse_usesTheLocalChannel() throws {
        try database.createChannel(cid: cid)
        let localChannel = try XCTUnwrap(DataStore(client: client).channel(cid: cid))

        let message = try XCTUnwrap(model(from: .dummy(cid: cid)))

        XCTAssertNotNil(localChannel.name)
        XCTAssertEqual(message.channel.name, localChannel.name)
        XCTAssertEqual(message.channel.imageURL, localChannel.imageURL)
    }

    func test_asModel_withoutChannelInTheResponse_andNoLocalChannel_exposesTheChannelWithoutName() throws {
        let message = try XCTUnwrap(model(from: .dummy(cid: cid)))

        XCTAssertEqual(message.channel.cid, cid)
        XCTAssertNil(message.channel.name)
        XCTAssertNil(message.channel.imageURL)
    }

    func test_asModel_exposesTheStatusAndTheFailureReason() throws {
        let response = ScheduledMessageResponse.dummy(cid: cid, status: "failed", failureReason: "channel_frozen")

        let message = try XCTUnwrap(model(from: response))

        XCTAssertEqual(message.status, .failed)
        XCTAssertEqual(message.failureReason, .channelFrozen)
        XCTAssertFalse(message.isPending)
    }

    func test_asModel_withInvalidChannelId_returnsNil() {
        XCTAssertNil(model(from: .dummy(rawCid: "invalid")))
    }

    func test_decoding_theBackendResponse() throws {
        let json = """
        {"scheduled_messages":[{"id":"ed08342b","cid":"messaging:sdk-general","user":{"id":"alice","name":"Alice","image":"https://example.com/alice.png","custom":{"birthland":"Staging"},"language":"","role":"user","teams":[],"created_at":1792418880247724000,"updated_at":1792421345756446000,"banned":false,"online":true,"last_active":1792425445149728740,"blocked_user_ids":[]},"message":{"text":"Reminder","custom":{}},"scheduled_at":1792678087853949000,"status":"scheduled","created_at":1792418888352383000,"updated_at":1792418888352383000,"channel":{"cid":"messaging:sdk-general","type":"messaging","id":"sdk-general","name":"General"}}],"next":"cursor","duration":"5.67ms"}
        """

        let response = try JSONDecoder.stream.decode(QueryScheduledMessagesResponse.self, from: Data(json.utf8))
        let message = try XCTUnwrap(model(from: try XCTUnwrap(response.scheduledMessages.first)))

        XCTAssertEqual(response.next, "cursor")
        XCTAssertEqual(message.id, "ed08342b")
        XCTAssertEqual(message.cid.rawValue, "messaging:sdk-general")
        XCTAssertEqual(message.message.text, "Reminder")
        XCTAssertEqual(message.message.author.id, "alice")
        XCTAssertEqual(message.channel.name, "General")
        XCTAssertEqual(message.status, .scheduled)
        XCTAssertEqual(message.scheduledAt.timeIntervalSince1970, 1_792_678_087.853949, accuracy: 0.001)
    }

    // MARK: - Update

    func test_reschedule_updatesTheScheduleDate() throws {
        let newDate = Date().addingTimeInterval(7200)
        apiClient.test_mockResponseResult(.success(updateResponse(.dummy(id: "scheduled-id", cid: cid, scheduledAt: newDate))))

        let rescheduled = try waitFor { repository.reschedule(id: "scheduled-id", scheduledAt: newDate, completion: $0) }.get()

        let expectedEndpoint: Endpoint<UpdateScheduledMessageResponse> = .updateScheduledMessage(
            id: "scheduled-id",
            updateScheduledMessageRequest: UpdateScheduledMessageRequest(scheduledAt: newDate)
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertEqual(rescheduled.scheduledAt, newDate)
        XCTAssertEqual(repository.scheduledMessages, [rescheduled])
    }

    func test_update_replacesTheContent() throws {
        apiClient.test_mockResponseResult(.success(updateResponse(.dummy(id: "scheduled-id", cid: cid, message: .dummy(text: "Updated")))))

        let updated = try waitFor {
            repository.update(id: "scheduled-id", content: content(text: "Updated"), scheduledAt: nil, completion: $0)
        }.get()

        let expectedEndpoint: Endpoint<UpdateScheduledMessageResponse> = .updateScheduledMessage(
            id: "scheduled-id",
            updateScheduledMessageRequest: UpdateScheduledMessageRequest(
                message: MessageRequest(attachments: [], custom: [:], mentionedUsers: [], showInChannel: false, text: "Updated"),
                scheduledAt: nil
            )
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertEqual(updated.message.text, "Updated")
        XCTAssertEqual(repository.scheduledMessage(id: "scheduled-id")?.message.text, "Updated")
    }

    func test_update_replacesTheMessageAlreadyInTheList() throws {
        apiClient.test_mockUnmanagedResponseResult(.success(sendMessageResponse(.dummy(id: "scheduled-id", cid: cid, message: .dummy(text: "Hello")))))
        _ = try schedule(id: "scheduled-id").get()
        apiClient.test_mockResponseResult(.success(updateResponse(.dummy(id: "scheduled-id", cid: cid, message: .dummy(text: "Updated")))))

        _ = try waitFor { repository.update(id: "scheduled-id", content: content(text: "Updated"), scheduledAt: nil, completion: $0) }.get()

        XCTAssertEqual(repository.scheduledMessages.map(\.message.text), ["Updated"])
    }

    func test_update_whenTheRequestFails_failsAndKeepsTheList() throws {
        apiClient.test_mockUnmanagedResponseResult(.success(sendMessageResponse(.dummy(id: "scheduled-id", cid: cid))))
        let message = try schedule(id: "scheduled-id").get()
        let error = ClientError(with: APIError(code: 4, message: "Already sent", statusCode: 409))
        apiClient.test_mockResponseResult(Result<UpdateScheduledMessageResponse, Error>.failure(error))

        let result = try waitFor { repository.reschedule(id: message.id, scheduledAt: Date().addingTimeInterval(7200), completion: $0) }

        XCTAssertNotNil(result.error)
        XCTAssertEqual(repository.scheduledMessages, [message])
    }

    // MARK: - Delete

    func test_delete_removesTheMessage() throws {
        apiClient.test_mockUnmanagedResponseResult(.success(sendMessageResponse(.dummy(id: "scheduled-id", cid: cid))))
        _ = try schedule(id: "scheduled-id").get()
        apiClient.test_mockResponseResult(.success(DeleteScheduledMessageResponse(scheduledMessage: .dummy(id: "scheduled-id", cid: cid, status: "canceled"))))

        let error = try waitFor { repository.delete(id: "scheduled-id", completion: $0) }

        let expectedEndpoint: Endpoint<DeleteScheduledMessageResponse> = .deleteScheduledMessage(id: "scheduled-id")
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(error)
        XCTAssertEqual(repository.scheduledMessages, [])
    }

    func test_delete_whenTheRequestFails_failsAndKeepsTheMessage() throws {
        apiClient.test_mockUnmanagedResponseResult(.success(sendMessageResponse(.dummy(id: "scheduled-id", cid: cid))))
        let message = try schedule(id: "scheduled-id").get()
        let error = ClientError(with: APIError(code: 4, message: "This scheduled message no longer exists", statusCode: 404))
        apiClient.test_mockResponseResult(Result<DeleteScheduledMessageResponse, Error>.failure(error))

        let result = try waitFor { repository.delete(id: message.id, completion: $0) }

        XCTAssertNotNil(result)
        XCTAssertEqual(repository.scheduledMessages, [message])
    }

    // MARK: - Send now

    func test_sendNow_updatesTheStatusOfTheMessage() throws {
        apiClient.test_mockUnmanagedResponseResult(.success(sendMessageResponse(.dummy(id: "scheduled-id", cid: cid))))
        _ = try schedule(id: "scheduled-id").get()
        apiClient.test_mockResponseResult(.success(SendScheduledMessageNowResponse(scheduledMessage: .dummy(id: "scheduled-id", cid: cid, status: "sending"))))

        let error = try waitFor { repository.sendNow(id: "scheduled-id", completion: $0) }

        let expectedEndpoint: Endpoint<SendScheduledMessageNowResponse> = .sendScheduledMessageNow(id: "scheduled-id")
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(error)
        XCTAssertEqual(repository.scheduledMessage(id: "scheduled-id")?.status, .sending)
    }

    // MARK: - Load

    func test_load_requestsTheScheduledMessages() throws {
        apiClient.test_mockResponseResult(.success(queryResponse([])))
        let query = ScheduledMessageListQuery(filter: .and([.pending, .equal(.cid, to: cid)]), pageSize: 20, next: "cursor")

        _ = try waitFor { repository.load(query: query, completion: $0) }.get()

        let expectedEndpoint: Endpoint<QueryScheduledMessagesResponse> = .queryScheduledMessages(
            queryScheduledMessagesRequest: QueryScheduledMessagesRequest(
                filter: ScheduledMessagesFilter(cid: cid.rawValue, status: ["scheduled", "sending"]),
                limit: 20,
                next: "cursor"
            )
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_load_withoutFilter_requestsTheWholeList() throws {
        apiClient.test_mockResponseResult(.success(queryResponse([])))

        _ = try waitFor { repository.load(query: .init(), completion: $0) }.get()

        let expectedEndpoint: Endpoint<QueryScheduledMessagesResponse> = .queryScheduledMessages(
            queryScheduledMessagesRequest: QueryScheduledMessagesRequest(filter: nil, limit: 100, next: nil)
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_load_returnsTheMessages_andReplacesTheLocalList() throws {
        apiClient.test_mockUnmanagedResponseResult(.success(sendMessageResponse(.dummy(id: "stale", cid: cid))))
        _ = try schedule(id: "stale").get()
        apiClient.test_mockResponseResult(.success(queryResponse([.dummy(id: "first", cid: cid), .dummy(id: "second", cid: cid)])))

        let page = try waitFor { repository.load(query: .init(), completion: $0) }.get()

        XCTAssertEqual(Set(page.messages.map(\.id)), ["first", "second"])
        XCTAssertNil(page.next)
        XCTAssertEqual(Set(repository.scheduledMessages.map(\.id)), ["first", "second"])
    }

    func test_load_withAnEmptyCursor_hasNoNextPage() throws {
        apiClient.test_mockResponseResult(.success(queryResponse([.dummy(cid: cid)], next: "")))

        let page = try waitFor { repository.load(query: .init(), completion: $0) }.get()

        XCTAssertNil(page.next)
    }

    func test_load_withAFilter_keepsTheOtherMessagesOfTheLocalList() throws {
        apiClient.test_mockUnmanagedResponseResult(.success(sendMessageResponse(.dummy(id: "other", cid: cid))))
        _ = try schedule(id: "other").get()
        apiClient.test_mockResponseResult(.success(queryResponse([.dummy(id: "failed", cid: cid, status: "failed")])))

        let page = try waitFor { repository.load(query: .init(filter: .failed), completion: $0) }.get()

        XCTAssertEqual(page.messages.map(\.id), ["failed"])
        XCTAssertEqual(Set(repository.scheduledMessages.map(\.id)), ["other", "failed"])
    }

    func test_load_withANextPage_keepsTheOtherMessagesOfTheLocalList() throws {
        apiClient.test_mockResponseResult(.success(queryResponse([.dummy(id: "first", cid: cid)], next: "cursor")))
        let firstPage = try waitFor { repository.load(query: .init(pageSize: 1), completion: $0) }.get()
        apiClient.test_mockResponseResult(.success(queryResponse([.dummy(id: "second", cid: cid)])))

        let secondPage = try waitFor { repository.load(query: .init(pageSize: 1, next: firstPage.next), completion: $0) }.get()

        XCTAssertEqual(firstPage.next, "cursor")
        XCTAssertNil(secondPage.next)
        XCTAssertEqual(Set(repository.scheduledMessages.map(\.id)), ["first", "second"])
    }

    func test_load_whenTheRequestFails_fails() throws {
        apiClient.test_mockResponseResult(Result<QueryScheduledMessagesResponse, Error>.failure(ClientError.ConnectionError()))

        let result = try waitFor { repository.load(query: .init(), completion: $0) }

        XCTAssertNotNil(result.error)
    }

    func test_switchingUser_clearsTheList() throws {
        apiClient.test_mockUnmanagedResponseResult(.success(sendMessageResponse(.dummy(id: "scheduled-id", cid: cid))))
        _ = try schedule(id: "scheduled-id").get()
        XCTAssertEqual(repository.scheduledMessages.count, 1)

        client.currentUserId_mock = .unique

        XCTAssertEqual(repository.scheduledMessages, [])
    }

    // MARK: - Events

    func test_events_keepTheListUpToDate() throws {
        let created = try makeMessage(id: "scheduled-id", text: "Hello")
        process(ScheduledMessageCreatedEvent(scheduledMessage: created, createdAt: .unique))
        XCTAssertEqual(repository.scheduledMessages.map(\.message.text), ["Hello"])

        let updated = try makeMessage(id: "scheduled-id", text: "Updated")
        process(ScheduledMessageUpdatedEvent(scheduledMessage: updated, createdAt: .unique))
        XCTAssertEqual(repository.scheduledMessages.map(\.message.text), ["Updated"])

        let failed = try makeMessage(id: "scheduled-id", status: "failed", failureReason: "banned")
        process(ScheduledMessageFailedEvent(scheduledMessage: failed, createdAt: .unique))
        XCTAssertEqual(repository.scheduledMessages.map(\.status), [.failed])
        XCTAssertEqual(repository.scheduledMessages.map(\.failureReason), [.banned])

        process(ScheduledMessageSentEvent(scheduledMessage: failed, messageId: .unique, createdAt: .unique))
        XCTAssertEqual(repository.scheduledMessages, [])
    }

    func test_events_deletedRemovesTheMessage() throws {
        let message = try makeMessage(id: "scheduled-id")
        process(ScheduledMessageCreatedEvent(scheduledMessage: message, createdAt: .unique))
        XCTAssertEqual(repository.scheduledMessages.count, 1)

        process(ScheduledMessageDeletedEvent(scheduledMessage: message, createdAt: .unique))

        XCTAssertEqual(repository.scheduledMessages, [])
    }

    func test_eventDTOs_areConvertedToDomainEvents() throws {
        let response = ScheduledMessageResponse.dummy(id: "scheduled-id", cid: cid)
        let createdAt = Date.unique
        let events: [EventDTO] = [
            ScheduledMessageCreatedEventDTO(createdAt: createdAt, scheduledMessage: response),
            ScheduledMessageUpdatedEventDTO(createdAt: createdAt, scheduledMessage: response),
            ScheduledMessageDeletedEventDTO(createdAt: createdAt, scheduledMessage: response),
            ScheduledMessageSentEventDTO(createdAt: createdAt, messageId: "sent-id", scheduledMessage: response),
            ScheduledMessageFailedEventDTO(createdAt: createdAt, scheduledMessage: response)
        ]

        let domainEvents = try database.readSynchronously { session in
            events.compactMap { $0.toDomainEvent(session: session) }
        }

        XCTAssertEqual(domainEvents.count, 5)
        XCTAssertEqual((domainEvents[0] as? ScheduledMessageCreatedEvent)?.scheduledMessage.id, "scheduled-id")
        XCTAssertEqual((domainEvents[1] as? ScheduledMessageUpdatedEvent)?.scheduledMessage.id, "scheduled-id")
        XCTAssertEqual((domainEvents[2] as? ScheduledMessageDeletedEvent)?.scheduledMessage.id, "scheduled-id")
        XCTAssertEqual((domainEvents[3] as? ScheduledMessageSentEvent)?.scheduledMessage.id, "scheduled-id")
        XCTAssertEqual((domainEvents[3] as? ScheduledMessageSentEvent)?.messageId, "sent-id")
        XCTAssertEqual((domainEvents[4] as? ScheduledMessageFailedEvent)?.scheduledMessage.id, "scheduled-id")
        XCTAssertEqual((domainEvents[0] as? ScheduledMessageCreatedEvent)?.createdAt, createdAt)
    }

    func test_eventDTOs_withoutScheduledMessage_areIgnored() throws {
        let event = ScheduledMessageCreatedEventDTO(createdAt: .unique, scheduledMessage: nil)

        let domainEvent = try database.readSynchronously { session in
            event.toDomainEvent(session: session)
        }

        XCTAssertNil(domainEvent)
    }

    // MARK: - Query

    func test_query_sortsPendingMessagesFirst_thenByScheduledAt() throws {
        let later = try makeMessage(scheduledAt: Date().addingTimeInterval(200))
        let failed = try makeMessage(scheduledAt: Date().addingTimeInterval(50), status: "failed")
        let sooner = try makeMessage(scheduledAt: Date().addingTimeInterval(100))

        let sorted = ScheduledMessageListQuery().sorted([later, failed, sooner])

        XCTAssertEqual(sorted.map(\.id), [sooner.id, later.id, failed.id])
    }

    func test_query_sortsBySortingKeys() throws {
        let first = try makeMessage(scheduledAt: Date().addingTimeInterval(100))
        let second = try makeMessage(scheduledAt: Date().addingTimeInterval(200))

        let sorted = ScheduledMessageListQuery(sort: [.init(key: .scheduledAt, isAscending: false)]).sorted([first, second])

        XCTAssertEqual(sorted.map(\.id), [second.id, first.id])
    }

    func test_query_filtersByStatusAndChannel() throws {
        let otherCid = ChannelId.unique
        let pending = try makeMessage()
        let failed = try makeMessage(status: "failed")
        let sending = try makeMessage(status: "sending")
        let otherChannel = try makeMessage(cid: otherCid)
        let messages = [pending, failed, sending, otherChannel]

        let pendingQuery = ScheduledMessageListQuery(filter: .and([.pending, .equal(.cid, to: cid)]))
        let failedQuery = ScheduledMessageListQuery(filter: .failed)
        let channelsQuery = ScheduledMessageListQuery(filter: .in(.cid, values: [otherCid]))

        XCTAssertEqual(messages.filter(pendingQuery.matches).map(\.id), [pending.id, sending.id])
        XCTAssertEqual(messages.filter(failedQuery.matches).map(\.id), [failed.id])
        XCTAssertEqual(messages.filter(channelsQuery.matches).map(\.id), [otherChannel.id])
    }

    // MARK: - Helpers

    private func content(text: String = "Hello") -> ScheduledMessageContent {
        ScheduledMessageContent(
            text: text,
            attachments: [],
            mentionedUserIds: [],
            quotedMessageId: nil,
            parentId: nil,
            showReplyInChannel: false,
            extraData: [:]
        )
    }

    private func schedule(
        id: String = .unique,
        scheduledAt: Date = Date().addingTimeInterval(3600)
    ) -> Result<ScheduledMessage, Error> {
        do {
            return try waitFor {
                repository.schedule(id: id, cid: cid, content: content(), scheduledAt: scheduledAt, completion: $0)
            }
        } catch {
            return .failure(error)
        }
    }

    private func sendMessageResponse(_ scheduledMessage: ScheduledMessageResponse?) -> SendMessageResponsePayload {
        SendMessageResponsePayload(message: .dummy(cid: cid), scheduledMessage: scheduledMessage)
    }

    private func updateResponse(_ scheduledMessage: ScheduledMessageResponse) -> UpdateScheduledMessageResponse {
        UpdateScheduledMessageResponse(scheduledMessage: scheduledMessage)
    }

    private func queryResponse(_ messages: [ScheduledMessageResponse], next: String? = nil) -> QueryScheduledMessagesResponse {
        QueryScheduledMessagesResponse(next: next, scheduledMessages: messages)
    }

    private func model(from response: ScheduledMessageResponse) -> ScheduledMessage? {
        try? database.readSynchronously { session in
            response.asModel(session: session)
        }
    }

    private func makeMessage(
        id: String = .unique,
        cid: ChannelId? = nil,
        text: String = "Hello",
        scheduledAt: Date = Date().addingTimeInterval(3600),
        status: String = "scheduled",
        failureReason: String? = nil
    ) throws -> ScheduledMessage {
        let response = ScheduledMessageResponse.dummy(
            id: id,
            cid: cid ?? self.cid,
            message: .dummy(text: text),
            scheduledAt: scheduledAt,
            status: status,
            failureReason: failureReason
        )
        return try XCTUnwrap(model(from: response))
    }

    private func process(_ event: Event) {
        let processed = expectation(description: "event processed")
        client.eventNotificationCenter.process([event]) {
            processed.fulfill()
        }
        wait(for: [processed], timeout: defaultTimeout)
    }
}

extension ScheduledMessageResponse {
    static func dummy(
        id: String = .unique,
        cid: ChannelId = .unique,
        rawCid: String? = nil,
        channel: ScheduledMessageChannelResponse? = nil,
        user: UserPayload = .dummy(userId: .unique),
        message: ScheduledMessageContentResponse = .dummy(),
        scheduledAt: Date = Date().addingTimeInterval(3600),
        status: String = "scheduled",
        failureReason: String? = nil
    ) -> ScheduledMessageResponse {
        .init(
            channel: channel,
            cid: rawCid ?? cid.rawValue,
            createdAt: Date(),
            failureReason: failureReason,
            id: id,
            message: message,
            scheduledAt: scheduledAt,
            status: status,
            updatedAt: Date(),
            user: user
        )
    }
}

extension ScheduledMessageContentResponse {
    static func dummy(
        text: String = "Hello",
        attachments: [MessageAttachmentPayload]? = nil,
        custom: [String: RawJSON] = [:],
        mentionedUsers: [String]? = nil,
        parentId: String? = nil,
        quotedMessageId: String? = nil,
        showInChannel: Bool? = nil
    ) -> ScheduledMessageContentResponse {
        .init(
            attachments: attachments,
            custom: custom,
            mentionedUsers: mentionedUsers,
            parentId: parentId,
            quotedMessageId: quotedMessageId,
            showInChannel: showInChannel,
            text: text
        )
    }
}
