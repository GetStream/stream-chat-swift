//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class RemindersRepository_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!
    var apiClient: APIClient_Spy!
    var repository: RemindersRepository!
    
    override func setUp() {
        super.setUp()
        
        let client = ChatClient.mock
        database = client.mockDatabaseContainer
        apiClient = client.mockAPIClient
        repository = RemindersRepository(database: database, apiClient: apiClient)
    }
    
    override func tearDown() {
        super.tearDown()
        
        apiClient.cleanUp()
        apiClient = nil
        database = nil
        repository = nil
    }
    
    // MARK: - Load Reminders Tests
    
    func test_loadReminders_makesCorrectAPICall() {
        // Prepare data for the test
        let query = MessageReminderListQuery(
            filter: .equal(.remindAt, to: Date()),
            sort: [.init(key: .remindAt, isAscending: true)]
        )

        // Simulate `loadReminders` call
        let exp = expectation(description: "completion is called")
        repository.loadReminders(query: query) { _ in
            exp.fulfill()
        }
        
        // Mock response
        let response = RemindersQueryPayload(
            reminders: [],
            next: nil
        )
        
        apiClient.test_simulateResponse(.success(response))

        wait(for: [exp], timeout: defaultTimeout)
        
        // Assert endpoint is correct
        let expectedEndpoint: Endpoint<RemindersQueryPayload> = .queryReminders(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_loadReminders_savesRemindersToDatabase() throws {
        // Prepare data for the test
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        let remindAt = Date().addingTimeInterval(3600) // 1 hour from now
        let createdAt = Date().addingTimeInterval(-3600) // 1 hour ago
        let updatedAt = Date()
        
        let query = MessageReminderListQuery(
            filter: .equal(.remindAt, to: Date()),
            sort: [.init(key: .remindAt, isAscending: true)]
        )

        // Create a reminder payload
        let reminderPayload = ReminderPayload(
            channelCid: cid,
            messageId: messageId,
            remindAt: remindAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        
        let response = RemindersQueryPayload(
            reminders: [reminderPayload],
            next: nil
        )

        // Create a message to add reminder to
        try database.createMessage(id: messageId, cid: cid, text: "Test message")

        // Simulate `loadReminders` call
        var result: Result<ReminderListResponse, Error>?
        let exp = expectation(description: "completion is called")
        repository.loadReminders(query: query) { receivedResult in
            result = receivedResult
            exp.fulfill()
        }
        
        apiClient.test_simulateResponse(.success(response))

        wait(for: [exp], timeout: defaultTimeout)
        
        // Assert response is parsed correctly
        guard case .success(let reminderResponse) = result else {
            XCTFail("Expected successful result")
            return
        }
        
        XCTAssertEqual(reminderResponse.reminders.count, 1)
        XCTAssertEqual(reminderResponse.reminders.first?.id, messageId)
        XCTAssertNearlySameDate(reminderResponse.reminders.first?.remindAt, remindAt)
        
        // Assert reminder is saved to database
        var savedReminder: MessageReminder?
        try database.writeSynchronously { session in
            savedReminder = try session.message(id: messageId)?.reminder?.asModel()
        }
        
        XCTAssertNotNil(savedReminder)
        XCTAssertNearlySameDate(savedReminder?.remindAt, remindAt)
    }
    
    func test_loadReminders_propagatesAPIError() {
        // Prepare data for the test
        let query = MessageReminderListQuery(
            filter: .equal(.remindAt, to: Date()),
            sort: [.init(key: .remindAt, isAscending: true)]
        )
        
        // Simulate `loadReminders` call
        var result: Result<ReminderListResponse, Error>?
        let exp = expectation(description: "completion is called")
        repository.loadReminders(query: query) { receivedResult in
            result = receivedResult
            exp.fulfill()
        }
        
        let testError = TestError()
        apiClient.test_simulateResponse(Result<RemindersQueryPayload, Error>.failure(testError))

        wait(for: [exp], timeout: defaultTimeout)
        
        // Assert error is propagated correctly
        guard case .failure = result else {
            XCTFail("Expected failure result")
            return
        }
    }
    
    // MARK: - Create Reminder Tests
    
    func test_createReminder_makesCorrectAPICall() throws {
        // Prepare data for the test
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        let remindAt = Date()
        
        // Create a message to add reminder to
        try database.createMessage(id: messageId, cid: cid, text: "Test message")
        
        // Simulate `createReminder` call
        let exp = expectation(description: "completion is called")
        repository.createReminder(
            messageId: messageId,
            cid: cid,
            remindAt: remindAt
        ) { _ in
            exp.fulfill()
        }
        
        apiClient.test_mockResponseResult(.success(ReminderResponsePayload(
            reminder: .init(
                channelCid: cid,
                messageId: messageId,
                remindAt: remindAt,
                createdAt: .unique,
                updatedAt: .unique
            )
        )))
        
        wait(for: [exp], timeout: defaultTimeout)
        
        // Assert endpoint is correct
        let expectedEndpoint: Endpoint<ReminderResponsePayload> = .createReminder(
            messageId: messageId,
            request: ReminderRequestBody(remindAt: remindAt)
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_createReminder_updatesLocalMessageOptimistically() throws {
        // Prepare data for the test
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        let remindAt = Date()
        
        // Create a message to add reminder to
        try database.createMessage(id: messageId, cid: cid, text: "Test message")
        
        // Simulate `createReminder` call
        repository.createReminder(
            messageId: messageId,
            cid: cid,
            remindAt: remindAt
        ) { _ in }
        
        // Assert reminder was created locally
        var expectedRemindAt: Date?
        try database.writeSynchronously { session in
            let message = session.message(id: messageId)
            expectedRemindAt = message?.reminder?.remindAt?.bridgeDate
        }
        XCTAssertNearlySameDate(expectedRemindAt, remindAt)
    }
    
    func test_createReminder_rollsBackOnFailure() throws {
        // Prepare data for the test
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        let remindAt = Date()
        
        // Create a message to add reminder to
        try database.createMessage(id: messageId, cid: cid, text: "Test message")
        
        // Simulate `createReminder` call
        let exp = expectation(description: "completion is called")
        repository.createReminder(
            messageId: messageId,
            cid: cid,
            remindAt: remindAt
        ) { _ in
            exp.fulfill()
        }
        
        // Assert reminder was created locally
        var expectedRemindAt: Date?
        try database.writeSynchronously { session in
            let message = session.message(id: messageId)
            expectedRemindAt = message?.reminder?.remindAt?.bridgeDate
        }
        XCTAssertNearlySameDate(expectedRemindAt, remindAt)
        
        apiClient.test_simulateResponse(Result<ReminderResponsePayload, Error>.failure(TestError()))
        
        wait(for: [exp], timeout: defaultTimeout)
        
        // Assert reminder was rolled back
        var actualRemindAt: Date?
        try database.writeSynchronously { session in
            let message = session.message(id: messageId)
            actualRemindAt = message?.reminder?.remindAt?.bridgeDate
        }
        XCTAssertNil(actualRemindAt)
    }
    
    // MARK: - Update Reminder Tests
    
    func test_updateReminder_makesCorrectAPICall() throws {
        // Prepare data for the test
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        let newRemindAt = Date().addingTimeInterval(3600) // 1 hour from now
        
        // Create a message with an existing reminder
        try database.createMessage(id: messageId, cid: cid, text: "Test message")

        try database.writeSynchronously { session in
            try session.saveReminder(
                payload: .init(
                    channelCid: cid,
                    messageId: messageId,
                    remindAt: .unique,
                    createdAt: .unique,
                    updatedAt: .unique
                ),
                cache: nil
            )
        }
        
        // Simulate `updateReminder` call
        let exp = expectation(description: "completion is called")
        repository.updateReminder(
            messageId: messageId,
            cid: cid,
            remindAt: newRemindAt
        ) { _ in
            exp.fulfill()
        }
        
        apiClient.test_mockResponseResult(.success(ReminderResponsePayload(
            reminder: .init(
                channelCid: cid,
                messageId: messageId,
                remindAt: newRemindAt,
                createdAt: .unique,
                updatedAt: .unique
            )
        )))
        
        wait(for: [exp], timeout: defaultTimeout)
        
        // Assert endpoint is correct
        let expectedEndpoint: Endpoint<ReminderResponsePayload> = .updateReminder(
            messageId: messageId,
            request: ReminderRequestBody(remindAt: newRemindAt)
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_updateReminder_updatesLocalMessageOptimistically() throws {
        // Prepare data for the test
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        let newRemindAt = Date().addingTimeInterval(3600) // 1 hour from now
        
        // Create a message with an existing reminder
        try database.createMessage(id: messageId, cid: cid, text: "Test message")
        
        try database.writeSynchronously { session in
            try session.saveReminder(
                payload: .init(
                    channelCid: cid,
                    messageId: messageId,
                    remindAt: .unique,
                    createdAt: .unique,
                    updatedAt: .unique
                ),
                cache: nil
            )
        }
        
        // Simulate `updateReminder` call
        repository.updateReminder(
            messageId: messageId,
            cid: cid,
            remindAt: newRemindAt
        ) { _ in }
        
        // Assert reminder was updated locally (optimistically)
        var updatedRemindAt: Date?
        try database.writeSynchronously { session in
            let message = session.message(id: messageId)
            updatedRemindAt = message?.reminder?.remindAt?.bridgeDate
        }
        XCTAssertNearlySameDate(updatedRemindAt, newRemindAt)
    }
    
    func test_updateReminder_rollsBackOnFailure() throws {
        // Prepare data for the test
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        let originalRemindAt = Date().addingTimeInterval(-3600) // 1 hour ago
        let newRemindAt = Date().addingTimeInterval(3600) // 1 hour from now
        
        // Create a message with an existing reminder
        try database.createMessage(id: messageId, cid: cid, text: "Test message")
        
        try database.writeSynchronously { session in
            try session.saveReminder(
                payload: .init(
                    channelCid: cid,
                    messageId: messageId,
                    remindAt: originalRemindAt,
                    createdAt: .unique,
                    updatedAt: .unique
                ),
                cache: nil
            )
        }
        
        // Simulate `updateReminder` call
        let exp = expectation(description: "completion is called")
        repository.updateReminder(
            messageId: messageId,
            cid: cid,
            remindAt: newRemindAt
        ) { _ in
            exp.fulfill()
        }
        
        // Assert reminder was updated locally (optimistically)
        var updatedRemindAt: Date?
        try database.writeSynchronously { session in
            let message = session.message(id: messageId)
            updatedRemindAt = message?.reminder?.remindAt?.bridgeDate
        }
        XCTAssertNearlySameDate(updatedRemindAt, newRemindAt)
        
        // Simulate API failure
        apiClient.test_simulateResponse(Result<ReminderResponsePayload, Error>.failure(TestError()))
        
        wait(for: [exp], timeout: defaultTimeout)
        
        // Assert reminder was rolled back to original state
        var rolledBackRemindAt: Date?
        try database.writeSynchronously { session in
            let message = session.message(id: messageId)
            rolledBackRemindAt = message?.reminder?.remindAt?.bridgeDate
        }
        XCTAssertNearlySameDate(rolledBackRemindAt, originalRemindAt)
    }
    
    // MARK: - Delete Reminder Tests
    
    func test_deleteReminder_makesCorrectAPICall() throws {
        // Prepare data for the test
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        
        // Create a message with reminder
        try database.createMessage(id: messageId, cid: cid, text: "Test message")
        
        try database.writeSynchronously { session in
            try session.saveReminder(
                payload: .init(
                    channelCid: cid,
                    messageId: messageId,
                    remindAt: .unique,
                    createdAt: .unique,
                    updatedAt: .unique
                ),
                cache: nil
            )
        }
        
        // Simulate `deleteReminder` call
        let exp = expectation(description: "completion is called")
        repository.deleteReminder(
            messageId: messageId,
            cid: cid
        ) { _ in
            exp.fulfill()
        }
        
        apiClient.test_mockResponseResult(.success(EmptyResponse()))
        
        wait(for: [exp], timeout: defaultTimeout)
        
        // Assert endpoint is correct
        let expectedEndpoint: Endpoint<EmptyResponse> = .deleteReminder(messageId: messageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_deleteReminder_deletesLocalReminderOptimistically() throws {
        // Prepare data for the test
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        
        // Create a message with reminder
        try database.createMessage(id: messageId, cid: cid, text: "Test message")
        
        try database.writeSynchronously { session in
            try session.saveReminder(
                payload: .init(
                    channelCid: cid,
                    messageId: messageId,
                    remindAt: .unique,
                    createdAt: .unique,
                    updatedAt: .unique
                ),
                cache: nil
            )
        }
        
        // Verify reminder exists before deletion
        var hasReminderBefore = false
        try database.writeSynchronously { session in
            hasReminderBefore = session.message(id: messageId)?.reminder != nil
        }
        XCTAssertTrue(hasReminderBefore, "Message should have a reminder before deletion")
        
        // Simulate `deleteReminder` call
        repository.deleteReminder(
            messageId: messageId,
            cid: cid
        ) { _ in }
        
        // Assert reminder was deleted locally (optimistically)
        var hasReminderAfter = true
        try database.writeSynchronously { session in
            hasReminderAfter = session.message(id: messageId)?.reminder != nil
        }
        XCTAssertFalse(hasReminderAfter, "Reminder should be optimistically deleted locally")
    }
    
    func test_deleteReminder_rollsBackOnFailure() throws {
        // Prepare data for the test
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        
        // Create a message with reminder
        try database.createMessage(id: messageId, cid: cid, text: "Test message")
        
        try database.writeSynchronously { session in
            try session.saveReminder(
                payload: .init(
                    channelCid: cid,
                    messageId: messageId,
                    remindAt: .unique,
                    createdAt: .unique,
                    updatedAt: .unique
                ),
                cache: nil
            )
        }
        
        // Store original reminder values for later comparison
        var originalRemindAt: Date?
        var originalCreatedAt: Date?
        var originalUpdatedAt: Date?
        
        try database.writeSynchronously { session in
            guard let reminder = session.message(id: messageId)?.reminder else { return }
            originalRemindAt = reminder.remindAt?.bridgeDate
            originalCreatedAt = reminder.createdAt.bridgeDate
            originalUpdatedAt = reminder.updatedAt.bridgeDate
        }
        
        // Simulate `deleteReminder` call
        let exp = expectation(description: "completion is called")
        repository.deleteReminder(
            messageId: messageId,
            cid: cid
        ) { _ in
            exp.fulfill()
        }
        
        // Verify reminder was optimistically deleted
        var hasReminderAfterDelete = true
        try database.writeSynchronously { session in
            hasReminderAfterDelete = session.message(id: messageId)?.reminder != nil
        }
        XCTAssertFalse(hasReminderAfterDelete, "Reminder should be optimistically deleted")
        
        // Simulate API failure
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(TestError()))
        
        wait(for: [exp], timeout: defaultTimeout)
        
        // Assert reminder was restored with original values
        var restoredRemindAt: Date?
        var restoredCreatedAt: Date?
        var restoredUpdatedAt: Date?
        
        try database.writeSynchronously { session in
            guard let reminder = session.message(id: messageId)?.reminder else {
                XCTFail("Reminder should be restored after API failure")
                return
            }
            
            restoredRemindAt = reminder.remindAt?.bridgeDate
            restoredCreatedAt = reminder.createdAt.bridgeDate
            restoredUpdatedAt = reminder.updatedAt.bridgeDate
        }
        
        XCTAssertNearlySameDate(restoredRemindAt, originalRemindAt)
        XCTAssertNearlySameDate(restoredCreatedAt, originalCreatedAt)
        XCTAssertNearlySameDate(restoredUpdatedAt, originalUpdatedAt)
    }
}
