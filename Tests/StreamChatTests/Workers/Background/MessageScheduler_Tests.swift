//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageScheduler_Tests: XCTestCase {
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer_Spy!
    var repository: ScheduledMessagesRepository!
    var scheduler: MessageScheduler!
    var cid: ChannelId!
    var userId: UserId!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        repository = ScheduledMessagesRepository(database: database, apiClient: apiClient)
        cid = .unique
        userId = .unique
        try? database.createCurrentUser(id: userId)
        scheduler = MessageScheduler(scheduledMessagesRepository: repository, database: database, apiClient: apiClient)
    }

    override func tearDown() {
        apiClient.cleanUp()

        weak var weakScheduler = scheduler
        weak var weakRepository = repository
        weak var weakAPIClient = apiClient
        weak var weakDatabase = database
        scheduler = nil
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

        scheduler = MessageScheduler(scheduledMessagesRepository: repository, database: database, apiClient: apiClient)

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

    func test_scheduler_whenTheRequestFails_marksTheMessageFailed() throws {
        let error = ClientError(with: APIError(code: 4, message: "Pick a time at least 1 minute from now", statusCode: 400))
        apiClient.test_mockResponseResult(Result<SendMessageResponsePayload, Error>.failure(error))

        try scheduleLocally(id: "scheduled-id")

        wait(until: { [self] in localState(of: "scheduled-id") == .sendingFailed })
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

    // MARK: - Helpers

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

    private func localState(of id: String) -> LocalMessageState? {
        database.viewContext.scheduledMessage(id: id)?.message?.localMessageState
    }

    private func sendResponse(id: String) -> SendMessageResponsePayload {
        SendMessageResponsePayload(
            message: .dummy(cid: cid),
            scheduledMessage: .dummy(id: id, cid: cid, user: .dummy(userId: userId))
        )
    }
}
