//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient
import XCTest

final class MessageController_Tests: StressTestCase {
    private var env: TestEnvironment!
    private var client: ChatClient!
    
    private var currentUserId: UserId!
    private var messageId: MessageId!
    private var cid: ChannelId!
    
    private var controller: MessageController!
    private var controllerCallbackQueueID: UUID!
    private var callbackQueueID: UUID { controllerCallbackQueueID }
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        env = TestEnvironment()
        client = Client.mock
        
        currentUserId = .unique
        messageId = .unique
        cid = .unique
        
        controllerCallbackQueueID = UUID()
        controller = MessageController(client: client, cid: cid, messageId: messageId, environment: env.controllerEnvironment)
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }
    
    override func tearDown() {
        controllerCallbackQueueID = nil
        currentUserId = nil
        messageId = nil
        cid = nil
        
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
            Assert.canBeReleased(&env)
        }

        super.tearDown()
    }
    
    // MARK: - Controller
    
    func test_controllerIsCreatedCorrectly() {
        // Create a controller with specific `cid` and `messageId`
        let controller = client.messageController(cid: cid, messageId: messageId)
        
        // Assert controller has correct `cid`
        XCTAssertEqual(controller.cid, cid)
        // Assert controller has correct `messageId`
        XCTAssertEqual(controller.messageId, messageId)
    }

    func test_initialState() {
        // Assert client is assigned correctly
        XCTAssertTrue(controller.client === client)
        
        // Assert initial state is correct
        XCTAssertEqual(controller.state, .inactive)
        
        // Assert message is nil
        XCTAssertNil(controller.message)
    }
    
    // MARK: - Start updating
    
    func test_startUpdating_forwardsObserverError() throws {
        // Update observer to throw the error
        let observerError = TestError()
        env.messageObserver_startUpdatingError = observerError
        
        // Simulate `startUpdating` call
        let completionError = try await(controller.startUpdating)
        
        // Assert correct error is received
        XCTAssertEqual(completionError as? ClientError, ClientError(with: observerError))
        // Assert controller stays in `.inactive` state
        XCTAssertEqual(controller.state, .inactive)
    }
    
    func test_startUpdating_forwardsUpdaterError() throws {
        // Simulate `startUpdating` call
        var completionError: Error?
        controller.startUpdating {
            completionError = $0
        }
        
        // Simulate netrwork response with the error
        let networkError = TestError()
        env.messageUpdater.getMessage_completion?(networkError)
        
        AssertAsync {
            // Assert netrwork error is propogated
            Assert.willBeEqual(completionError as? TestError, networkError)
            // Assert netrwork error is propogated
            Assert.willBeEqual(self.controller.state, .remoteDataFetchFailed(ClientError(with: networkError)))
        }
    }
    
    func test_startUpdating_changesStateCorrectly_ifNoErrorsHappen() throws {
        // Simulate `startUpdating` call
        var completionError: Error?
        var completionCalled = false
        controller.startUpdating {
            completionError = $0
            completionCalled = true
        }
        
        // Assert controller is in `localDataFetched` state
        XCTAssertEqual(controller.state, .localDataFetched)
        
        // Simulate netrwork response with the error
        env.messageUpdater.getMessage_completion?(nil)
        
        AssertAsync {
            // Assert completion is called
            Assert.willBeTrue(completionCalled)
            // Assert completion is called without any error
            Assert.staysTrue(completionError == nil)
            // Assert controller is in `remoteDataFetched` state
            Assert.willBeEqual(self.controller.state, .remoteDataFetched)
        }
    }
    
    // MARK: - Updates

    func test_messageIsUpToDate_onAllStartUpdatingStages() throws {
        let messageLocalText: MessageId = .unique
        
        // Assert message is `nil` initially
        XCTAssertNil(controller.message)
        
        // Create current user in the database
        try client.databaseContainer.createCurrentUser(id: currentUserId)
        
        // Create message in that matches controller's `messageId`
        try client.databaseContainer.createMessage(id: messageId, authorId: currentUserId, cid: cid, text: messageLocalText)
        
        // Simulate `startUpdating` call
        var completionCalled = false
        controller.startUpdating {
            XCTAssertNil($0)
            completionCalled = true
        }
        
        // Assert message is fetched from the database and has correct field values
        var message = try XCTUnwrap(controller.message)
        XCTAssertEqual(message.id, messageId)
        XCTAssertEqual(message.text, messageLocalText)
        
        // Simulate response from the backend with updated `text`, update the local message in the databse
        let messagePayload: MessagePayload<DefaultDataTypes> = .dummy(
            messageId: messageId,
            authorUserId: currentUserId,
            text: .unique
        )
        try client.databaseContainer.writeSynchronously { session in
            try session.saveMessage(payload: messagePayload, for: self.cid)
        }
        env.messageUpdater.getMessage_completion?(nil)
        
        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        
        // Assert the controller's `message` is up-to-date
        message = try XCTUnwrap(controller.message)
        XCTAssertEqual(message.id, messageId)
        XCTAssertEqual(message.text, messagePayload.text)
    }

    // MARK: - Delegate

    func test_delegate_isAssignedCorrectly() {
        let delegate = TestDelegate()

        // Set the delegate
        controller.delegate = delegate

        // Assert the delegate is assigned correctly
        XCTAssert(controller.delegate === delegate)
    }

    func test_delegate_isNotifiedAboutStateChanges() throws {
        // Set the delegate
        let delegate = TestDelegate()
        delegate.expectedQueueId = controllerCallbackQueueID
        controller.delegate = delegate

        // Assert no state changes received so far
        XCTAssertNil(delegate.state)

        // Start updating
        controller.startUpdating()
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)
        
        // Simulate network call response
        env.messageUpdater.getMessage_completion?(nil)
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .remoteDataFetched)
    }

    func test_genericDelegate_isNotifiedAboutStateChanges() throws {
        // Set the generic delegate
        let delegate = TestDelegateGeneric()
        delegate.expectedQueueId = controllerCallbackQueueID
        controller.setDelegate(delegate)

        // Assert no state changes received so far
        XCTAssertNil(delegate.state)
        
        // Start updating
        controller.startUpdating()
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)
        
        // Simulate network call response
        env.messageUpdater.getMessage_completion?(nil)
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .remoteDataFetched)
    }

    func test_delegate_isNotifiedAboutCreatedMessage() throws {
        // Create current user in the database
        try client.databaseContainer.createCurrentUser(id: currentUserId)
        
        // Create channel in the database
        try client.databaseContainer.createChannel(cid: cid)
        
        // Set the delegate
        let delegate = TestDelegate()
        delegate.expectedQueueId = controllerCallbackQueueID
        controller.delegate = delegate
        
        // Simulate `startUpdating` call
        controller.startUpdating()

        // Simulate response from a backend with a message that doesn't exist locally
        let messagePayload: MessagePayload<DefaultDataTypes> = .dummy(
            messageId: messageId,
            authorUserId: currentUserId
        )
        try client.databaseContainer.writeSynchronously { session in
            try session.saveMessage(payload: messagePayload, for: self.cid)
        }
        env.messageUpdater.getMessage_completion?(nil)
        
        // Assert `create` entity change is received by the delegate
        AssertAsync {
            Assert.willBeEqual(delegate.didChangeMessage_change?.fieldChange(\.id), .create(messagePayload.id))
            Assert.willBeEqual(delegate.didChangeMessage_change?.fieldChange(\.text), .create(messagePayload.text))
        }
    }
    
    func test_delegate_isNotifiedAboutUpdatedMessage() throws {
        let initialMessageText: String = .unique

        // Create current user in the database
        try client.databaseContainer.createCurrentUser(id: currentUserId)
        
        // Create channel in the database
        try client.databaseContainer.createChannel(cid: cid)
        
        // Create message in the database with `initialMessageText`
        try client.databaseContainer.createMessage(id: messageId, authorId: currentUserId, cid: cid, text: initialMessageText)
        
        // Set the delegate
        let delegate = TestDelegate()
        delegate.expectedQueueId = controllerCallbackQueueID
        controller.delegate = delegate
        
        // Simulate `startUpdating` call
        controller.startUpdating()
        
        // Simulate response from a backend with a message that exists locally but has out-dated text
        let messagePayload: MessagePayload<DefaultDataTypes> = .dummy(
            messageId: messageId,
            authorUserId: currentUserId,
            text: "new text"
        )
        try client.databaseContainer.writeSynchronously { session in
            try session.saveMessage(payload: messagePayload, for: self.cid)
        }
        env.messageUpdater.getMessage_completion?(nil)
        
        // Assert `update` entity change is received by the delegate
        AssertAsync {
            Assert.willBeEqual(delegate.didChangeMessage_change?.fieldChange(\.id), .update(messagePayload.id))
            Assert.willBeEqual(delegate.didChangeMessage_change?.fieldChange(\.text), .update(messagePayload.text))
        }
    }
    
    // MARK: - Delete message
    
    func test_deleteMessage_propogatesError() {
        // Simulate `deleteMessage` call and catch the completion
        var completionError: Error?
        controller.deleteMessage { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }
        
        // Simulate network response with the error
        let networkError = TestError()
        env.messageUpdater.deleteMessage_completion?(networkError)
        
        // Assert error is propogated
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }
    
    func test_deleteMessage_propogatesNilError() {
        // Simulate `deleteMessage` call and catch the completion
        var completionCalled = false
        controller.deleteMessage { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil($0)
            completionCalled = true
        }
        
        // Simulate successful network response
        env.messageUpdater.deleteMessage_completion?(nil)
        
        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_deleteMessage_callsMessageUpdater_withCorrectValues() {
        // Simulate `deleteMessage` call
        controller.deleteMessage()
        
        // Assert messageUpdater is called with correct `messageId`
        XCTAssertEqual(env.messageUpdater.deleteMessage_messageId, controller.messageId)
    }
    
    // MARK: - Edit message
    
    func test_editMessage_propogatesError() {
        // Simulate `editMessage` call and catch the completion
        var completionError: Error?
        controller.editMessage(text: .unique) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }
        
        // Simulate network response with the error
        let networkError = TestError()
        env.messageUpdater.editMessage_completion?(networkError)
        
        // Assert error is propogated
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }
    
    func test_editMessage_propogatesNilError() {
        // Simulate `editMessage` call and catch the completion
        var completionCalled = false
        controller.editMessage(text: .unique) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil($0)
            completionCalled = true
        }
        
        // Simulate successful network response
        env.messageUpdater.editMessage_completion?(nil)
        
        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_editMessage_callsMessageUpdater_withCorrectValues() {
        let updatedText: String = .unique
        
        // Simulate `editMessage` call and catch the completion
        controller.editMessage(text: updatedText)
        
        // Assert message updater is called with correct `messageId` and `text`
        XCTAssertEqual(env.messageUpdater.editMessage_messageId, controller.messageId)
        XCTAssertEqual(env.messageUpdater.editMessage_text, updatedText)
    }
}

private class TestDelegate: QueueAwareDelegate, MessageControllerDelegate {
    @Atomic var state: Controller.State?
    @Atomic var didChangeMessage_change: EntityChange<Message>?
    
    func controller(_ controller: Controller, didChangeState state: Controller.State) {
        self.state = state
        validateQueue()
    }
    
    func messageController(_ controller: MessageController, didChangeMessage change: EntityChange<Message>) {
        didChangeMessage_change = change
        validateQueue()
    }
}

private class TestDelegateGeneric: QueueAwareDelegate, MessageControllerDelegateGeneric {
    @Atomic var state: Controller.State?
    @Atomic var didChangeMessage_change: EntityChange<Message>?
   
    func controller(_ controller: Controller, didChangeState state: Controller.State) {
        self.state = state
        validateQueue()
    }
    
    func messageController(_ controller: MessageController, didChangeMessage change: EntityChange<Message>) {
        didChangeMessage_change = change
        validateQueue()
    }
}

private class TestEnvironment {
    var messageUpdater: MessageUpdaterMock<DefaultDataTypes>!
    var messageObserver: EntityDatabaseObserverMock<MessageModel<DefaultDataTypes>, MessageDTO>!
    var messageObserver_startUpdatingError: Error?
    
    lazy var controllerEnvironment: MessageController
        .Environment = .init(
            messageObserverBuilder: { [unowned self] in
                self.messageObserver = .init(context: $0, fetchRequest: $1, itemCreator: $2, fetchedResultsControllerType: $3)
                self.messageObserver.startUpdatingError = self.messageObserver_startUpdatingError
                return self.messageObserver!
            },
            messageUpdaterBuilder: { [unowned self] in
                self.messageUpdater = MessageUpdaterMock(database: $0, webSocketClient: $1, apiClient: $2)
                return self.messageUpdater!
            }
        )
}
