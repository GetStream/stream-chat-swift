//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageSearchController_Tests: XCTestCase {
    fileprivate var env: TestEnvironment!
    
    var client: ChatClient!
    
    var query: MessageSearchQuery!
    var controller: ChatMessageSearchController!
    var controllerCallbackQueueID: UUID!
    /// Workaround for unwrapping **controllerCallbackQueueID!** in each closure that captures it
    private var callbackQueueID: UUID { controllerCallbackQueueID }
    
    override func setUpWithError() throws {
        super.setUp()
        
        env = TestEnvironment()
        client = ChatClient.mock
        query = .init(
            channelFilter: .exists(.cid),
            messageFilter: .queryText("")
        )
        controller = ChatMessageSearchController(client: client, environment: env.environment)
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
        // Message search requires a current user
        client.currentUserId = .unique
    }
    
    override func tearDown() {
        controllerCallbackQueueID = nil
        
        env.messageUpdater?.cleanUp()
        (client as? ChatClient_Mock)?.cleanUp()
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
            Assert.canBeReleased(&env)
        }
        controller = nil
        client = nil
        env = nil
        super.tearDown()
    }
    
    func test_clientIsCorrect() {
        let controller = client.userSearchController()
        XCTAssert(controller.client === client)
    }
    
    func test_messagesAreEmpty_beforeSearch() throws {
        // Save a new message to DB, so DB is not empty
        try client.databaseContainer.createMessage()
        
        // Assert that controller messages is empty
        XCTAssert(controller.messages.isEmpty)
    }
    
    func test_controllerQueryRemoved_whenControllerIsDeallocated() throws {
        // Assert that controller messages is empty
        // Calling `messages` property starts observing DB too
        XCTAssert(controller.messages.isEmpty)
        
        // Make a search
        controller.search(text: "Hello")
        
        // Simulate DB update
        let messageId = MessageId.unique
        try client.databaseContainer.createMessage(id: messageId, searchQuery: controller.query)
        
        // Simulate network call response
        env.messageUpdater?.search_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.messageUpdater?.search_completion = nil
        
        var message: ChatMessage? { try? client.databaseContainer.viewContext.message(id: messageId)?.asModel() }
        
        // Check if message is reported
        AssertAsync.willBeEqual(controller.messages.first, message)
        
        let filterHash = controller.query.filterHash
        // Deallocate controller
        controller = nil
        
        var query: MessageSearchQueryDTO? {
            // Force DB to re-fetch DTO from persistent store
            FetchCache.clear()
            return client.databaseContainer.viewContext.messageSearchQuery(filterHash: filterHash)
        }
        
        // Assert query doesn't exist in DB anymore
        AssertAsync.willBeNil(query)
        
        // Assert the message is still here
        AssertAsync.staysTrue(message != nil)
    }
    
    // MARK: - search(text:)
    
    func test_searchWithText_callsMessageUpdater() {
        let queueId = UUID()
        controller.callbackQueue = .testQueue(withId: queueId)
        
        // Simulate `search` calls and catch the completion
        var completionCalled = false
        controller.search(text: "test") { error in
            XCTAssertNil(error)
            AssertTestQueue(withId: queueId)
            completionCalled = true
        }
        
        // Assert the updater is called with the query
        XCTAssertEqual(
            env.messageUpdater?.search_query?.filterHash,
            controller.query.filterHash
        )
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil
        
        // Simulate successful update
        env.messageUpdater?.search_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.messageUpdater?.search_completion = nil
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_searchWithText_resultIsReported() throws {
        // Set the delegate
        let delegate = MessageSearchController_Delegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Assert the delegate is assigned correctly. We should test this because of the type-erasing we
        // do in the controller.
        XCTAssert(controller.delegate === delegate)
        
        // Assert that controller users is empty
        XCTAssert(controller.messages.isEmpty)
        
        // Assert that state is updated
        XCTAssertEqual(controller.state, .localDataFetched)
        // Delegate is updated on a different queue so we have to use AssertAsync
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)
        
        // Make a search
        controller.search(text: "test")
        
        // Simulate DB update
        let messageId = MessageId.unique
        try client.databaseContainer.createMessage(id: messageId, searchQuery: controller.query)
        
        // Simulate network call response
        env.messageUpdater?.search_completion?(nil)
        
        let message = try XCTUnwrap(client.databaseContainer.viewContext.message(id: messageId)?.asModel())
        
        AssertAsync.willBeEqual(controller.messages.count, 1)
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeMessages_changes, [.insert(message, index: [0, 0])])
        
        if #available(iOS 13, *) {
            XCTAssert(controller.basePublishers.controller === controller)
        }
    }
    
    /// This test simulates a bug where the `message` field was not updated if it wasn't
    /// touched before calling synchronize.
    func test_searchWithText_resultIsReported_evenAfterCallingSynchronize() throws {
        // Make a search
        controller.search(text: "test")
        
        // Simulate DB update
        let messageId = MessageId.unique
        try client.databaseContainer.createMessage(id: messageId, searchQuery: controller.query)
        
        // Simulate network call response
        env.messageUpdater?.search_completion?(nil)
        
        let message = try XCTUnwrap(client.databaseContainer.viewContext.message(id: messageId)?.asModel())
        
        XCTAssertEqual(controller.messages, [message])
    }
    
    func test_searchWithText_newlyMatchedMessage_isReportedAsInserted() throws {
        // Add message to DB before searching
        let messageId = MessageId.unique
        try client.databaseContainer.createMessage(id: messageId)
        
        // Set the delegate
        let delegate = MessageSearchController_Delegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Make a search
        controller.search(text: "test")
        
        // Simulate DB update
        try client.databaseContainer.createMessage(id: messageId, searchQuery: controller.query)
        
        // Simulate network call response
        env.messageUpdater?.search_completion?(nil)
        
        let message = try XCTUnwrap(client.databaseContainer.viewContext.message(id: messageId)?.asModel())
        
        AssertAsync.willBeEqual(controller.messages.count, 1)
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeMessages_changes, [.insert(message, index: [0, 0])])
    }
    
    func test_searchWithText_whenNewSearchIsMade_oldMessagesAreNotLinked() throws {
        // For this test, we need to check if `.replace` update policy is correctly passed to
        // the updater instance
        
        // Set the delegate
        let delegate = MessageSearchController_Delegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Make a search
        controller.search(text: "test")
        
        // Assert the correct update policy is passed
        XCTAssertEqual(env.messageUpdater?.search_policy, .replace)
        
        // Simulate DB update
        let messageId = MessageId.unique
        try client.databaseContainer.createMessage(id: messageId, searchQuery: controller.query)
        
        // Simulate search call response
        env.messageUpdater?.search_completion?(nil)
        
        let message = try XCTUnwrap(client.databaseContainer.viewContext.message(id: messageId)?.asModel())
        
        AssertAsync.willBeEqual(controller.messages.count, 1)
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeMessages_changes, [.insert(message, index: [0, 0])])
        
        // Make another search
        controller.search(text: "newTest")
        
        // Simulate DB update
        // This is the expected behavior of MessageUpdater under `.replace` update policy
        let newMessageId = MessageId.unique
        try client.databaseContainer.createMessage(id: newMessageId, searchQuery: controller.query, clearAll: true)
        
        // Simulate network call response
        env.messageUpdater?.search_completion?(nil)
        
        let newMessage = try XCTUnwrap(client.databaseContainer.viewContext.message(id: newMessageId)?.asModel())
        
        // Check if the old message is still matching the new search query (shouldn't)
        XCTAssertEqual(controller.messages.count, 1)
        // Check if delegate method is called
        AssertAsync.willBeEqual(
            delegate.didChangeMessages_changes,
            [.remove(message, index: [0, 0]), .insert(newMessage, index: [0, 0])]
        )
    }
    
    func test_searchWithTerm_errorIsPropagated() {
        let testError = TestError()
        
        // Make a search
        var reportedError: Error?
        controller.search(text: "test") { error in
            reportedError = error
        }
        
        // Simulate network call response
        env.messageUpdater?.search_completion?(testError)
        
        AssertAsync.willBeEqual(reportedError as? TestError, testError)
    }
    
    func test_searchWithTerm_emptySearch_clearsSearch() throws {
        // Set the delegate
        let delegate = MessageSearchController_Delegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Make a search
        controller.search(text: "test")
        
        // Simulate DB update
        try client.databaseContainer.createMessage(id: .unique, searchQuery: controller.query)
        
        // Simulate network call response
        env.messageUpdater?.search_completion?(nil)
        
        // Assert message is reported
        AssertAsync.willBeEqual(controller.messages.count, 1)
        
        // Make an empty search
        controller.search(text: "")
        
        // Assert call is made to `clearSearchResults`
        XCTAssertNotNil(env.messageUpdater?.clearSearchResults_query)
    }
    
    // MARK: - search(query:)
    
    func test_searchWithQuery_callsMessageUpdater() {
        let queueId = UUID()
        controller.callbackQueue = .testQueue(withId: queueId)
        
        // Simulate `search` calls and catch the completion
        var completionCalled = false
        controller.search(query: query) { error in
            XCTAssertNil(error)
            AssertTestQueue(withId: queueId)
            completionCalled = true
        }
        
        // Assert the updater is called with the query
        XCTAssertEqual(
            env.messageUpdater?.search_query?.filterHash,
            controller.query.filterHash
        )
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil
        
        // Simulate successful update
        env.messageUpdater!.search_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.messageUpdater!.search_completion = nil
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_searchWithQuery_resultIsReported() throws {
        // Set the delegate
        let delegate = MessageSearchController_Delegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Assert the delegate is assigned correctly. We should test this because of the type-erasing we
        // do in the controller.
        XCTAssert(controller.delegate === delegate)
        
        // Assert that controller users is empty
        XCTAssert(controller.messages.isEmpty)
        
        // Assert that state is updated
        XCTAssertEqual(controller.state, .localDataFetched)
        // Delegate is updated on a different queue so we have to use AssertAsync
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)
        
        // Make a search
        controller.search(query: query)
        
        // Simulate DB update
        let messageId = MessageId.unique
        try client.databaseContainer.createMessage(id: messageId, searchQuery: controller.query)
        
        // Simulate network call response
        env.messageUpdater?.search_completion?(nil)
        
        let message = try XCTUnwrap(client.databaseContainer.viewContext.message(id: messageId)?.asModel())
        
        AssertAsync.willBeEqual(controller.messages.count, 1)
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeMessages_changes, [.insert(message, index: [0, 0])])
    }
    
    /// This test simulates a bug where the `messages` field was not updated if it wasn't
    /// touched before calling synchronize.
    func test_searchWithQuery_resultIsReported_evenAfterCallingSynchronize() throws {
        // Make a search
        controller.search(query: query)
        
        // Simulate DB update
        let messageId = MessageId.unique
        try client.databaseContainer.createMessage(id: messageId, searchQuery: controller.query)
        
        // Simulate network call response
        env.messageUpdater?.search_completion?(nil)
        
        let message = try XCTUnwrap(client.databaseContainer.viewContext.message(id: messageId)?.asModel())
        XCTAssertEqual(controller.messages, [message])
    }
    
    func test_searchWithQuery_newlyMatchedMessage_isReportedAsInserted() throws {
        // Add message to DB before searching
        let messageId = MessageId.unique
        try client.databaseContainer.createMessage(id: messageId)
        
        // Set the delegate
        let delegate = MessageSearchController_Delegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Make a search
        controller.search(query: query)
        
        // Simulate DB update
        try client.databaseContainer.createMessage(id: messageId, searchQuery: controller.query)
        
        // Simulate network call response
        env.messageUpdater?.search_completion?(nil)
        
        let message = try XCTUnwrap(client.databaseContainer.viewContext.message(id: messageId)?.asModel())
        
        AssertAsync.willBeEqual(controller.messages.count, 1)
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeMessages_changes, [.insert(message, index: [0, 0])])
    }
    
    func test_searchWithQuery_whenNewSearchIsMade_oldMessagesAreNotLinked() throws {
        // For this test, we need to check if `.replace` update policy is correctly passed to
        // the updater instance
        
        // Set the delegate
        let delegate = MessageSearchController_Delegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Make a search
        controller.search(query: query)
        
        // Assert the correct update policy is passed
        XCTAssertEqual(env.messageUpdater!.search_policy, .replace)
        
        // Simulate DB update
        let messageId = MessageId.unique
        try client.databaseContainer.createMessage(id: messageId, searchQuery: controller.query)
        
        // Simulate search call response
        env.messageUpdater?.search_completion?(nil)
        
        let message = try XCTUnwrap(client.databaseContainer.viewContext.message(id: messageId)?.asModel())
        
        AssertAsync.willBeEqual(controller.messages.count, 1)
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeMessages_changes, [.insert(message, index: [0, 0])])
        
        // Make another search
        controller.search(query: query)
        
        // Simulate DB update
        // This is the expected behavior of MessageUpdater under `.replace` update policy
        let newMessageId = MessageId.unique
        try client.databaseContainer.createMessage(id: newMessageId, searchQuery: controller.query, clearAll: true)
        
        // Simulate network call response
        env.messageUpdater?.search_completion?(nil)
        
        let newMessage = try XCTUnwrap(client.databaseContainer.viewContext.message(id: newMessageId)?.asModel())
        
        // Check if the old message is still matching the new search query (shouldn't)
        XCTAssertEqual(controller.messages.count, 1)
        // Check if delegate method is called
        AssertAsync.willBeEqual(
            delegate.didChangeMessages_changes,
            [.remove(message, index: [0, 0]), .insert(newMessage, index: [0, 0])]
        )
    }
    
    func test_searchWithQuery_sortingIsRespected() throws {
        // Set the delegate
        let delegate = MessageSearchController_Delegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Make a search
        controller
            .search(query: .init(
                channelFilter: .exists(.cid),
                messageFilter: .queryText(""),
                sort: [.init(key: .id, isAscending: false)]
            ))
        
        // Simulate DB update
        // `ChatMessageSearchController` sorts the results by id
        // We use random character and not `.unique` for messageId and name
        // Since we'll generate a bigger id for next user's id and name
        // so that insertion will be [0,1] and not [0,0]
        let messageId = "a"
        let olderMessageId = "b"
        try client.databaseContainer.createMessages(ids: [messageId, olderMessageId], searchQuery: controller.query)
        
        // Simulate update call response
        env.messageUpdater?.search_completion?(nil)
        
        let message = try XCTUnwrap(client.databaseContainer.viewContext.message(id: messageId)?.asModel())
        let olderMessage = try XCTUnwrap(client.databaseContainer.viewContext.message(id: olderMessageId)?.asModel())

        AssertAsync.willBeEqual(controller.messages.count, 2)
        // Check if delegate method is called
        AssertAsync {
            Assert.willBeEqual(
                delegate.didChangeMessages_changes?.first(where: { $0.item.id == olderMessage.id }),
                .insert(olderMessage, index: [0, 0])
            )
            Assert.willBeEqual(
                delegate.didChangeMessages_changes?.first(where: { $0.item.id == message.id }),
                .insert(message, index: [0, 1])
            )
        }
    }
    
    func test_searchWithQuery_errorIsPropagated() {
        let testError = TestError()
        
        // Make a search
        var reportedError: Error?
        controller.search(query: query) { error in
            reportedError = error
        }
        
        // Simulate network call response
        env.messageUpdater?.search_completion?(testError)
        
        AssertAsync.willBeEqual(reportedError as? TestError, testError)
    }
    
    // MARK: - loadNextMessages
    
    func test_loadNextMessages_propagatesError() {
        let testError = TestError()
        var reportedError: Error?
        
        // Make a search so we can call `loadNextMessages`
        controller.search(text: "test")
        
        // Simulate network call response
        env.messageUpdater?.search_completion?(nil)
        
        // Call `loadNextMessages`
        controller.loadNextMessages { error in
            reportedError = error
        }
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil
        
        // Simulate network call response
        env.messageUpdater?.search_completion?(testError)
        // Release reference of completion so we can deallocate stuff
        env.messageUpdater?.search_completion = nil
        
        AssertAsync.willBeEqual(reportedError as? TestError, testError)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_loadNextMessages_nextResultPage_isLoaded() throws {
        // Set the delegate
        let delegate = MessageSearchController_Delegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Make a search
        controller
            .search(query: .init(
                channelFilter: .exists(.cid),
                messageFilter: .queryText(""),
                sort: [.init(key: .id, isAscending: true)]
            ))
        
        // Simulate DB update
        // `ChatMessageSearchController` sorts the results by id
        // We use random character and not `.unique` for messageId and name
        // Since we'll generate a bigger id for next user's id and name
        // so that insertion will be [0,1] and not [0,0]
        let messageId = "a"
        try client.databaseContainer.createMessage(id: messageId, searchQuery: controller.query)
        
        // Simulate update call response
        env.messageUpdater?.search_completion?(nil)
        
        let message = try XCTUnwrap(client.databaseContainer.viewContext.message(id: messageId)?.asModel())
        
        AssertAsync.willBeEqual(controller.messages.count, 1)
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeMessages_changes, [.insert(message, index: [0, 0])])
        
        // Load next page
        controller.loadNextMessages()
        
        // Simulate DB update
        let newMessageId = "b"
        try client.databaseContainer.createMessage(id: newMessageId, searchQuery: controller.query)
        
        // Simulate network call response
        env.messageUpdater?.search_completion?(nil)
        
        let newMessage = try XCTUnwrap(client.databaseContainer.viewContext.message(id: newMessageId)?.asModel())
        
        AssertAsync.willBeEqual(controller.messages.count, 2)
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeMessages_changes, [.insert(newMessage, index: [0, 1])])
    }
    
    func test_loadNextMessages_nextResultsPage_cantBeCalledBeforeSearch() {
        var reportedError: Error?
        controller.loadNextMessages { error in
            reportedError = error
        }
        
        // Assert updater is not called
        XCTAssertNil(env.messageUpdater?.search_completion)
        
        // Assert an error is reported
        AssertAsync.willBeFalse(reportedError == nil)
    }
}

private class TestEnvironment {
    @Atomic var messageUpdater: MessageUpdater_Mock?
    
    lazy var environment: ChatMessageSearchController.Environment =
        .init(messageUpdaterBuilder: { [unowned self] in
            self.messageUpdater = MessageUpdater_Mock(
                isLocalStorageEnabled: $0,
                messageRepository: $1,
                database: $2,
                apiClient: $3
            )
            return self.messageUpdater!
        })
}
