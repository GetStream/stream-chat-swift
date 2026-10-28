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
        try? database.createCurrentUser(id: userId)
        repository = ScheduledMessagesRepository(database: database, apiClient: apiClient)
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

    func test_schedule_savesTheMessageLocally_withoutSendingIt() throws {
        let scheduledAt = Date().addingTimeInterval(3600)

        let message = try schedule(id: "scheduled-id", content: content(text: "Hello", parentId: "parent"), scheduledAt: scheduledAt).get()

        XCTAssertEqual(message.id, "scheduled-id")
        XCTAssertEqual(message.cid, cid)
        XCTAssertEqual(message.message.localState, .pendingSend)
        XCTAssertEqual(message.status, .preparingToSchedule)
        XCTAssertEqual(message.scheduledAt.timeIntervalSince1970, scheduledAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(message.message.text, "Hello")
        XCTAssertEqual(message.message.parentMessageId, "parent")
        XCTAssertEqual(message.message.author.id, userId)
        XCTAssertEqual(try storedMessages(), [message])
        XCTAssertNil(apiClient.request_endpoint)
        XCTAssertNil(apiClient.request_endpoint)
    }

    func test_schedule_withoutCurrentUser_fails() throws {
        try database.writeSynchronously { session in
            session.deleteCurrentUser()
        }

        XCTAssertNotNil(schedule().error)
        XCTAssertEqual(try storedMessages(), [])
    }

    func test_scheduledContent_isNotSentByTheMessageSender() throws {
        _ = try schedule(id: "scheduled-id").get()

        let pendingSend = try database.readSynchronously { session in
            try (session as? NSManagedObjectContext)?.fetch(MessageDTO.messagesPendingSendFetchRequest()).map(\.id) ?? []
        }

        XCTAssertEqual(pendingSend, [])
    }

    // MARK: - Sending to the server

    func test_sendPendingChanges_schedulesTheMessageOnTheServer() throws {
        let content = ScheduledMessageContent(
            text: "Hi @mentioned",
            attachments: [],
            mentionedUserIds: ["mentioned"],
            quotedMessageId: nil,
            parentId: "parent",
            showReplyInChannel: true,
            extraData: ["key": .string("value")]
        )
        _ = try schedule(id: "scheduled-id", content: content).get()
        apiClient.test_mockResponseResult(.success(sendMessageResponse(.dummy(id: "scheduled-id", cid: cid, user: .dummy(userId: userId)))))

        let sent = try XCTUnwrap(waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }.get())

        let endpoint = try XCTUnwrap(apiClient.request_endpoint)
        let body = try endpoint.bodyAsDictionary()
        let message = try XCTUnwrap(body["message"] as? [String: Any])
        XCTAssertEqual(endpoint.path, .sendMessage(type: cid.type.rawValue, id: cid.id))
        XCTAssertNotNil(body["scheduled_at"])
        XCTAssertEqual(message["id"] as? String, "scheduled-id")
        XCTAssertEqual(message["text"] as? String, "Hi @mentioned")
        XCTAssertEqual(message["parent_id"] as? String, "parent")
        XCTAssertEqual(message["show_in_channel"] as? Bool, true)
        XCTAssertEqual(message["mentioned_users"] as? [String], ["mentioned"])
        XCTAssertEqual((message["custom"] as? [String: Any])?["key"] as? String, "value")
        XCTAssertNil(sent.message.localState)
        XCTAssertEqual(sent.status, .scheduled)
        XCTAssertNil(try storedMessage(id: "scheduled-id")?.message.localState)
    }

    func test_sendPendingChanges_whenTheRequestFails_marksTheMessageFailed() throws {
        _ = try schedule(id: "scheduled-id").get()
        let error = ClientError(with: APIError(code: 4, message: "Pick a time at least 1 minute from now", statusCode: 400))
        apiClient.test_mockResponseResult(Result<SendMessageResponsePayload, Error>.failure(error))

        let result = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }

        XCTAssertNotNil(result.error)
        XCTAssertEqual(try storedMessage(id: "scheduled-id")?.message.localState, .sendingFailed)
    }

    func test_sendPendingChanges_whenTheLimitIsReached_keepsTheErrorOfTheServer() throws {
        _ = try schedule(id: "scheduled-id").get()
        let apiError = APIError(code: 117, message: "SendMessage failed with error: \"you can schedule at most 2 messages in this channel\"", statusCode: 400)
        apiError.exceptionFields = ["reason": "scheduled_limit_channel"]
        apiClient.test_mockResponseResult(Result<SendMessageResponsePayload, Error>.failure(ClientError(with: apiError)))

        _ = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }

        let message = try XCTUnwrap(storedMessage(id: "scheduled-id"))
        XCTAssertEqual(message.message.localState, .sendingFailed)
        XCTAssertEqual(message.status, .failed)
        guard case let .serverRejectedScheduling(rejection) = message.failure else {
            return XCTFail("Expected a rejection of the server, got \(String(describing: message.failure))")
        }
        XCTAssertEqual(rejection.reason, .scheduledLimitChannel)
        XCTAssertEqual(rejection.message, apiError.message)
        XCTAssertEqual(rejection.isRetryable, false)
        XCTAssertEqual(message.failure?.isRetryable, false)
    }

    func test_sendPendingChanges_whenTheServerRejectsWithoutAReason_isNotRetryable() throws {
        _ = try schedule(id: "scheduled-id").get()
        let apiError = APIError(code: 4, message: "SendMessage failed with error: \"slash commands cannot be scheduled\"", statusCode: 400)
        apiClient.test_mockResponseResult(Result<SendMessageResponsePayload, Error>.failure(ClientError(with: apiError)))

        _ = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }

        let message = try XCTUnwrap(storedMessage(id: "scheduled-id"))
        guard case let .serverRejectedScheduling(rejection) = message.failure else {
            return XCTFail("Expected a rejection of the server, got \(String(describing: message.failure))")
        }
        XCTAssertNil(rejection.reason)
        XCTAssertEqual(message.failure?.isRetryable, false)
    }

    func test_sendPendingChanges_whenTheServerFails_isUnavailableAndRetryable() throws {
        _ = try schedule(id: "scheduled-id").get()
        let apiError = APIError(code: -1, message: "Internal error", statusCode: 503)
        apiClient.test_mockResponseResult(Result<SendMessageResponsePayload, Error>.failure(ClientError(with: apiError)))

        _ = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }

        let message = try XCTUnwrap(storedMessage(id: "scheduled-id"))
        guard case let .serverRejectedScheduling(rejection) = message.failure else {
            return XCTFail("Expected a rejection of the server, got \(String(describing: message.failure))")
        }
        XCTAssertEqual(rejection.reason, .serverUnavailable)
        XCTAssertEqual(message.failure?.isRetryable, true)
    }

    func test_sendPendingChanges_whenRateLimited_isRetryable() throws {
        _ = try schedule(id: "scheduled-id").get()
        let apiError = APIError(code: 9, message: "Too many requests", statusCode: 429)
        apiClient.test_mockResponseResult(Result<SendMessageResponsePayload, Error>.failure(ClientError(with: apiError)))

        _ = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }

        let message = try XCTUnwrap(storedMessage(id: "scheduled-id"))
        guard case let .serverRejectedScheduling(rejection) = message.failure else {
            return XCTFail("Expected a rejection of the server, got \(String(describing: message.failure))")
        }
        XCTAssertEqual(rejection.reason, .rateLimited)
        XCTAssertEqual(message.failure?.isRetryable, true)
    }

    func test_serverRejection_isRetryableOnlyForAKnownTemporaryReason() {
        let retryable: [ScheduledMessageFailure.ServerRejection.Reason?] = [
            .serverUnavailable, .rateLimited, .scheduledMessageConflict
        ]
        let notRetryable: [ScheduledMessageFailure.ServerRejection.Reason?] = [
            nil, "unknown_reason", .scheduledMessageSending, .scheduledLimitChannel, .scheduledAtTooSoon
        ]

        for reason in retryable {
            XCTAssertTrue(ScheduledMessageFailure.ServerRejection(reason: reason, message: "").isRetryable, "\(String(describing: reason))")
        }
        for reason in notRetryable {
            XCTAssertFalse(ScheduledMessageFailure.ServerRejection(reason: reason, message: "").isRetryable, "\(String(describing: reason))")
        }
    }

    func test_sendPendingChanges_whenTheRequestFailsWithoutAResponse_isAFailureOfTheLocalDevice() throws {
        _ = try schedule(id: "scheduled-id").get()
        apiClient.test_mockResponseResult(Result<SendMessageResponsePayload, Error>.failure(ClientError("Encoding failed")))

        _ = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }

        let message = try XCTUnwrap(storedMessage(id: "scheduled-id"))
        XCTAssertEqual(message.status, .failed)
        XCTAssertEqual(message.failure, .localDeviceFailedScheduling(.init(reason: .requestFailed, message: ClientError("Encoding failed").localizedDescription)))
        XCTAssertEqual(message.failure?.isRetryable, true)
    }

    func test_asModel_whenAnAttachmentFailedToUpload_isAFailureOfTheLocalDevice() throws {
        _ = try schedule(
            id: "scheduled-id",
            content: ScheduledMessageContent(
                text: "Photo",
                attachments: [.mockImage],
                mentionedUserIds: [],
                quotedMessageId: nil,
                parentId: nil,
                showReplyInChannel: false,
                extraData: [:]
            )
        ).get()

        try database.writeSynchronously { session in
            let message = try XCTUnwrap(session.scheduledMessage(id: "scheduled-id")?.message)
            message.attachments.forEach { $0.localState = .uploadingFailed }
            message.localMessageState = .sendingFailed
        }

        XCTAssertEqual(try storedMessage(id: "scheduled-id")?.failure, .localDeviceFailedScheduling(.init(reason: .attachmentUploadFailed)))
    }

    func test_asModel_whenAnEditIsRejectedAfterThePublishingFailed_reportsTheRejection() throws {
        try saveOnServer(id: "scheduled-id")
        try database.writeSynchronously { session in
            try session.saveScheduledMessage(payload: .dummy(
                id: "scheduled-id",
                cid: self.cid,
                user: .dummy(userId: self.userId),
                status: .failed,
                failureReason: .banned
            ))
            let dto = try XCTUnwrap(session.scheduledMessage(id: "scheduled-id"))
            dto.message?.localMessageState = .syncingFailed
            dto.syncErrorReason = "scheduled_message_not_editable"
            dto.syncErrorMessage = "Failed messages can't be edited"
        }
        XCTAssertEqual(
            try storedMessage(id: "scheduled-id")?.failure,
            .serverRejectedScheduling(.init(reason: .scheduledMessageNotEditable, message: "Failed messages can't be edited"))
        )

        try database.writeSynchronously { session in
            session.scheduledMessage(id: "scheduled-id")?.message?.localMessageState = nil
        }
        XCTAssertEqual(try storedMessage(id: "scheduled-id")?.failure, .serverFailedPublishing(.init(reason: .banned)))
    }

    func test_sendPendingChanges_withoutConnection_keepsNoError() throws {
        _ = try schedule(id: "scheduled-id").get()
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        apiClient.test_mockResponseResult(Result<SendMessageResponsePayload, Error>.failure(error))

        _ = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }

        XCTAssertNil(try storedMessage(id: "scheduled-id")?.failure)
    }

    func test_sendPendingChanges_whenTheServerSendsItRightAway_savesTheMessageInTheChannel() throws {
        try database.createChannel(cid: cid)
        _ = try schedule(id: "scheduled-id", content: content(text: "Hello")).get()
        apiClient.test_mockResponseResult(.success(SendMessageResponsePayload(
            message: .dummy(messageId: "scheduled-id", authorUserId: userId, text: "Hello", cid: cid),
            scheduledMessage: nil
        )))

        let result = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }

        XCTAssertNil(try result.get())
        XCTAssertEqual(try storedMessages(), [])
        let sentMessage = try database.readSynchronously { session in
            try session.message(id: "scheduled-id")?.asModel()
        }
        XCTAssertEqual(sentMessage?.cid, cid)
        XCTAssertEqual(sentMessage?.text, "Hello")
        XCTAssertNil(sentMessage?.localState)
    }

    func test_sendPendingChanges_whenItWasAlreadySent_removesIt() throws {
        try assertSendPendingChangesRemovesTheMessage(code: 123, reason: "scheduled_message_already_sent")
    }

    func test_sendPendingChanges_whenItWasCanceled_removesIt() throws {
        try assertSendPendingChangesRemovesTheMessage(code: 124, reason: "scheduled_message_canceled")
    }

    private func assertSendPendingChangesRemovesTheMessage(code: Int, reason: String) throws {
        _ = try schedule(id: "scheduled-id").get()
        let apiError = APIError(code: code, message: reason, statusCode: 400)
        apiError.exceptionFields = ["reason": reason]
        apiClient.test_mockResponseResult(Result<SendMessageResponsePayload, Error>.failure(ClientError(with: apiError)))

        let result = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }

        XCTAssertNil(try result.get())
        XCTAssertEqual(try storedMessages(), [])
        XCTAssertNil(try database.readSynchronously { $0.message(id: "scheduled-id")?.id })
    }

    func test_schedule_whenTheTextIsACommandInAChannelWithCommands_failsWithoutSavingTheMessage() throws {
        try saveChannel(commands: [.init(name: "giphy", description: "", set: "", args: "")])

        let result = schedule(id: "scheduled-id", content: content(text: "/giphy hello"))

        XCTAssertTrue(result.error is ClientError.ScheduledMessageHasACommand, "\(String(describing: result.error))")
        XCTAssertNil(try storedMessage(id: "scheduled-id"))
    }

    func test_schedule_whenTheChannelHasNoCommands_savesATextStartingWithASlash() throws {
        try saveChannel(commands: [])

        let result = schedule(id: "scheduled-id", content: content(text: "/giphy hello"))

        XCTAssertEqual(try result.get().message.text, "/giphy hello")
    }

    func test_update_whenTheTextIsACommandInAChannelWithCommands_failsAndKeepsTheContent() throws {
        try saveChannel(commands: [.init(name: "giphy", description: "", set: "", args: "")])
        _ = try schedule(id: "scheduled-id").get()

        let result = try waitFor {
            repository.update(id: "scheduled-id", content: content(text: "/giphy hello"), scheduledAt: nil, completion: $0)
        }

        XCTAssertTrue(result.error is ClientError.ScheduledMessageHasACommand, "\(String(describing: result.error))")
        XCTAssertEqual(try storedMessage(id: "scheduled-id")?.message.text, "Hello")
    }

    func test_schedule_whenTheQuotedMessageIsDeleted_failsWithoutSavingTheMessage() throws {
        try saveMessage(id: "quoted-id")
        try deleteMessage(id: "quoted-id")

        let result = schedule(id: "scheduled-id", content: content(quotedMessageId: "quoted-id"))

        XCTAssertTrue(result.error is ClientError.ScheduledMessageQuotesADeletedMessage, "\(String(describing: result.error))")
        XCTAssertNil(try storedMessage(id: "scheduled-id"))
    }

    func test_update_whenTheQuotedMessageIsDeleted_failsAndKeepsTheContent() throws {
        try saveMessage(id: "quoted-id")
        _ = try schedule(id: "scheduled-id", content: content(quotedMessageId: "quoted-id")).get()
        try deleteMessage(id: "quoted-id")

        let result = try waitFor {
            repository.update(
                id: "scheduled-id",
                content: content(text: "Edited", quotedMessageId: "quoted-id"),
                scheduledAt: nil,
                completion: $0
            )
        }

        XCTAssertTrue(result.error is ClientError.ScheduledMessageQuotesADeletedMessage, "\(String(describing: result.error))")
        XCTAssertEqual(try storedMessage(id: "scheduled-id")?.message.text, "Hello")
    }

    func test_reschedule_whenTheQuotedMessageIsDeleted_fails() throws {
        try saveMessage(id: "quoted-id")
        let scheduledAt = Date().addingTimeInterval(3600)
        _ = try schedule(id: "scheduled-id", content: content(quotedMessageId: "quoted-id"), scheduledAt: scheduledAt).get()
        try deleteMessage(id: "quoted-id")

        let result = try waitFor {
            repository.reschedule(id: "scheduled-id", scheduledAt: Date().addingTimeInterval(7200), completion: $0)
        }

        XCTAssertTrue(result.error is ClientError.ScheduledMessageQuotesADeletedMessage, "\(String(describing: result.error))")
        let stored = try XCTUnwrap(storedMessage(id: "scheduled-id"))
        XCTAssertEqual(stored.scheduledAt.timeIntervalSince1970, scheduledAt.timeIntervalSince1970, accuracy: 0.001)
    }

    func test_sendNow_whenTheQuotedMessageIsDeleted_failsWithoutARequest() throws {
        try saveMessage(id: "quoted-id")
        _ = try schedule(id: "scheduled-id", content: content(quotedMessageId: "quoted-id")).get()
        try deleteMessage(id: "quoted-id")

        let error = try waitFor { repository.sendNow(id: "scheduled-id", completion: $0) }

        XCTAssertTrue(error is ClientError.ScheduledMessageQuotesADeletedMessage, "\(String(describing: error))")
        XCTAssertNil(apiClient.request_endpoint)
    }

    func test_schedule_whenTheQuotedMessageIsNotDeleted_savesTheMessage() throws {
        try saveMessage(id: "quoted-id")

        let result = schedule(id: "scheduled-id", content: content(quotedMessageId: "quoted-id"))

        XCTAssertEqual(try result.get().quotedMessageId, "quoted-id")
    }

    func test_resend_clearsTheError() throws {
        _ = try schedule(id: "scheduled-id").get()
        apiClient.test_mockResponseResult(Result<SendMessageResponsePayload, Error>.failure(
            ClientError(with: APIError(code: 4, message: "Failed", statusCode: 400))
        ))
        _ = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }
        XCTAssertNotNil(try storedMessage(id: "scheduled-id")?.failure)

        _ = try waitFor { repository.resend(id: "scheduled-id", completion: $0) }

        XCTAssertNil(try storedMessage(id: "scheduled-id")?.failure)
    }

    func test_reschedule_clearsTheError() throws {
        _ = try schedule(id: "scheduled-id").get()
        let apiError = APIError(code: 115, message: "scheduled_at must be at least 1 minute from now", statusCode: 400)
        apiError.exceptionFields = ["reason": "scheduled_at_too_soon"]
        apiClient.test_mockResponseResult(Result<SendMessageResponsePayload, Error>.failure(ClientError(with: apiError)))
        _ = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }

        let rescheduled = try waitFor {
            repository.reschedule(id: "scheduled-id", scheduledAt: Date().addingTimeInterval(7200), completion: $0)
        }.get()

        XCTAssertNil(rescheduled.failure)
        XCTAssertEqual(rescheduled.message.localState, .pendingSend)
    }

    func test_sendPendingChanges_withoutConnection_keepsTheMessagePending() throws {
        _ = try schedule(id: "scheduled-id").get()
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        apiClient.test_mockResponseResult(Result<SendMessageResponsePayload, Error>.failure(error))

        let result = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }

        XCTAssertNotNil(result.error)
        XCTAssertEqual(try storedMessage(id: "scheduled-id")?.message.localState, .pendingSend)
    }

    func test_sendPendingChanges_whenDeletedWhileScheduling_deletesItOnTheServer() throws {
        _ = try schedule(id: "scheduled-id").get()
        apiClient.test_mockResponseResult(.success(DeleteScheduledMessageResponse(scheduledMessage: .dummy(id: "scheduled-id", cid: cid, status: .canceled))))
        let sendCompleted = expectation(description: "sendPendingChanges completes")
        nonisolated(unsafe) var result: Result<ScheduledMessage?, Error>?
        repository.sendPendingChanges(id: "scheduled-id") {
            result = $0
            sendCompleted.fulfill()
        }
        wait(until: { [self] in apiClient.request_endpoint?.path == .sendMessage(type: cid.type.rawValue, id: cid.id) })

        XCTAssertNil(try waitFor { repository.delete(id: "scheduled-id", completion: $0) })
        apiClient.test_simulateResponse(.success(sendMessageResponse(.dummy(id: "scheduled-id", cid: cid, user: .dummy(userId: userId)))))
        wait(for: [sendCompleted], timeout: defaultTimeout)

        let expectedEndpoint: Endpoint<DeleteScheduledMessageResponse> = .deleteScheduledMessage(id: "scheduled-id")
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(try XCTUnwrap(result).get())
        XCTAssertEqual(try storedMessages(), [])
    }

    func test_sendPendingChanges_withoutScheduledMessageInTheResponse_fails() throws {
        _ = try schedule(id: "scheduled-id").get()
        apiClient.test_mockResponseResult(.success(sendMessageResponse(nil)))

        let result = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }

        XCTAssertNotNil(result.error)
    }

    func test_sendPendingChanges_withoutPendingChanges_fails() throws {
        try saveOnServer(id: "scheduled-id")

        let result = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }

        XCTAssertTrue(result.error is ClientError.ScheduledMessageHasNoPendingChanges)
        XCTAssertNil(apiClient.request_endpoint)
    }

    func test_resend_marksTheFailedMessagePendingAgain() throws {
        _ = try schedule(id: "scheduled-id").get()
        apiClient.test_mockResponseResult(Result<SendMessageResponsePayload, Error>.failure(
            ClientError(with: APIError(code: 4, message: "Failed", statusCode: 400))
        ))
        _ = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }

        let result = try waitFor { repository.resend(id: "scheduled-id", completion: $0) }

        XCTAssertNil(result.error)
        XCTAssertEqual(try storedMessage(id: "scheduled-id")?.message.localState, .pendingSend)
    }

    func test_saveScheduledMessage_keepsTheLocalChangesNotOnTheServerYet() throws {
        _ = try schedule(id: "scheduled-id", content: content(text: "Local")).get()

        _ = model(from: .dummy(id: "scheduled-id", cid: cid, user: .dummy(userId: userId), message: .dummy(text: "Server")))

        XCTAssertEqual(try storedMessage(id: "scheduled-id")?.message.text, "Local")
        XCTAssertEqual(try storedMessage(id: "scheduled-id")?.message.localState, .pendingSend)
    }

    func test_saveScheduledMessage_keepsTheFailedLocalChanges() throws {
        try saveOnServer(id: "scheduled-id")
        _ = try waitFor { repository.update(id: "scheduled-id", content: content(text: "Local"), scheduledAt: nil, completion: $0) }.get()
        try database.writeSynchronously { session in
            let dto = try XCTUnwrap(session.scheduledMessage(id: "scheduled-id"))
            dto.message?.localMessageState = .syncingFailed
            dto.syncErrorReason = "scheduled_message_not_editable"
        }

        _ = model(from: .dummy(id: "scheduled-id", cid: cid, user: .dummy(userId: userId), message: .dummy(text: "Server")))

        let stored = try XCTUnwrap(storedMessage(id: "scheduled-id"))
        XCTAssertEqual(stored.message.text, "Local")
        XCTAssertEqual(stored.message.localState, .syncingFailed)
        XCTAssertNotNil(stored.failure)
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
        XCTAssertEqual(message.message.createdAt.timeIntervalSince1970, scheduledAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(message.message.type, .reply)
        XCTAssertEqual(message.message.parentMessageId, "parent")
        XCTAssertTrue(message.message.showReplyInChannel)
        // Mentioned users are only resolved when they are in the database.
        XCTAssertEqual(message.message.mentionedUsers.map(\.id), [])
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

    func test_asModel_exposesTheMentionsAndPin() throws {
        let scheduledAt = Date().addingTimeInterval(3600)
        let pinExpires = Date().addingTimeInterval(7200)
        let response = ScheduledMessageResponse.dummy(
            cid: cid,
            user: .dummy(userId: userId),
            message: .dummy(
                mentionedChannel: true,
                mentionedHere: true,
                mentionedRoles: ["admin"],
                pinExpires: pinExpires,
                pinned: true
            ),
            scheduledAt: scheduledAt
        )

        let message = try XCTUnwrap(model(from: response)).message

        XCTAssertTrue(message.mentionedChannel)
        XCTAssertTrue(message.mentionedHere)
        XCTAssertEqual(message.mentionedRoles, ["admin"])
        XCTAssertEqual(try XCTUnwrap(message.pinDetails?.pinnedAt).timeIntervalSince1970, scheduledAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(message.pinDetails?.pinnedBy.id, userId)
        XCTAssertEqual(try XCTUnwrap(message.pinDetails?.expiresAt).timeIntervalSince1970, pinExpires.timeIntervalSince1970, accuracy: 0.001)
    }

    func test_asModel_withoutPin_exposesNone() throws {
        let message = try XCTUnwrap(model(from: .dummy(cid: cid))).message

        XCTAssertNil(message.pinDetails)
        XCTAssertNil(message.poll)
        XCTAssertFalse(message.mentionedChannel)
        XCTAssertFalse(message.mentionedHere)
        XCTAssertEqual(message.mentionedRoles, [])
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

    func test_status_mergesTheLocalChangesWithTheStatusOfTheServer() {
        let cases: [(LocalMessageState?, String, ScheduledMessageStatus)] = [
            (.pendingSend, "scheduled", .preparingToSchedule),
            (.pendingSync, "failed", .preparingToSchedule),
            (.sending, "scheduled", .preparingToSchedule),
            (.syncing, "sending", .preparingToSchedule),
            (.sendingFailed, "scheduled", .failed),
            (.syncingFailed, "scheduled", .failed),
            (nil, "scheduled", .scheduled),
            (nil, "sending", .sending),
            (nil, "failed", .failed)
        ]
        for (localState, serverStatus, expected) in cases {
            XCTAssertEqual(ScheduledMessageStatus(localState: localState, serverStatus: serverStatus), expected, "\(String(describing: localState)), \(serverStatus)")
        }
    }

    func test_asModel_exposesTheStatusAndTheFailureReason() throws {
        let response = ScheduledMessageResponse.dummy(cid: cid, status: .failed, failureReason: .channelFrozen)

        let message = try XCTUnwrap(model(from: response))

        XCTAssertEqual(message.status, .failed)
        XCTAssertEqual(message.failure, .serverFailedPublishing(.init(reason: .channelFrozen)))
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

    func test_update_ofAMessageOnTheServer_syncsTheNewContent() throws {
        try saveOnServer(id: "scheduled-id")

        let updated = try waitFor {
            repository.update(id: "scheduled-id", content: content(text: "Updated"), scheduledAt: nil, completion: $0)
        }.get()

        XCTAssertEqual(updated.message.text, "Updated")
        XCTAssertEqual(updated.message.localState, .pendingSync)

        apiClient.test_mockResponseResult(.success(updateResponse(
            .dummy(id: "scheduled-id", cid: cid, user: .dummy(userId: userId), message: .dummy(text: "Updated"))
        )))
        let synced = try XCTUnwrap(waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }.get())

        let endpoint = try XCTUnwrap(apiClient.request_endpoint)
        let body = try endpoint.bodyAsDictionary()
        XCTAssertEqual(endpoint.path.value, EndpointPath.updateScheduledMessage(id: "scheduled-id").value)
        XCTAssertEqual((body["message"] as? [String: Any])?["text"] as? String, "Updated")
        XCTAssertNil(body["scheduled_at"])
        XCTAssertNil(synced.message.localState)
        XCTAssertEqual(try storedMessage(id: "scheduled-id")?.message.text, "Updated")
    }

    func test_update_whenTheSyncFails_marksTheChangesFailed() throws {
        try saveOnServer(id: "scheduled-id")
        _ = try waitFor { repository.update(id: "scheduled-id", content: content(text: "Updated"), scheduledAt: nil, completion: $0) }.get()
        let error = ClientError(with: APIError(code: 4, message: "Already sent", statusCode: 409))
        apiClient.test_mockResponseResult(Result<UpdateScheduledMessageResponse, Error>.failure(error))

        let result = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }

        XCTAssertNotNil(result.error)
        XCTAssertEqual(try storedMessage(id: "scheduled-id")?.message.localState, .syncingFailed)
        XCTAssertEqual(try storedMessage(id: "scheduled-id")?.message.text, "Updated")
    }

    func test_update_ofAMessageNotOnTheServerYet_staysPendingSend() throws {
        _ = try schedule(id: "scheduled-id").get()

        let updated = try waitFor {
            repository.update(id: "scheduled-id", content: content(text: "Updated"), scheduledAt: nil, completion: $0)
        }.get()

        XCTAssertEqual(updated.message.localState, .pendingSend)
        XCTAssertEqual(updated.message.text, "Updated")
    }

    func test_update_withoutThread_keepsTheThreadOfTheMessage() throws {
        _ = try schedule(id: "scheduled-id", content: content(parentId: "parent")).get()

        let updated = try waitFor {
            repository.update(id: "scheduled-id", content: content(text: "Updated"), scheduledAt: nil, completion: $0)
        }.get()

        XCTAssertEqual(updated.message.parentMessageId, "parent")
    }

    func test_update_ofAMissingMessage_fails() throws {
        let result = try waitFor {
            repository.update(id: "missing", content: content(), scheduledAt: nil, completion: $0)
        }

        XCTAssertTrue(result.error is ClientError.ScheduledMessageDoesNotExist)
    }

    func test_reschedule_ofAMessageOnTheServer_syncsTheNewDate() throws {
        try saveOnServer(id: "scheduled-id")
        let newDate = Date().addingTimeInterval(7200)

        let rescheduled = try waitFor { repository.reschedule(id: "scheduled-id", scheduledAt: newDate, completion: $0) }.get()

        XCTAssertEqual(rescheduled.scheduledAt.timeIntervalSince1970, newDate.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(rescheduled.message.localState, .pendingSync)

        apiClient.test_mockResponseResult(.success(updateResponse(
            .dummy(id: "scheduled-id", cid: cid, user: .dummy(userId: userId), scheduledAt: newDate)
        )))
        _ = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }.get()

        let body = try XCTUnwrap(apiClient.request_endpoint).bodyAsDictionary()
        XCTAssertNotNil(body["scheduled_at"])
    }

    // MARK: - Delete

    func test_delete_ofAMessageNotOnTheServerYet_onlyDeletesItLocally() throws {
        _ = try schedule(id: "scheduled-id").get()

        let error = try waitFor { repository.delete(id: "scheduled-id", completion: $0) }

        XCTAssertNil(error)
        XCTAssertNil(apiClient.request_endpoint)
        XCTAssertEqual(try storedMessages(), [])
        XCTAssertNil(database.viewContext.message(id: "scheduled-id"))
    }

    func test_delete_ofAMessageOnTheServer_deletesItOnTheServer() throws {
        try saveOnServer(id: "scheduled-id")
        apiClient.test_mockResponseResult(.success(DeleteScheduledMessageResponse(scheduledMessage: .dummy(id: "scheduled-id", cid: cid, status: .canceled))))

        let error = try waitFor { repository.delete(id: "scheduled-id", completion: $0) }

        let expectedEndpoint: Endpoint<DeleteScheduledMessageResponse> = .deleteScheduledMessage(id: "scheduled-id")
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(error)
        XCTAssertEqual(try storedMessages(), [])
    }

    func test_delete_whenTheRequestFails_failsAndKeepsTheMessage() throws {
        try saveOnServer(id: "scheduled-id")
        let message = try XCTUnwrap(storedMessage(id: "scheduled-id"))
        let error = ClientError(with: APIError(code: 4, message: "This scheduled message no longer exists", statusCode: 404))
        apiClient.test_mockResponseResult(Result<DeleteScheduledMessageResponse, Error>.failure(error))

        let result = try waitFor { repository.delete(id: message.id, completion: $0) }

        XCTAssertNotNil(result)
        XCTAssertEqual(try storedMessages(), [message])
    }

    // MARK: - Send now

    func test_sendNow_marksTheMessageWithoutARequest() throws {
        try saveOnServer(id: "scheduled-id")

        let error = try waitFor { repository.sendNow(id: "scheduled-id", completion: $0) }

        XCTAssertNil(error)
        XCTAssertNil(apiClient.request_endpoint)
        XCTAssertEqual(try isPendingSendNow(id: "scheduled-id"), true)
        XCTAssertEqual(try storedMessage(id: "scheduled-id")?.status, .preparingToSchedule)
    }

    func test_sendNow_whenTheMessageDoesNotExist_fails() throws {
        let error = try waitFor { repository.sendNow(id: "scheduled-id", completion: $0) }

        XCTAssertTrue(error is ClientError.ScheduledMessageDoesNotExist, "\(String(describing: error))")
    }

    func test_sendPendingChanges_whenMarkedToSendNow_sendsItNow() throws {
        try saveOnServer(id: "scheduled-id")
        _ = try waitFor { repository.sendNow(id: "scheduled-id", completion: $0) }
        apiClient.test_mockResponseResult(.success(sendNowResponse(id: "scheduled-id")))

        let result = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }

        let expectedEndpoint: Endpoint<SendScheduledMessageNowResponse> = .sendScheduledMessageNow(id: "scheduled-id")
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertEqual(try result.get()?.status, .sending)
        XCTAssertEqual(try isPendingSendNow(id: "scheduled-id"), false)
    }

    func test_sendPendingChanges_whenEditedAndMarkedToSendNow_sendsTheChangesBeforeSendingIt() throws {
        try saveOnServer(id: "scheduled-id")
        _ = try waitFor { repository.update(id: "scheduled-id", content: content(text: "Edited"), scheduledAt: nil, completion: $0) }
        _ = try waitFor { repository.sendNow(id: "scheduled-id", completion: $0) }
        apiClient.test_mockResponseResult(.success(updateResponse(
            .dummy(id: "scheduled-id", cid: cid, user: .dummy(userId: userId), message: .dummy(text: "Edited"))
        )))

        _ = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }

        XCTAssertEqual(apiClient.request_endpoint?.path.value, EndpointPath.updateScheduledMessage(id: "scheduled-id").value)
        XCTAssertEqual(try isPendingSendNow(id: "scheduled-id"), true, "Sent once the changes are on the server")

        apiClient.test_mockResponseResult(.success(sendNowResponse(id: "scheduled-id")))
        _ = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }

        let expectedSendNow: Endpoint<SendScheduledMessageNowResponse> = .sendScheduledMessageNow(id: "scheduled-id")
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedSendNow))
    }

    func test_sendPendingChanges_whenSendingNowIsRejected_keepsItMarkedToSendNowOnRetry() throws {
        try saveOnServer(id: "scheduled-id")
        _ = try waitFor { repository.sendNow(id: "scheduled-id", completion: $0) }
        apiClient.test_mockResponseResult(Result<SendScheduledMessageNowResponse, Error>.failure(
            ClientError(with: APIError(code: 4, message: "Rejected", statusCode: 400))
        ))

        _ = try waitFor { repository.sendPendingChanges(id: "scheduled-id", completion: $0) }

        XCTAssertEqual(try storedMessage(id: "scheduled-id")?.status, .failed)
        XCTAssertEqual(try isPendingSendNow(id: "scheduled-id"), true)
    }

    // MARK: - Load

    func test_load_requestsTheScheduledMessages() throws {
        apiClient.test_mockResponseResult(.success(queryResponse([])))
        let query = ScheduledMessageListQuery(filter: .and([.pending, .equal(.cid, to: cid)]), pageSize: 20, next: "cursor")

        _ = try waitFor { repository.loadScheduledMessages(query: query, completion: $0) }.get()

        let expectedEndpoint: Endpoint<QueryScheduledMessagesResponse> = .queryScheduledMessages(
            queryScheduledMessagesRequest: QueryScheduledMessagesRequest(
                filter: ScheduledMessagesFilter(cid: cid.rawValue, status: [.scheduled, .sending]),
                limit: 20,
                next: "cursor"
            )
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_load_withoutFilter_requestsTheWholeList() throws {
        apiClient.test_mockResponseResult(.success(queryResponse([])))

        _ = try waitFor { repository.loadScheduledMessages(query: .init(), completion: $0) }.get()

        let expectedEndpoint: Endpoint<QueryScheduledMessagesResponse> = .queryScheduledMessages(
            queryScheduledMessagesRequest: QueryScheduledMessagesRequest(filter: nil, limit: 100, next: nil)
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_load_returnsTheMessages_andReplacesTheLocalList() throws {
        try saveOnServer(id: "stale")
        apiClient.test_mockResponseResult(.success(queryResponse([.dummy(id: "first", cid: cid), .dummy(id: "second", cid: cid)])))

        let page = try waitFor { repository.loadScheduledMessages(query: .init(), completion: $0) }.get()

        XCTAssertEqual(Set(page.scheduledMessages.map(\.id)), ["first", "second"])
        XCTAssertNil(page.next)
        XCTAssertEqual(Set(try storedMessages().map(\.id)), ["first", "second"])
    }

    func test_load_keepsTheMessagesNotOnTheServerYet() throws {
        _ = try schedule(id: "local").get()
        apiClient.test_mockResponseResult(.success(queryResponse([.dummy(id: "first", cid: cid)])))

        _ = try waitFor { repository.loadScheduledMessages(query: .init(), completion: $0) }.get()

        XCTAssertEqual(Set(try storedMessages().map(\.id)), ["first", "local"])
    }

    func test_load_withAnEmptyCursor_hasNoNextPage() throws {
        apiClient.test_mockResponseResult(.success(queryResponse([.dummy(cid: cid)], next: "")))

        let page = try waitFor { repository.loadScheduledMessages(query: .init(), completion: $0) }.get()

        XCTAssertNil(page.next)
    }

    func test_load_withAFilter_keepsTheOtherMessagesOfTheLocalList() throws {
        apiClient.test_mockResponseResult(.success(sendMessageResponse(.dummy(id: "other", cid: cid))))
        _ = try schedule(id: "other").get()
        apiClient.test_mockResponseResult(.success(queryResponse([.dummy(id: "failed", cid: cid, status: .failed)])))

        let page = try waitFor { repository.loadScheduledMessages(query: .init(filter: .failed), completion: $0) }.get()

        XCTAssertEqual(page.scheduledMessages.map(\.id), ["failed"])
        XCTAssertEqual(Set(try storedMessages().map(\.id)), ["other", "failed"])
    }

    func test_load_withANextPage_keepsTheOtherMessagesOfTheLocalList() throws {
        apiClient.test_mockResponseResult(.success(queryResponse([.dummy(id: "first", cid: cid)], next: "cursor")))
        let firstPage = try waitFor { repository.loadScheduledMessages(query: .init(pageSize: 1), completion: $0) }.get()
        apiClient.test_mockResponseResult(.success(queryResponse([.dummy(id: "second", cid: cid)])))

        let secondPage = try waitFor { repository.loadScheduledMessages(query: .init(pageSize: 1, next: firstPage.next), completion: $0) }.get()

        XCTAssertEqual(firstPage.next, "cursor")
        XCTAssertNil(secondPage.next)
        XCTAssertEqual(Set(try storedMessages().map(\.id)), ["first", "second"])
    }

    func test_load_whenTheRequestFails_fails() throws {
        apiClient.test_mockResponseResult(Result<QueryScheduledMessagesResponse, Error>.failure(ClientError.ConnectionError()))

        let result = try waitFor { repository.loadScheduledMessages(query: .init(), completion: $0) }

        XCTAssertNotNil(result.error)
    }

    // MARK: - Events

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

        // Converting the events saves the scheduled messages, like in the event pipeline.
        nonisolated(unsafe) var domainEvents: [Event] = []
        try database.writeSynchronously { session in
            domainEvents = events.compactMap { $0.toDomainEvent(session: session) }
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
        let failed = try makeMessage(scheduledAt: Date().addingTimeInterval(50), status: .failed)
        let sooner = try makeMessage(scheduledAt: Date().addingTimeInterval(100))

        XCTAssertEqual(try storedMessages().map(\.id), [sooner.id, later.id, failed.id])
    }

    func test_query_sortsBySortingKeys() throws {
        let first = try makeMessage(scheduledAt: Date().addingTimeInterval(100))
        let second = try makeMessage(scheduledAt: Date().addingTimeInterval(200))

        let query = ScheduledMessageListQuery(sort: [.init(key: .scheduledAt, isAscending: false)])

        XCTAssertEqual(try storedMessages(query: query).map(\.id), [second.id, first.id])
    }

    func test_query_filtersByStatusAndChannel() throws {
        let otherCid = ChannelId.unique
        let pending = try makeMessage(scheduledAt: Date().addingTimeInterval(100))
        let failed = try makeMessage(status: .failed)
        let sending = try makeMessage(scheduledAt: Date().addingTimeInterval(200), status: .sending)
        let otherChannel = try makeMessage(cid: otherCid)

        let pendingQuery = ScheduledMessageListQuery(filter: .and([.pending, .equal(.cid, to: cid)]))
        let failedQuery = ScheduledMessageListQuery(filter: .failed)
        let channelsQuery = ScheduledMessageListQuery(filter: .in(.cid, values: [otherCid]))

        XCTAssertEqual(try storedMessages(query: pendingQuery).map(\.id), [pending.id, sending.id])
        XCTAssertEqual(try storedMessages(query: failedQuery).map(\.id), [failed.id])
        XCTAssertEqual(try storedMessages(query: channelsQuery).map(\.id), [otherChannel.id])
    }

    // MARK: - Helpers

    private func saveMessage(id: MessageId) throws {
        try database.createMessage(id: id, cid: cid)
    }

    private func deleteMessage(id: MessageId) throws {
        try database.writeSynchronously { session in
            session.message(id: id)?.deletedAt = Date().bridgeDate
        }
    }

    private func saveChannel(commands: [Command]) throws {
        try database.writeSynchronously { [cid] session in
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid!, config: .mock(commands: commands))))
        }
    }

    private func content(
        text: String = "Hello",
        parentId: MessageId? = nil,
        quotedMessageId: MessageId? = nil
    ) -> ScheduledMessageContent {
        ScheduledMessageContent(
            text: text,
            attachments: [],
            mentionedUserIds: [],
            quotedMessageId: quotedMessageId,
            parentId: parentId,
            showReplyInChannel: false,
            extraData: [:]
        )
    }

    private func schedule(
        id: String = .unique,
        content: ScheduledMessageContent? = nil,
        scheduledAt: Date = Date().addingTimeInterval(3600)
    ) -> Result<ScheduledMessage, Error> {
        do {
            let content = content ?? self.content()
            return try waitFor {
                repository.schedule(id: id, cid: cid, content: content, scheduledAt: scheduledAt, completion: $0)
            }
        } catch {
            return .failure(error)
        }
    }

    private func isPendingSendNow(id: String) throws -> Bool? {
        try database.readSynchronously { $0.scheduledMessage(id: id)?.isPendingSendNow }
    }

    private func sendNowResponse(id: String) -> SendScheduledMessageNowResponse {
        SendScheduledMessageNowResponse(scheduledMessage: .dummy(id: id, cid: cid, user: .dummy(userId: userId), status: .sending))
    }

    private func saveOnServer(id: String) throws {
        _ = try XCTUnwrap(model(from: .dummy(id: id, cid: cid, user: .dummy(userId: userId))))
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
        try? database.writeSynchronously { session in
            try session.saveScheduledMessage(payload: response)
        }
        return try? storedMessage(id: response.id)
    }

    private func storedMessages(query: ScheduledMessageListQuery = .init()) throws -> [ScheduledMessage] {
        try database.readSynchronously { session in
            guard let context = session as? NSManagedObjectContext else { return [] }
            let request = ScheduledMessageDTO.scheduledMessagesFetchRequest(query: query)
            return try ScheduledMessageDTO.load(by: request, context: context).map { try $0.asModel() }
        }
    }

    private func storedMessage(id: String) throws -> ScheduledMessage? {
        try database.readSynchronously { session in
            try session.scheduledMessage(id: id)?.asModel()
        }
    }

    private func makeMessage(
        id: String = .unique,
        cid: ChannelId? = nil,
        text: String = "Hello",
        scheduledAt: Date = Date().addingTimeInterval(3600),
        status: ScheduledMessageServerStatus = .scheduled,
        failureReason: ScheduledMessageFailureReason? = nil
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
        status: ScheduledMessageServerStatus = .scheduled,
        failureReason: ScheduledMessageFailureReason? = nil
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
        mentionedChannel: Bool? = nil,
        mentionedHere: Bool? = nil,
        mentionedRoles: [String]? = nil,
        mentionedUsers: [String]? = nil,
        parentId: String? = nil,
        pinExpires: Date? = nil,
        pinned: Bool? = nil,
        quotedMessageId: String? = nil,
        showInChannel: Bool? = nil
    ) -> ScheduledMessageContentResponse {
        .init(
            attachments: attachments,
            custom: custom,
            mentionedChannel: mentionedChannel,
            mentionedHere: mentionedHere,
            mentionedRoles: mentionedRoles,
            mentionedUsers: mentionedUsers,
            parentId: parentId,
            pinExpires: pinExpires,
            pinned: pinned,
            quotedMessageId: quotedMessageId,
            showInChannel: showInChannel,
            text: text
        )
    }
}
