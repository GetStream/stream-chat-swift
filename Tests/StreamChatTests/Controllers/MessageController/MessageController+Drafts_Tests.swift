//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageController_Drafts_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var controller: ChatMessageController!
    var draftsRepository: DraftMessagesRepository_Mock!
    
    override func setUp() {
        super.setUp()
        
        client = ChatClient.mock
        draftsRepository = client.draftMessagesRepository as? DraftMessagesRepository_Mock

        let cid = ChannelId.unique
        let messageId = MessageId.unique
        controller = ChatMessageController(
            client: client,
            cid: cid,
            messageId: messageId,
            replyPaginationHandler: MessagesPaginationStateHandler_Mock()
        )
    }
    
    override func tearDown() {
        client.cleanUp()
        draftsRepository = nil
        controller = nil
        client = nil

        super.tearDown()
    }
    
    // MARK: - Update Draft Reply Tests
    
    func test_updateDraftReply_whenSuccessful() {
        let text = "Draft reply"
        let message = ChatMessage.mock(text: text)
        
        let expectation = expectation(description: "updateDraft completion called")
        controller.updateDraftReply(
            text: text,
            isSilent: false,
            attachments: [],
            mentionedUserIds: [],
            quotedMessageId: nil,
            showReplyInChannel: false,
            extraData: [:]
        ) { result in
            XCTAssertEqual(try? result.get(), message)
            expectation.fulfill()
        }
        
        draftsRepository.updateDraft_completion?(.success(message))
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.updateDraft_callCount, 1)
        
        let calledWith = draftsRepository.updateDraft_calledWith
        XCTAssertEqual(calledWith?.cid, controller.cid)
        XCTAssertEqual(calledWith?.threadId, controller.messageId)
    }
    
    func test_updateDraftReply_whenFailure() {
        let error = TestError()
        
        let expectation = expectation(description: "updateDraft completion called")
        controller.updateDraftReply(text: "test") { result in
            XCTAssertEqual(error, result.error as? TestError)
            expectation.fulfill()
        }
        
        draftsRepository.updateDraft_completion?(.failure(error))
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.updateDraft_callCount, 1)
    }
    
    // MARK: - Load Draft Reply Tests
    
    func test_loadDraftReply_whenSuccessful() {
        let message = ChatMessage.mock()
        
        let expectation = expectation(description: "loadDraft completion called")
        controller.loadDraftReply { result in
            XCTAssertEqual(try? result.get(), message)
            expectation.fulfill()
        }
        
        draftsRepository.getDraft_completion?(.success(message))
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.getDraft_callCount, 1)
        
        let calledWith = draftsRepository.getDraft_calledWith
        XCTAssertEqual(calledWith?.cid, controller.cid)
        XCTAssertEqual(calledWith?.threadId, controller.messageId)
    }
    
    func test_loadDraftReply_whenFailure() {
        let error = TestError()
        
        let expectation = expectation(description: "loadDraft completion called")
        controller.loadDraftReply { result in
            XCTAssertEqual(error, result.error as? TestError)
            expectation.fulfill()
        }
        
        draftsRepository.getDraft_completion?(.failure(error))
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.getDraft_callCount, 1)
    }
    
    // MARK: - Delete Draft Reply Tests
    
    func test_deleteDraftReply_whenSuccessful() {
        let expectation = expectation(description: "deleteDraft completion called")
        controller.deleteDraftReply { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        draftsRepository.deleteDraft_completion?(nil)
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.deleteDraft_callCount, 1)
        
        let calledWith = draftsRepository.deleteDraft_calledWith
        XCTAssertEqual(calledWith?.cid, controller.cid)
        XCTAssertEqual(calledWith?.threadId, controller.messageId)
    }
    
    func test_deleteDraftReply_whenFailure() {
        let error = TestError()
        
        let expectation = expectation(description: "deleteDraft completion called")
        controller.deleteDraftReply { receivedError in
            XCTAssertEqual(error, receivedError as? TestError)
            expectation.fulfill()
        }
        
        draftsRepository.deleteDraft_completion?(error)
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.deleteDraft_callCount, 1)
    }
}
