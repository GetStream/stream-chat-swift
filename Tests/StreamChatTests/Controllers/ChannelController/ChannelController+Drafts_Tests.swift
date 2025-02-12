//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelController_Drafts_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var controller: ChatChannelController!
    var draftsRepository: DraftMessagesRepository_Mock!
    
    override func setUp() {
        super.setUp()
        
        client = ChatClient.mock
        draftsRepository = client.draftMessagesRepository as? DraftMessagesRepository_Mock

        let query = ChannelQuery(cid: .unique)
        controller = ChatChannelController(
            channelQuery: query,
            channelListQuery: nil,
            client: client,
            isChannelAlreadyCreated: true
        )
    }
    
    override func tearDown() {
        client.cleanUp()
        draftsRepository = nil
        controller = nil
        client = nil

        super.tearDown()
    }
    
    // MARK: - Update Draft Tests
    
    func test_updateDraftMessage_whenChannelNotCreated_fails() {
        // Create controller with non-created channel
        controller = ChatChannelController(
            channelQuery: .init(cid: .unique),
            channelListQuery: nil,
            client: client,
            isChannelAlreadyCreated: false
        )
        
        let expectation = expectation(description: "updateDraft completion called")
        controller.updateDraftMessage(text: "test") { result in
            if case .failure(let error) = result {
                XCTAssertTrue(error is ClientError.ChannelNotCreatedYet)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.updateDraft_callCount, 0)
    }
    
    func test_updateDraftMessage_whenSuccessful() {
        let text = "Draft message"
        let message = ChatMessage.mock(text: text)
        
        let expectation = expectation(description: "updateDraft completion called")
        controller.updateDraftMessage(
            text: text,
            isSilent: false,
            attachments: [],
            mentionedUserIds: [],
            quotedMessageId: nil,
            extraData: [:]
        ) { result in
            XCTAssertEqual(try? result.get(), message)
            expectation.fulfill()
        }
        
        draftsRepository.updateDraft_completion?(.success(message))
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.updateDraft_callCount, 1)
    }
    
    func test_updateDraftMessage_whenFailure() {
        let error = TestError()
        
        let expectation = expectation(description: "updateDraft completion called")
        controller.updateDraftMessage(text: "test") { result in
            XCTAssertEqual(error, result.error as? TestError)
            expectation.fulfill()
        }
        
        draftsRepository.updateDraft_completion?(.failure(error))
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.updateDraft_callCount, 1)
    }
    
    // MARK: - Load Draft Tests
    
    func test_loadDraftMessage_whenChannelNotCreated_fails() {
        // Create controller with non-created channel
        controller = ChatChannelController(
            channelQuery: .init(cid: .unique),
            channelListQuery: nil,
            client: client,
            isChannelAlreadyCreated: false
        )
        
        let expectation = expectation(description: "loadDraft completion called")
        controller.loadDraftMessage { result in
            if case .failure(let error) = result {
                XCTAssertTrue(error is ClientError.ChannelNotCreatedYet)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.getDraft_callCount, 0)
    }
    
    func test_loadDraftMessage_whenSuccessful() {
        let message = ChatMessage.mock()
        
        let expectation = expectation(description: "loadDraft completion called")
        controller.loadDraftMessage { result in
            XCTAssertEqual(try? result.get(), message)
            expectation.fulfill()
        }
        
        draftsRepository.getDraft_completion?(.success(message))
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.getDraft_callCount, 1)
    }
    
    func test_loadDraftMessage_whenFailure() {
        let error = TestError()
        
        let expectation = expectation(description: "loadDraft completion called")
        controller.loadDraftMessage { result in
            XCTAssertEqual(error, result.error as? TestError)
            expectation.fulfill()
        }
        
        draftsRepository.getDraft_completion?(.failure(error))
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.getDraft_callCount, 1)
    }
    
    // MARK: - Delete Draft Tests
    
    func test_deleteDraftMessage_whenChannelNotCreated_fails() {
        // Create controller with non-created channel
        controller = ChatChannelController(
            channelQuery: .init(cid: .unique),
            channelListQuery: nil,
            client: client,
            isChannelAlreadyCreated: false
        )
        
        let expectation = expectation(description: "deleteDraft completion called")
        controller.deleteDraftMessage { error in
            XCTAssertTrue(error is ClientError.ChannelNotCreatedYet)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.deleteDraft_callCount, 0)
    }
    
    func test_deleteDraftMessage_whenSuccessful() {
        let expectation = expectation(description: "deleteDraft completion called")
        controller.deleteDraftMessage { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        draftsRepository.deleteDraft_completion?(nil)
        
        waitForExpectations(timeout: defaultTimeout)
    }
    
    func test_deleteDraftMessage_whenFailure() {
        let error = TestError()
        
        let expectation = expectation(description: "deleteDraft completion called")
        controller.deleteDraftMessage { receivedError in
            XCTAssertEqual(error, receivedError as? TestError)
            expectation.fulfill()
        }
        
        draftsRepository.deleteDraft_completion?(error)
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.deleteDraft_callCount, 1)
    }
}
