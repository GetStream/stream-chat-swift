//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageController_Reminders_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var controller: ChatMessageController!
    var remindersRepository: RemindersRepository_Mock!
    
    override func setUp() {
        super.setUp()
        
        client = ChatClient.mock
        remindersRepository = client.remindersRepository as? RemindersRepository_Mock

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
        remindersRepository = nil
        controller = nil
        client = nil

        super.tearDown()
    }
    
    // MARK: - Create Reminder Tests
    
    func test_createReminder_whenSuccessful() {
        // Prepare data for mocking
        let remindAt = Date()
        let reminderResponse = MessageReminder(
            id: controller.messageId,
            remindAt: remindAt,
            message: .mock(),
            channel: .mockDMChannel(),
            createdAt: .init(),
            updatedAt: .init()
        )
        
        // Setup mock response
        remindersRepository.createReminder_completion_result = .success(reminderResponse)

        // Setup callback verification
        let expectation = expectation(description: "createReminder completion called")
        nonisolated(unsafe) var receivedResult: Result<MessageReminder, Error>?
        
        // Call method being tested
        controller.createReminder(remindAt: remindAt) { result in
            receivedResult = result
            expectation.fulfill()
        }
        
        // Wait for callback
        waitForExpectations(timeout: defaultTimeout)
        
        // Assert remindersRepository is called with correct params
        XCTAssertEqual(remindersRepository.createReminder_messageId, controller.messageId)
        XCTAssertEqual(remindersRepository.createReminder_cid, controller.cid)
        XCTAssertEqual(remindersRepository.createReminder_remindAt, remindAt)
        XCTAssertEqual(receivedResult?.value?.id, reminderResponse.id)
    }
    
    func test_createReminder_whenFailure() {
        // Setup mock error response
        let testError = TestError()
        remindersRepository.createReminder_completion_result = .failure(testError)

        // Setup callback verification
        let expectation = expectation(description: "createReminder completion called")
        nonisolated(unsafe) var receivedError: Error?
        
        // Call method being tested
        controller.createReminder(remindAt: nil) { result in
            if case let .failure(error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }
        
        // Wait for callback
        waitForExpectations(timeout: defaultTimeout)
        
        // Assert callback is called with correct error
        XCTAssertEqual(receivedError as? TestError, testError)
    }
    
    // MARK: - Update Reminder Tests
    
    func test_updateReminder_whenSuccessful() {
        // Prepare data for mocking
        let remindAt = Date()
        let reminderResponse = MessageReminder(
            id: controller.messageId,
            remindAt: remindAt,
            message: .mock(),
            channel: .mockDMChannel(),
            createdAt: .init(),
            updatedAt: .init()
        )
        
        // Setup mock response
        remindersRepository.updateReminder_completion_result = .success(reminderResponse)

        // Setup callback verification
        let expectation = expectation(description: "updateReminder completion called")
        nonisolated(unsafe) var receivedResult: Result<MessageReminder, Error>?
        
        // Call method being tested
        controller.updateReminder(remindAt: remindAt) { result in
            receivedResult = result
            expectation.fulfill()
        }
        
        // Wait for callback
        waitForExpectations(timeout: defaultTimeout)
        
        // Assert remindersRepository is called with correct params
        XCTAssertEqual(remindersRepository.updateReminder_messageId, controller.messageId)
        XCTAssertEqual(remindersRepository.updateReminder_cid, controller.cid)
        XCTAssertEqual(remindersRepository.updateReminder_remindAt, remindAt)
        XCTAssertEqual(receivedResult?.value?.id, reminderResponse.id)
    }
    
    func test_updateReminder_whenFailure() {
        // Setup mock error response
        let testError = TestError()
        remindersRepository.updateReminder_completion_result = .failure(testError)

        // Setup callback verification
        let expectation = expectation(description: "updateReminder completion called")
        nonisolated(unsafe) var receivedError: Error?
        
        // Call method being tested
        controller.updateReminder(remindAt: nil) { result in
            if case let .failure(error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }
        
        // Wait for callback
        waitForExpectations(timeout: defaultTimeout)
        
        // Assert callback is called with correct error
        XCTAssertEqual(receivedError as? TestError, testError)
    }
    
    // MARK: - Delete Reminder Tests
    
    func test_deleteReminder_whenSuccessful() {
        // Setup mock response
        remindersRepository.deleteReminder_error = nil
        
        // Setup callback verification
        let expectation = expectation(description: "deleteReminder completion called")
        nonisolated(unsafe) var receivedError: Error?
        
        // Call method being tested
        controller.deleteReminder { error in
            receivedError = error
            expectation.fulfill()
        }
        
        // Wait for callback
        waitForExpectations(timeout: defaultTimeout)
        
        // Assert remindersRepository is called with correct params
        XCTAssertEqual(remindersRepository.deleteReminder_messageId, controller.messageId)
        XCTAssertEqual(remindersRepository.deleteReminder_cid, controller.cid)
        XCTAssertNil(receivedError)
    }
    
    func test_deleteReminder_whenFailure() {
        // Setup mock error response
        let testError = TestError()
        remindersRepository.deleteReminder_error = testError
        
        // Setup callback verification
        let expectation = expectation(description: "deleteReminder completion called")
        nonisolated(unsafe) var receivedError: Error?
        
        // Call method being tested
        controller.deleteReminder { error in
            receivedError = error
            expectation.fulfill()
        }
        
        // Wait for callback
        waitForExpectations(timeout: defaultTimeout)
        
        // Assert callback is called with correct error
        XCTAssertEqual(receivedError as? TestError, testError)
    }
}
