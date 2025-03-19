//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class CurrentUserController_Reminders_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var controller: CurrentChatUserController!
    var remindersRepository: RemindersRepository_Mock!
    
    override func setUp() {
        super.setUp()
        
        client = ChatClient.mock
        remindersRepository = client.mockRemindersRepository

        controller = CurrentChatUserController(client: client)
    }
    
    override func tearDown() {
        client.cleanUp()
        remindersRepository = nil
        controller = nil
        client = nil

        super.tearDown()
    }
    
    // MARK: - Load Reminders Tests
    
    func test_loadReminders_whenSuccessful() {
        // Create test data
        let reminders = [
            MessageReminder(
                id: .unique,
                remindAt: Date(),
                message: .mock(),
                channel: .mockDMChannel(),
                createdAt: .init(),
                updatedAt: .init()
            ),
            MessageReminder(
                id: .unique,
                remindAt: nil, // "save for later" type reminder
                message: .mock(),
                channel: .mockDMChannel(),
                createdAt: .init(),
                updatedAt: .init()
            )
        ]
        
        // Setup expectation
        let expectation = expectation(description: "loadReminders completion called")
        var receivedResult: Result<[MessageReminder], Error>?
        
        // Call method being tested
        controller.loadReminders { result in
            receivedResult = result
            expectation.fulfill()
        }
        
        // Provide the mock response after the call
        remindersRepository.loadReminders_completion?(.success(
            ReminderListResponse(reminders: reminders, next: nil)
        ))
        
        // Wait for completion
        waitForExpectations(timeout: defaultTimeout)
        
        // Verify results
        XCTAssertEqual(try? receivedResult?.get().count, 2)
        XCTAssertEqual(controller.hasLoadedAllReminders, true)
        XCTAssertNotNil(remindersRepository.loadReminders_query)
    }
    
    func test_loadReminders_withPagination() {
        // Create test data
        let reminders = [MessageReminder(
            id: .unique,
            remindAt: Date(),
            message: .mock(),
            channel: .mockDMChannel(),
            createdAt: .init(),
            updatedAt: .init()
        )]
        
        // Set up next cursor
        let nextCursor = "next_page_token"
        
        // Setup expectation
        let expectation = expectation(description: "loadReminders completion called")
        var receivedResult: Result<[MessageReminder], Error>?
        
        // Call method being tested
        let query = MessageReminderListQuery(pageSize: 10)
        controller.loadReminders(query: query) { result in
            receivedResult = result
            expectation.fulfill()
        }
        
        // Provide the mock response after the call
        remindersRepository.loadReminders_completion?(.success(
            ReminderListResponse(reminders: reminders, next: nextCursor)
        ))
        
        // Wait for completion
        waitForExpectations(timeout: defaultTimeout)
        
        // Verify results
        XCTAssertEqual(try? receivedResult?.get().count, 1)
        XCTAssertEqual(controller.hasLoadedAllReminders, false)
        XCTAssertEqual(remindersRepository.loadReminders_query?.pagination.pageSize, 10)
    }
    
    func test_loadReminders_whenFailure() {
        // Mock repository error
        let testError = TestError()
        
        // Setup expectation
        let expectation = expectation(description: "loadReminders completion called")
        var receivedError: Error?
        
        // Call method being tested
        controller.loadReminders { result in
            if case let .failure(error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }
        
        // Provide the mock error response after the call
        remindersRepository.loadReminders_completion?(.failure(testError))
        
        // Wait for completion
        waitForExpectations(timeout: defaultTimeout)
        
        // Verify error is passed through
        XCTAssertEqual(receivedError as? TestError, testError)
    }
    
    // MARK: - Load More Reminders Tests
    
    func test_loadMoreReminders_whenSuccessful() {
        // First load initial page
        let initialReminders = [MessageReminder(
            id: .unique,
            remindAt: Date(),
            message: .mock(),
            channel: .mockDMChannel(),
            createdAt: .init(),
            updatedAt: .init()
        )]
        let nextCursor = "test_cursor"
        
        // Call initial load
        controller.loadReminders { _ in }
        remindersRepository.loadReminders_completion?(.success(
            ReminderListResponse(reminders: initialReminders, next: nextCursor)
        ))
        
        // Create test data for second page
        let moreReminders = [MessageReminder(
            id: .unique,
            remindAt: Date(),
            message: .mock(),
            channel: .mockDMChannel(),
            createdAt: .init(),
            updatedAt: .init()
        )]
        
        // Setup expectation for loadMoreReminders
        let expectation = expectation(description: "loadMoreReminders completion called")
        var receivedResult: Result<[MessageReminder], Error>?
        
        // Call method being tested
        controller.loadMoreReminders(limit: 20) { result in
            receivedResult = result
            expectation.fulfill()
        }
        
        // Provide the mock response after the call
        remindersRepository.loadReminders_completion?(.success(
            ReminderListResponse(reminders: moreReminders, next: nil)
        ))
        
        // Wait for completion
        waitForExpectations(timeout: defaultTimeout)
        
        // Verify results
        XCTAssertEqual(try? receivedResult?.get().count, 1)
        XCTAssertEqual(controller.hasLoadedAllReminders, true)
    }
    
    func test_loadMoreReminders_withNoCursor() {
        // Setup expectation
        let expectation = expectation(description: "loadMoreReminders completion called")
        var receivedResult: Result<[MessageReminder], Error>?
        
        // Call method being tested with no cursor set
        controller.loadMoreReminders { result in
            receivedResult = result
            expectation.fulfill()
        }
        
        // Wait for completion
        waitForExpectations(timeout: defaultTimeout)
        
        // Verify no API call was made and empty result returned
        XCTAssertEqual(try? receivedResult?.get().count, 0)
    }
    
    func test_loadMoreReminders_whenFailure() {
        // First load initial page
        let initialReminders = [MessageReminder(
            id: .unique,
            remindAt: Date(),
            message: .mock(),
            channel: .mockDMChannel(),
            createdAt: .init(),
            updatedAt: .init()
        )]
        let nextCursor = "test_cursor"
        
        // Call initial load
        controller.loadReminders { _ in }
        remindersRepository.loadReminders_completion?(.success(
            ReminderListResponse(reminders: initialReminders, next: nextCursor)
        ))
        
        // Setup error for next page
        let testError = TestError()
        
        // Setup expectation
        let expectation = expectation(description: "loadMoreReminders completion called")
        var receivedError: Error?
        
        // Call method being tested
        controller.loadMoreReminders { result in
            if case let .failure(error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }
        
        // Provide the mock error response after the call
        remindersRepository.loadReminders_completion?(.failure(testError))
        
        // Wait for completion
        waitForExpectations(timeout: defaultTimeout)
        
        // Verify error is passed through
        XCTAssertEqual(receivedError as? TestError, testError)
    }
    
    // MARK: - Delegate Tests
    
    func test_messageRemindersObserver_notifiesDelegate() throws {
        class DelegateMock: CurrentChatUserControllerDelegate {
            var reminders: [MessageReminder] = []
            let expectation = XCTestExpectation(description: "Did Change Message Reminders")
            let expectedRemindersCount: Int
            
            init(expectedRemindersCount: Int) {
                self.expectedRemindersCount = expectedRemindersCount
            }
            
            func currentUserController(
                _ controller: CurrentChatUserController,
                didChangeMessageReminders reminders: [MessageReminder]
            ) {
                self.reminders = reminders
                guard expectedRemindersCount == reminders.count else { return }
                expectation.fulfill()
            }
        }

        let delegate = DelegateMock(expectedRemindersCount: 2)
        controller.loadReminders()
        controller.delegate = delegate

        try client.databaseContainer.writeSynchronously { session in
            let date = Date.unique
            let cid = ChannelId.unique
            let messageId1 = MessageId.unique
            let messageId2 = MessageId.unique
            
            try session.saveCurrentUser(payload: .dummy(userId: .unique, role: .admin))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveMessage(payload: .dummy(messageId: messageId1), for: cid, syncOwnReactions: false, cache: nil)
            try session.saveMessage(payload: .dummy(messageId: messageId2), for: cid, syncOwnReactions: false, cache: nil)

            // Create test reminders with different dates
            let reminders = [
                ReminderPayload(
                    channelCid: cid,
                    messageId: messageId1,
                    remindAt: date,
                    createdAt: date,
                    updatedAt: date
                ),
                ReminderPayload(
                    channelCid: cid,
                    messageId: messageId2,
                    remindAt: date.addingTimeInterval(3600), // 1 hour later
                    createdAt: date,
                    updatedAt: date
                )
            ]

            try reminders.forEach {
                try session.saveReminder(payload: $0, cache: nil)
            }
        }
        
        wait(for: [delegate.expectation], timeout: defaultTimeout)
        XCTAssertEqual(controller.messageReminders.count, 2)
        XCTAssertEqual(delegate.reminders.count, 2)
    }
}
