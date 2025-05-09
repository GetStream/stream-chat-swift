//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class CurrentUserController_Drafts_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var controller: CurrentChatUserController!
    var draftsRepository: DraftMessagesRepository_Mock!
    
    override func setUp() {
        super.setUp()
        
        client = ChatClient.mock
        draftsRepository = client.draftMessagesRepository as? DraftMessagesRepository_Mock
        controller = CurrentChatUserController(client: client)
    }
    
    override func tearDown() {
        client.cleanUp()
        draftsRepository = nil
        controller = nil
        client = nil
        
        super.tearDown()
    }
    
    // MARK: - Load Draft Messages Tests
    
    func test_loadDraftMessages_whenSuccessful() {
        let messages: [DraftMessage] = [.mock(), .mock()]
        let nextCursor = "next_page"
        
        let expectation = expectation(description: "loadDraftMessages completion called")
        controller.loadDraftMessages { result in
            XCTAssertEqual(try? result.get(), messages)
            expectation.fulfill()
        }
        
        draftsRepository.loadDrafts_completion?(.success(.init(drafts: messages, next: nextCursor)))
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.loadDrafts_callCount, 1)
        XCTAssertFalse(controller.hasLoadedAllDrafts)
    }
    
    func test_loadDraftMessages_whenNoNextCursor_marksAsLoadedAll() {
        let messages: [DraftMessage] = [.mock(), .mock()]

        let expectation = expectation(description: "loadDraftMessages completion called")
        controller.loadDraftMessages { result in
            XCTAssertEqual(try? result.get(), messages)
            expectation.fulfill()
        }
        
        draftsRepository.loadDrafts_completion?(.success(.init(drafts: messages, next: nil)))
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.loadDrafts_callCount, 1)
        XCTAssertTrue(controller.hasLoadedAllDrafts)
    }
    
    func test_loadDraftMessages_whenFailure() {
        let error = TestError()
        
        let expectation = expectation(description: "loadDraftMessages completion called")
        controller.loadDraftMessages { result in
            XCTAssertEqual(error, result.error as? TestError)
            expectation.fulfill()
        }
        
        draftsRepository.loadDrafts_completion?(.failure(error))
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.loadDrafts_callCount, 1)
    }
    
    // MARK: - Load More Draft Messages Tests
    
    func test_loadMoreDraftMessages_whenNoNextCursor_returnsEmpty() {
        let expectation = expectation(description: "loadMoreDraftMessages completion called")
        controller.loadMoreDraftMessages { result in
            XCTAssertEqual(try? result.get(), [])
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.loadDrafts_callCount, 0)
    }
    
    func test_loadMoreDraftMessages_whenSuccessful() {
        // First load initial page
        let initialMessages: [DraftMessage] = [.mock(), .mock()]
        let nextCursor = "next_page"
        controller.loadDraftMessages { _ in }
        draftsRepository.loadDrafts_completion?(.success(.init(drafts: initialMessages, next: nextCursor)))
        
        // Then load more
        let moreMessages: [DraftMessage] = [.mock(), .mock()]
        let expectation = expectation(description: "loadMoreDraftMessages completion called")
        controller.loadMoreDraftMessages { result in
            XCTAssertEqual(try? result.get(), moreMessages)
            expectation.fulfill()
        }
        
        draftsRepository.loadDrafts_completion?(.success(.init(drafts: moreMessages, next: nil)))
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.loadDrafts_callCount, 2)
        XCTAssertTrue(controller.hasLoadedAllDrafts)
    }
    
    func test_loadMoreDraftMessages_whenFailure() {
        // First load initial page
        let initialMessages: [DraftMessage] = [.mock(), .mock()]
        let nextCursor = "next_page"
        controller.loadDraftMessages { _ in }
        draftsRepository.loadDrafts_completion?(.success(.init(drafts: initialMessages, next: nextCursor)))
        
        // Then try to load more
        let error = TestError()
        let expectation = expectation(description: "loadMoreDraftMessages completion called")
        controller.loadMoreDraftMessages { result in
            XCTAssertEqual(error, result.error as? TestError)
            expectation.fulfill()
        }
        
        draftsRepository.loadDrafts_completion?(.failure(error))
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.loadDrafts_callCount, 2)
    }
    
    // MARK: - Delete Draft Message Tests
    
    func test_deleteDraftMessage_whenSuccessful() {
        let cid = ChannelId.unique
        let threadId = MessageId.unique
        
        let expectation = expectation(description: "deleteDraftMessage completion called")
        controller.deleteDraftMessage(for: cid, threadId: threadId) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        draftsRepository.deleteDraft_completion?(nil)
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.deleteDraft_callCount, 1)
        let calledWith = draftsRepository.deleteDraft_calledWith
        XCTAssertEqual(calledWith?.cid, cid)
        XCTAssertEqual(calledWith?.threadId, threadId)
    }
    
    func test_deleteDraftMessage_whenFailure() {
        let error = TestError()
        
        let expectation = expectation(description: "deleteDraftMessage completion called")
        controller.deleteDraftMessage(for: .unique) { receivedError in
            XCTAssertEqual(error, receivedError as? TestError)
            expectation.fulfill()
        }
        
        draftsRepository.deleteDraft_completion?(error)
        
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(draftsRepository.deleteDraft_callCount, 1)
    }
    
    // MARK: - Delegate Tests
    
    func test_draftMessagesObserver_notifiesDelegate() throws {
        class DelegateMock: CurrentChatUserControllerDelegate {
            var messages: [DraftMessage] = []
            let expectation = XCTestExpectation(description: "Did Change Draft Messages")
            let expectedMessagesCount: Int
            
            init(expectedMessagesCount: Int) {
                self.expectedMessagesCount = expectedMessagesCount
            }
            
            func currentUserController(
                _ controller: CurrentChatUserController,
                didChangeDraftMessages messages: [DraftMessage]
            ) {
                self.messages = messages
                guard expectedMessagesCount == messages.count else { return }
                expectation.fulfill()
            }
        }

        let delegate = DelegateMock(expectedMessagesCount: 2)
        controller.loadDraftMessages()
        controller.delegate = delegate

        try client.databaseContainer.writeSynchronously { session in
            let date = Date.unique
            let cid = ChannelId.unique
            let parentId = MessageId.unique
            try session.saveCurrentUser(payload: .dummy(userId: .unique, role: .admin))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveMessage(payload: .dummy(messageId: parentId), for: cid, syncOwnReactions: false, cache: nil)

            // Test a draft in a channel and thread in the same channel
            let messages = [
                DraftPayload.dummy(cid: cid, createdAt: date, message: .dummy(text: "1")),
                DraftPayload.dummy(cid: cid, createdAt: date.addingTimeInterval(1), message: .dummy(text: "2"), parentId: parentId)
            ]

            try messages.forEach {
                try session.saveDraftMessage(payload: $0, for: cid, cache: nil)
            }
        }
        
        wait(for: [delegate.expectation], timeout: defaultTimeout)
        XCTAssertEqual(controller.draftMessages.count, 2)
        XCTAssertEqual(delegate.messages.map(\.text), ["2", "1"])
    }
}
