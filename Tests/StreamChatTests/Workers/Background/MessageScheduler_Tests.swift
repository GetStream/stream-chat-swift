//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageScheduler_Tests: XCTestCase {
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer_Spy!
    var eventNotificationCenter: EventNotificationCenter_Mock!
    var repository: ScheduledMessagesRepository!
    var scheduler: MessageScheduler!
    var cid: ChannelId!
    var userId: UserId!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        eventNotificationCenter = EventNotificationCenter_Mock(database: database)
        repository = ScheduledMessagesRepository(database: database, apiClient: apiClient)
        cid = .unique
        userId = .unique
        try? database.createCurrentUser(id: userId)
        scheduler = makeScheduler()
    }

    override func tearDown() {
        apiClient.cleanUp()

        weak var weakScheduler = scheduler
        weak var weakRepository = repository
        weak var weakAPIClient = apiClient
        weak var weakDatabase = database
        scheduler = nil
        eventNotificationCenter = nil
        repository = nil
        apiClient = nil
        database = nil
        wait(until: { weakScheduler == nil && weakRepository == nil && weakAPIClient == nil && weakDatabase == nil })
        cid = nil
        userId = nil

        super.tearDown()
    }

    // MARK: - Tests

    func test_scheduler_sendsTheMessage_whenItIsScheduledLocally() throws {
        apiClient.test_mockResponseResult(.success(sendResponse(id: "scheduled-id")))

        try scheduleLocally(id: "scheduled-id")

        wait(until: { [self] in
            apiClient.request_endpoint?.path.value == EndpointPath.sendMessage(type: cid.type.rawValue, id: cid.id).value
        })
        wait(until: { [self] in localState(of: "scheduled-id") == nil })
    }

    func test_scheduler_waitsForTheAttachmentsToBeUploaded() throws {
        apiClient.test_mockResponseResult(.success(sendResponse(id: "scheduled-id")))

        try scheduleLocally(id: "scheduled-id", attachments: [.mockFile])

        waitWhile { [self] in apiClient.request_endpoint == nil }

        try database.writeSynchronously { session in
            session.scheduledMessage(id: "scheduled-id")?.message?.attachments.forEach { $0.localState = .uploaded }
        }

        wait(until: { [self] in
            apiClient.request_endpoint?.path.value == EndpointPath.sendMessage(type: cid.type.rawValue, id: cid.id).value
        })
    }

    func test_scheduler_syncsTheChanges_ofAMessageOnTheServer() throws {
        try database.writeSynchronously { [cid, userId] session in
            try session.saveScheduledMessage(payload: .dummy(id: "scheduled-id", cid: cid!, user: .dummy(userId: userId!)))
        }
        apiClient.test_mockResponseResult(.success(UpdateScheduledMessageResponse(
            scheduledMessage: .dummy(id: "scheduled-id", cid: cid, user: .dummy(userId: userId))
        )))

        try database.writeSynchronously { session in
            try session.updateScheduledMessage(id: "scheduled-id", content: nil, scheduledAt: Date().addingTimeInterval(7200))
        }

        wait(until: { [self] in
            apiClient.request_endpoint?.path.value == EndpointPath.updateScheduledMessage(id: "scheduled-id").value
        })
    }

    func test_scheduler_whenStarted_syncsTheChangesStuckInSyncing() throws {
        scheduler = nil
        try database.writeSynchronously { [cid, userId] session in
            try session.saveScheduledMessage(payload: .dummy(id: "scheduled-id", cid: cid!, user: .dummy(userId: userId!)))
            try session.updateScheduledMessage(id: "scheduled-id", content: nil, scheduledAt: Date().addingTimeInterval(7200))
            session.scheduledMessage(id: "scheduled-id")?.message?.localMessageState = .syncing
        }
        apiClient.test_mockResponseResult(.success(UpdateScheduledMessageResponse(
            scheduledMessage: .dummy(id: "scheduled-id", cid: cid, user: .dummy(userId: userId))
        )))

        scheduler = makeScheduler()

        wait(until: { [self] in
            apiClient.request_endpoint?.path.value == EndpointPath.updateScheduledMessage(id: "scheduled-id").value
        })
        wait(until: { [self] in localState(of: "scheduled-id") == nil })
    }

    func test_scheduler_withoutConnection_sendsTheMessageAgainOnceConnected() throws {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        apiClient.test_mockResponseResult(Result<SendMessageResponsePayload, Error>.failure(error))

        try scheduleLocally(id: "scheduled-id")

        wait(until: { [self] in apiClient.request_allRecordedCalls.count == 1 })
        wait(until: { [self] in localState(of: "scheduled-id") == .pendingSend })
        waitWhile { [self] in apiClient.request_allRecordedCalls.count == 1 }

        apiClient.test_mockResponseResult(.success(sendResponse(id: "scheduled-id")))
        scheduler.didUpdateConnectionState(.connected(healthCheckInfo: .init(connectionId: .unique)))

        wait(until: { [self] in apiClient.request_allRecordedCalls.count == 2 })
        wait(until: { [self] in localState(of: "scheduled-id") == nil })
    }

    func test_scheduler_whenConnected_uploadsAgainTheAttachmentsThatFailedWithoutConnection() throws {
        try scheduleLocally(id: "pending-id", attachments: [.mockFile])
        try scheduleLocally(id: "failed-id", attachments: [.mockFile])
        try database.writeSynchronously { session in
            session.scheduledMessage(id: "pending-id")?.message?.attachments.forEach { $0.localState = .uploadingFailed }
            let failed = session.scheduledMessage(id: "failed-id")?.message
            failed?.attachments.forEach { $0.localState = .uploadingFailed }
            failed?.localMessageState = .sendingFailed
        }

        scheduler.didUpdateConnectionState(.connected(healthCheckInfo: .init(connectionId: .unique)))

        wait(until: { [self] in attachmentStates(of: "pending-id") == [.pendingUpload] })
        XCTAssertEqual(attachmentStates(of: "failed-id"), [.uploadingFailed])
    }

    func test_scheduler_whenTheRequestFails_marksTheMessageFailed() throws {
        let error = ClientError(with: APIError(code: 4, message: "Pick a time at least 1 minute from now", statusCode: 400))
        apiClient.test_mockResponseResult(Result<SendMessageResponsePayload, Error>.failure(error))

        try scheduleLocally(id: "scheduled-id")

        wait(until: { [self] in localState(of: "scheduled-id") == .sendingFailed })
    }

    func test_scheduler_whenTheServerSendsTheMessageRightAway_postsASentNowEvent() throws {
        try database.createChannel(cid: cid)
        apiClient.test_mockResponseResult(.success(SendMessageResponsePayload(
            message: .dummy(messageId: "scheduled-id", authorUserId: userId, cid: cid),
            scheduledMessage: nil
        )))

        try scheduleLocally(id: "scheduled-id")

        wait(until: { [self] in !eventNotificationCenter.mock_processCalledWithEvents.isEmpty })
        let event = try XCTUnwrap(eventNotificationCenter.mock_processCalledWithEvents.first as? ScheduledMessageSentEvent)
        XCTAssertTrue(event.isSentNow)
        XCTAssertEqual(event.messageId, "scheduled-id")
        XCTAssertEqual(event.cid, cid)
    }

    func test_scheduler_sendsNow_aMessageMarkedToBeSentNow() throws {
        try database.writeSynchronously { [cid, userId] session in
            let dto = try session.saveScheduledMessage(payload: .dummy(id: "scheduled-id", cid: cid!, user: .dummy(userId: userId!)))
            dto.isPendingSendNow = true
        }
        apiClient.test_mockResponseResult(.success(SendScheduledMessageNowResponse(
            scheduledMessage: .dummy(id: "scheduled-id", cid: cid, user: .dummy(userId: userId), status: .sending)
        )))

        wait(until: { [self] in
            apiClient.request_endpoint?.path.value == EndpointPath.sendScheduledMessageNow(id: "scheduled-id").value
        })
    }

    func test_scheduler_waitsForTheAttachmentsBeforeSendingNow() throws {
        try scheduleLocally(id: "scheduled-id", attachments: [.mockFile])
        try database.writeSynchronously { session in
            session.scheduledMessage(id: "scheduled-id")?.isPendingSendNow = true
        }

        waitWhile { [self] in apiClient.request_endpoint == nil }
    }

    // MARK: - Waiting for the API request

    func test_waitForAPIRequest_completesWithTheScheduledMessageOfTheServer() throws {
        apiClient.test_mockResponseResult(.success(sendResponse(id: "scheduled-id")))

        let result = try waitFor { scheduleWaitingForAPIRequest(id: "scheduled-id", completion: $0) }

        XCTAssertEqual(try result.get().id, "scheduled-id")
        XCTAssertNil(try result.get().failure)
    }

    func test_waitForAPIRequest_whenTheRequestFails_completesWithItsError() throws {
        let error = ClientError(with: APIError(code: 4, message: "Pick a time at least 1 minute from now", statusCode: 400))
        apiClient.test_mockResponseResult(Result<SendMessageResponsePayload, Error>.failure(error))

        let result = try waitFor { scheduleWaitingForAPIRequest(id: "scheduled-id", completion: $0) }

        XCTAssertEqual((result.error as? ClientError)?.apiError?.message, "Pick a time at least 1 minute from now")
    }

    func test_waitForAPIRequest_whenTheLocalWriteFails_completesWithItsError() throws {
        let result = try waitFor { completion in
            scheduler.waitForAPIRequest(
                afterLocalWrite: { [repository] in repository!.sendNow(id: "unknown-id", completion: $0) },
                completion: completion
            )
        }

        XCTAssertTrue(result.error is ClientError.ScheduledMessageDoesNotExist)
        XCTAssertNil(apiClient.request_endpoint)
    }

    func test_waitForAPIRequest_afterAConnectionError_failsTheWaitersWithoutRequests() throws {
        scheduleWaitingForAPIRequest(id: "first") { _ in }
        wait(until: { [self] in apiClient.request_endpoint != nil })
        let queuedCompleted = expectation(description: "queued completed")
        nonisolated(unsafe) var queued: Result<ScheduledMessage, Error>?
        scheduleWaitingForAPIRequest(id: "queued") {
            queued = $0
            queuedCompleted.fulfill()
        }

        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        apiClient.test_simulateResponse(Result<SendMessageResponsePayload, Error>.failure(error))
        wait(for: [queuedCompleted], timeout: defaultTimeout)
        let later = try waitFor { scheduleWaitingForAPIRequest(id: "later", completion: $0) }

        XCTAssertEqual((queued?.error as? NSError)?.code, NSURLErrorNotConnectedToInternet)
        XCTAssertTrue(later.error is ClientError.ConnectionError)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 1)
        XCTAssertEqual(localState(of: "later"), .pendingSend)
    }

    func test_waitForAPIRequest_whenSendingNowAMessageWithFailedChanges_completesOnceItIsSentNow() throws {
        try database.writeSynchronously { [cid, userId] session in
            try session.saveScheduledMessage(payload: .dummy(id: "scheduled-id", cid: cid!, user: .dummy(userId: userId!)))
            session.scheduledMessage(id: "scheduled-id")?.message?.localMessageState = .syncingFailed
        }
        apiClient.test_mockResponseResult(.success(UpdateScheduledMessageResponse(
            scheduledMessage: .dummy(id: "scheduled-id", cid: cid, user: .dummy(userId: userId))
        )))
        apiClient.test_mockResponseResult(.success(SendScheduledMessageNowResponse(
            scheduledMessage: .dummy(id: "scheduled-id", cid: cid, user: .dummy(userId: userId), status: .sending)
        )))

        let result = try waitFor { completion in
            scheduler.waitForAPIRequest(
                afterLocalWrite: { [repository] in repository!.sendNow(id: "scheduled-id", completion: $0) },
                completion: completion
            )
        }

        XCTAssertEqual(try result.get().status, .sending)
        XCTAssertEqual(
            apiClient.request_allRecordedCalls.map(\.endpoint.path.value),
            [EndpointPath.updateScheduledMessage(id: "scheduled-id").value, EndpointPath.sendScheduledMessageNow(id: "scheduled-id").value]
        )
    }

    func test_waitForAPIRequest_whenAnAttachmentFailsToUpload_failsWithoutARequest() throws {
        let completed = expectation(description: "completed")
        nonisolated(unsafe) var result: Result<ScheduledMessage, Error>?
        scheduleWaitingForAPIRequest(id: "scheduled-id", attachments: [.mockFile]) {
            result = $0
            completed.fulfill()
        }

        try database.writeSynchronously { session in
            let message = try XCTUnwrap(session.scheduledMessage(id: "scheduled-id")?.message)
            message.attachments.forEach { $0.localState = .uploadingFailed }
            message.localMessageState = .sendingFailed
        }

        wait(for: [completed], timeout: defaultTimeout)
        XCTAssertTrue(result?.error is ClientError.AttachmentUploading)
        XCTAssertNil(apiClient.request_endpoint)
    }

    // MARK: - Helpers

    private func makeScheduler() -> MessageScheduler {
        MessageScheduler(
            scheduledMessagesRepository: repository,
            eventNotificationCenter: eventNotificationCenter,
            database: database,
            apiClient: apiClient
        )
    }

    private func scheduleLocally(id: String, attachments: [AnyAttachmentPayload] = []) throws {
        let content = ScheduledMessageContent(
            text: "Hello",
            attachments: attachments,
            mentionedUserIds: [],
            quotedMessageId: nil,
            parentId: nil,
            showReplyInChannel: false,
            extraData: [:]
        )
        try database.writeSynchronously { [cid] session in
            try session.createNewScheduledMessage(id: id, cid: cid!, content: content, scheduledAt: Date().addingTimeInterval(3600))
        }
    }

    private func scheduleWaitingForAPIRequest(
        id: String,
        attachments: [AnyAttachmentPayload] = [],
        completion: @escaping @Sendable (Result<ScheduledMessage, Error>) -> Void
    ) {
        scheduler.waitForAPIRequest(
            afterLocalWrite: { [repository, cid] in
                repository!.schedule(
                    id: id,
                    cid: cid!,
                    content: .dummy(attachments: attachments),
                    scheduledAt: Date().addingTimeInterval(3600),
                    completion: $0
                )
            },
            completion: completion
        )
    }

    private func localState(of id: String) -> LocalMessageState? {
        database.viewContext.scheduledMessage(id: id)?.message?.localMessageState
    }

    private func attachmentStates(of id: String) -> [LocalAttachmentState?] {
        database.viewContext.scheduledMessage(id: id)?.message?.attachments.map(\.localState) ?? []
    }

    private func sendResponse(id: String) -> SendMessageResponsePayload {
        SendMessageResponsePayload(
            message: .dummy(cid: cid),
            scheduledMessage: .dummy(id: id, cid: cid, user: .dummy(userId: userId))
        )
    }
}
