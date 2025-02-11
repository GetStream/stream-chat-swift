//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class DraftMessagesRepository_Tests: XCTestCase {
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer!
    var repository: DraftMessagesRepository!
    
    override func setUp() {
        super.setUp()
        
        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        repository = DraftMessagesRepository(database: database, apiClient: apiClient)
    }
    
    override func tearDown() {
        apiClient.cleanUp()
        
        apiClient = nil
        repository = nil
        database = nil
        
        super.tearDown()
    }
    
    // MARK: - Load Drafts Tests
    
    func test_loadDrafts_whenSuccessful() throws {
        let channelId = ChannelId.unique
        try savePreExistingData(channelId: channelId, threadId: nil)

        let query = DraftListQuery()
        let draftPayload1 = DraftPayload.dummy(
            cid: channelId,
            channelPayload: .dummy(cid: channelId),
            message: .dummy(text: "Draft 1")
        )
        let draftPayload2 = DraftPayload.dummy(
            cid: channelId,
            channelPayload: .dummy(cid: channelId),
            message: .dummy(text: "Draft 2")
        )
        
        let payload = DraftListPayloadResponse(drafts: [draftPayload1, draftPayload2], next: "next_page")

        let completionCalled = expectation(description: "completion called")
        repository.loadDrafts(query: query) { result in
            XCTAssertNil(result.error)
            XCTAssertEqual(result.value?.drafts.count, 2)
            XCTAssertEqual(result.value?.next, "next_page")
            completionCalled.fulfill()
        }
        
        apiClient.test_simulateResponse(.success(payload))
        
        wait(for: [completionCalled], timeout: defaultTimeout)
        
        let referenceEndpoint: Endpoint<DraftListPayloadResponse> = .drafts(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_loadDrafts_whenFailure() {
        let query = DraftListQuery()
        let completionCalled = expectation(description: "completion called")
        
        repository.loadDrafts(query: query) { result in
            XCTAssertNotNil(result.error)
            completionCalled.fulfill()
        }
        
        let error = TestError()
        apiClient.test_simulateResponse(Result<DraftListPayloadResponse, Error>.failure(error))

        wait(for: [completionCalled], timeout: defaultTimeout)
    }
    
    // MARK: - Update Draft Tests
    
    func test_updateDraft_whenSuccessful() throws {
        let channelId = ChannelId.unique
        let text = "Draft message"
        let threadId: MessageId = .unique
        try savePreExistingData(channelId: channelId, threadId: threadId)

        let draftPayload = DraftPayload.dummy(
            cid: channelId,
            channelPayload: .dummy(cid: channelId),
            message: .dummy(
                text: text,
                showReplyInChannel: false,
                isSilent: false
            ),
            parentId: threadId
        )
        
        let completionCalled = expectation(description: "completion called")
        repository.updateDraft(
            for: channelId,
            threadId: threadId,
            text: text,
            isSilent: false,
            showReplyInChannel: true,
            command: nil,
            arguments: nil,
            attachments: [],
            mentionedUserIds: ["leia"],
            quotedMessageId: "quotedID",
            extraData: [:]
        ) { result in
            XCTAssertNil(result.error)
            completionCalled.fulfill()
        }

        wait(for: [apiClient.request_expectation], timeout: defaultTimeout)

        apiClient.test_simulateResponse(.success(DraftPayloadResponse(draft: draftPayload)))

        wait(for: [completionCalled], timeout: defaultTimeout)

        let requestBodyMessage = try XCTUnwrap(apiClient.request_endpoint?.bodyAsDictionary()["message"] as? [String: Any])
        AssertDictionary(ignoringKeys: ["id"], requestBodyMessage, [
            "mentioned_users": ["leia"],
            "parent_id": threadId,
            "show_in_channel": 1,
            "silent": 0,
            "text": text
        ])
    }
    
    func test_updateDraft_whenFailure() {
        let channelId = ChannelId.unique
        let text = "Draft message"
        
        let completionCalled = expectation(description: "completion called")
        repository.updateDraft(
            for: channelId,
            threadId: nil,
            text: text,
            isSilent: false,
            showReplyInChannel: false,
            command: nil,
            arguments: nil,
            attachments: [],
            mentionedUserIds: [],
            quotedMessageId: nil,
            extraData: [:]
        ) { result in
            XCTAssertNotNil(result.error)
            completionCalled.fulfill()
        }
        
        let error = TestError()
        apiClient.test_simulateResponse(Result<DraftPayloadResponse, Error>.failure(error))

        wait(for: [completionCalled], timeout: defaultTimeout)
    }
    
    // MARK: - Get Draft Tests
    
    func test_getDraft_whenSuccessful() throws {
        let channelId = ChannelId.unique
        let threadId: MessageId = .unique
        try savePreExistingData(channelId: channelId, threadId: threadId)

        let draftPayload = DraftPayload.dummy(
            cid: channelId,
            channelPayload: .dummy(cid: channelId),
            parentId: threadId
        )
        
        let completionCalled = expectation(description: "completion called")
        repository.getDraft(for: channelId, threadId: threadId) { result in
            XCTAssertNil(result.error)
            completionCalled.fulfill()
        }
        
        apiClient.test_simulateResponse(.success(DraftPayloadResponse(draft: draftPayload)))

        wait(for: [completionCalled], timeout: defaultTimeout)
        
        let referenceEndpoint: Endpoint<DraftPayloadResponse> = .getDraftMessage(channelId: channelId, threadId: threadId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_getDraft_whenFailure() {
        let channelId = ChannelId.unique
        let threadId: MessageId? = nil
        
        let completionCalled = expectation(description: "completion called")
        repository.getDraft(for: channelId, threadId: threadId) { result in
            XCTAssertNotNil(result.error)
            completionCalled.fulfill()
        }
        
        let error = TestError()
        apiClient.test_simulateResponse(Result<DraftPayloadResponse, Error>.failure(error))

        wait(for: [completionCalled], timeout: defaultTimeout)
    }
    
    // MARK: - Delete Draft Tests
    
    func test_deleteDraft_whenSuccessful() {
        let channelId = ChannelId.unique
        let threadId: MessageId? = .unique
        
        let completionCalled = expectation(description: "completion called")
        repository.deleteDraft(for: channelId, threadId: threadId) { error in
            XCTAssertNil(error)
            completionCalled.fulfill()
        }
        
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))
        
        wait(for: [completionCalled], timeout: defaultTimeout)
        
        let referenceEndpoint: Endpoint<EmptyResponse> = .deleteDraftMessage(channelId: channelId, threadId: threadId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_deleteDraft_whenFailure() {
        let channelId = ChannelId.unique
        let threadId: MessageId? = nil
        
        let completionCalled = expectation(description: "completion called")
        repository.deleteDraft(for: channelId, threadId: threadId) { error in
            XCTAssertNotNil(error)
            completionCalled.fulfill()
        }
        
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))
        
        wait(for: [completionCalled], timeout: defaultTimeout)
    }

    private func savePreExistingData(channelId: ChannelId, threadId: MessageId?) throws {
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: .unique, role: .user))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: channelId)))
            if let threadId {
                try session.saveMessage(payload: .dummy(messageId: threadId), for: channelId, syncOwnReactions: false, cache: nil)
            }
        }
    }
}
