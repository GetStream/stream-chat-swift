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

        AssertAsync {
            Assert.canBeReleased(&scheduler)
            Assert.canBeReleased(&repository)
            Assert.canBeReleased(&apiClient)
            Assert.canBeReleased(&database)
        }

        scheduler = nil
        repository = nil
        apiClient = nil
        database = nil
        cid = nil
        userId = nil

        super.tearDown()
    }

    // MARK: - Tests

    func test_scheduler_sendsTheMessage_whenItIsScheduledLocally() throws {
        apiClient.test_mockUnmanagedResponseResult(.success(sendResponse(id: "scheduled-id")))

        try scheduleLocally(id: "scheduled-id")

        AssertAsync.willBeEqual(
            apiClient.unmanagedRequest_endpoint?.path.value,
            EndpointPath.sendMessage(type: cid.type.rawValue, id: cid.id).value
        )
        AssertAsync.willBeTrue(self.localState(of: "scheduled-id") == nil)
    }

    func test_scheduler_waitsForTheAttachmentsToBeUploaded() throws {
        apiClient.test_mockUnmanagedResponseResult(.success(sendResponse(id: "scheduled-id")))

        try scheduleLocally(id: "scheduled-id", attachments: [.mockFile])

        AssertAsync.staysTrue(apiClient.unmanagedRequest_endpoint == nil)

        try database.writeSynchronously { session in
            session.scheduledMessage(id: "scheduled-id")?.message?.attachments.forEach { $0.localState = .uploaded }
        }

        AssertAsync.willBeEqual(
            apiClient.unmanagedRequest_endpoint?.path.value,
            EndpointPath.sendMessage(type: cid.type.rawValue, id: cid.id).value
        )
    }

    func test_scheduler_syncsTheChanges_ofAMessageOnTheServer() throws {
        try database.writeSynchronously { [cid, userId] session in
            try session.saveScheduledMessage(payload: .dummy(id: "scheduled-id", cid: cid!, user: .dummy(userId: userId!)))
        }
        apiClient.test_mockUnmanagedResponseResult(.success(UpdateScheduledMessageResponse(
            scheduledMessage: .dummy(id: "scheduled-id", cid: cid, user: .dummy(userId: userId))
        )))

        try database.writeSynchronously { session in
            try session.updateScheduledMessage(id: "scheduled-id", content: nil, scheduledAt: Date().addingTimeInterval(7200))
        }

        AssertAsync.willBeEqual(
            apiClient.unmanagedRequest_endpoint?.path.value,
            EndpointPath.updateScheduledMessage(id: "scheduled-id").value
        )
    }

    func test_scheduler_withoutConnection_sendsTheMessageAgainOnceConnected() throws {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        apiClient.test_mockUnmanagedResponseResult(Result<SendMessageResponsePayload, Error>.failure(error))

        try scheduleLocally(id: "scheduled-id")

        AssertAsync.willBeEqual(apiClient.unmanagedRequest_allRecordedCalls.count, 1)
        AssertAsync.willBeTrue(self.localState(of: "scheduled-id") == .pendingSend)
        AssertAsync.staysEqual(apiClient.unmanagedRequest_allRecordedCalls.count, 1)

        apiClient.test_mockUnmanagedResponseResult(.success(sendResponse(id: "scheduled-id")))
        scheduler.didUpdateConnectionState(.connected(healthCheckInfo: .init(connectionId: .unique)))

        AssertAsync.willBeEqual(apiClient.unmanagedRequest_allRecordedCalls.count, 2)
        AssertAsync.willBeTrue(self.localState(of: "scheduled-id") == nil)
    }

    func test_scheduler_whenTheRequestFails_marksTheMessageFailed() throws {
        let error = ClientError(with: APIError(code: 4, message: "Pick a time at least 1 minute from now", statusCode: 400))
        apiClient.test_mockUnmanagedResponseResult(Result<SendMessageResponsePayload, Error>.failure(error))

        try scheduleLocally(id: "scheduled-id")

        AssertAsync.willBeTrue(self.localState(of: "scheduled-id") == .sendingFailed)
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
