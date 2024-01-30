//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageController_Tests: XCTestCase {
    private var env: TestEnvironment!
    private var client: ChatClient_Mock!

    private var currentUserId: UserId!
    private var messageId: MessageId!
    private var cid: ChannelId!

    private var controller: ChatMessageController!
    private var controllerCallbackQueueID: UUID!
    private var callbackQueueID: UUID { controllerCallbackQueueID }

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        env = TestEnvironment()
        client = ChatClient.mock

        currentUserId = .unique
        messageId = .unique
        cid = .unique

        controllerCallbackQueueID = UUID()
        controller = ChatMessageController(client: client, cid: cid, messageId: messageId, environment: env.controllerEnvironment)
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }

    override func tearDown() {
        env.messageUpdater?.cleanUp()

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
        XCTAssertEqual(controller.state, .initialized)

        // Assert message is nil
        XCTAssertNil(controller.message)
    }

    // MARK: - hasLoadedAllPreviousReplies

    func test_hasLoadedAllPreviousReplies_whenPaginationStateHasLoadedAllPreviousMessages_thenReturnsTrue() {
        // Given
        env.messageUpdater.mockPaginationState.hasLoadedAllPreviousMessages = true

        // When
        let result = controller.hasLoadedAllPreviousReplies

        // Then
        XCTAssertTrue(result)
    }

    func test_hasLoadedAllPreviousReplies_whenPaginationStateHasNotLoadedAllPreviousMessages_thenReturnsFalse() {
        // Given
        env.messageUpdater.mockPaginationState.hasLoadedAllPreviousMessages = false

        // When
        let result = controller.hasLoadedAllPreviousReplies

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - hasLoadedAllNextReplies

    func test_hasLoadedAllNextReplies_whenPaginationStateHasLoadedAllNextMessagesOrRepliesAreEmpty_thenReturnsTrue() throws {
        // Given
        env.messageUpdater.mockPaginationState.hasLoadedAllNextMessages = true
        try saveReplies(with: [MessageId]())

        // When
        let result = controller.hasLoadedAllNextReplies

        // Then
        XCTAssertTrue(result)
    }

    func test_hasLoadedAllNextReplies_whenPaginationStateHasNotLoadedAllNextMessagesAndRepliesAreNotEmpty_thenReturnsFalse() throws {
        // Given
        env.messageUpdater.mockPaginationState.hasLoadedAllNextMessages = false
        try saveReplies(with: [.unique, .unique])

        // When
        let result = controller.hasLoadedAllNextReplies

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - isLoadingPreviousReplies

    func test_isLoadingPreviousReplies_whenPaginationStateIsLoadingPreviousMessages_thenReturnsTrue() {
        // Given
        env.messageUpdater.mockPaginationState.isLoadingPreviousMessages = true

        // When
        let result = controller.isLoadingPreviousReplies

        // Then
        XCTAssertTrue(result)
    }

    func test_isLoadingPreviousReplies_whenPaginationStateIsNotLoadingPreviousMessages_thenReturnsFalse() {
        // Given
        env.messageUpdater.mockPaginationState.isLoadingPreviousMessages = false

        // When
        let result = controller.isLoadingPreviousReplies

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Tests for isLoadingNextReplies

    func test_isLoadingNextReplies_whenPaginationStateIsLoadingNextMessages_thenReturnsTrue() {
        // Given
        env.messageUpdater.mockPaginationState.isLoadingNextMessages = true

        // When
        let result = controller.isLoadingNextReplies

        // Then
        XCTAssertTrue(result)
    }

    func test_isLoadingNextReplies_whenPaginationStateIsNotLoadingNextMessages_thenReturnsFalse() {
        // Given
        env.messageUpdater.mockPaginationState.isLoadingNextMessages = false

        // When
        let result = controller.isLoadingNextReplies

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Tests for isLoadingMiddleReplies

    func test_isLoadingMiddleReplies_whenPaginationStateIsLoadingMiddleMessages_thenReturnsTrue() {
        // Given
        env.messageUpdater.mockPaginationState.isLoadingMiddleMessages = true

        // When
        let result = controller.isLoadingMiddleReplies

        // Then
        XCTAssertTrue(result)
    }

    func test_isLoadingMiddleReplies_whenPaginationStateIsNotLoadingMiddleMessages_thenReturnsFalse() {
        // Given
        env.messageUpdater.mockPaginationState.isLoadingMiddleMessages = false

        // When
        let result = controller.isLoadingMiddleReplies

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Tests for isJumpingToMessage

    func test_isJumpingToMessage_whenPaginationStateIsJumpingToMessage_thenReturnsTrue() {
        // Given
        env.messageUpdater.mockPaginationState.hasLoadedAllNextMessages = false

        // When
        let result = controller.isJumpingToMessage

        // Then
        XCTAssertTrue(result)
    }

    func test_isJumpingToMessage_whenPaginationStateIsNotJumpingToMessage_thenReturnsFalse() {
        // Given
        env.messageUpdater.mockPaginationState.hasLoadedAllNextMessages = true

        // When
        let result = controller.isJumpingToMessage

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Tests for lastOldestReplyId

    func test_lastOldestReplyId_whenPaginationStateHasOldestFetchedMessage_thenReturnsItsId() {
        // Given
        let oldestFetchedMessage = MessagePayload.dummy()
        env.messageUpdater.mockPaginationState.oldestFetchedMessage = oldestFetchedMessage

        // When
        let result = controller.lastOldestReplyId

        // Then
        XCTAssertEqual(result, oldestFetchedMessage.id)
    }

    func test_lastOldestReplyId_whenPaginationStateHasNoOldestFetchedMessage_thenReturnsNil() {
        // Given
        env.messageUpdater.mockPaginationState.oldestFetchedMessage = nil

        // When
        let result = controller.lastOldestReplyId

        // Then
        XCTAssertNil(result)
    }

    // MARK: - Tests for lastNewestReplyId

    func test_lastNewestReplyId_whenPaginationStateHasNewestFetchedMessage_thenReturnsItsId() {
        // Given
        let newestFetchedMessage = MessagePayload.dummy()
        env.messageUpdater.mockPaginationState.newestFetchedMessage = newestFetchedMessage

        // When
        let result = controller.lastNewestReplyId

        // Then
        XCTAssertEqual(result, newestFetchedMessage.id)
    }

    func test_lastNewestReplyId_whenPaginationStateHasNoNewestFetchedMessage_thenReturnsNil() {
        // Given
        env.messageUpdater.mockPaginationState.newestFetchedMessage = nil

        // When
        let result = controller.lastNewestReplyId

        // Then
        XCTAssertNil(result)
    }

    // MARK: - Synchronize

    func test_synchronize_forwardsUpdaterError() throws {
        // Simulate `synchronize` call
        var completionError: Error?
        controller.synchronize {
            completionError = $0
        }

        // Simulate network response with the error
        let networkError = TestError()
        env.messageUpdater.getMessage_completion?(.failure(networkError))

        AssertAsync {
            // Assert network error is propagated
            Assert.willBeEqual(completionError as? TestError, networkError)
            // Assert network error is propagated
            Assert.willBeEqual(self.controller.state, .remoteDataFetchFailed(ClientError(with: networkError)))
        }
    }

    func test_synchronize_changesStateCorrectly_ifNoErrorsHappen() throws {
        // Simulate `synchronize` call
        var completionError: Error?
        var completionCalled = false
        controller.synchronize {
            completionError = $0
            completionCalled = true
        }

        // Assert controller is in `localDataFetched` state
        XCTAssertEqual(controller.state, .localDataFetched)

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate network response with the error
        env.messageUpdater.getMessage_completion?(.success(ChatMessage.unique))
        // Release reference of completion so we can deallocate stuff
        env.messageUpdater.getMessage_completion = nil

        AssertAsync {
            // Assert completion is called
            Assert.willBeTrue(completionCalled)
            // Assert completion is called without any error
            Assert.staysTrue(completionError == nil)
        }
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_messageIsUpToDate_withoutSynchronizeCall() throws {
        // Assert message is `nil` initially and start observing DB
        XCTAssertNil(controller.message)

        let messageLocalText: String = .unique

        // Create current user in the database
        try client.databaseContainer.createCurrentUser(id: currentUserId)

        // Create message in that matches controller's `messageId`
        try client.databaseContainer.createMessage(id: messageId, authorId: currentUserId, cid: cid, text: messageLocalText)

        // Assert message is fetched from the database and has correct field values
        var message = try XCTUnwrap(controller.message)
        XCTAssertEqual(message.id, messageId)
        XCTAssertEqual(message.text, messageLocalText)

        // Simulate response from the backend with updated `text`, update the local message in the databse
        let messagePayload: MessagePayload = .dummy(
            messageId: messageId,
            authorUserId: currentUserId,
            text: .unique
        )
        try client.databaseContainer.writeSynchronously { session in
            try session.saveMessage(payload: messagePayload, for: self.cid, syncOwnReactions: true, cache: nil)
        }

        // Assert the controller's `message` is up-to-date
        message = try XCTUnwrap(controller.message)
        XCTAssertEqual(message.id, messageId)
        XCTAssertEqual(message.text, messagePayload.text)
    }

    /// This test simulates a bug where the `message` and `replies` fields were not updated if they weren't
    /// touched before calling synchronize.
    func test_messagesAreFetched_afterCallingSynchronize() throws {
        // Simulate `synchronize` call
        controller.synchronize()

        // Create the message and replies in the DB
        let expectedReplies: [MessageId] = [.unique, .unique, .unique, .unique, .unique]
        try saveReplies(with: expectedReplies)

        // Simulate updater completion call
        env.messageUpdater.getMessage_completion?(.success(ChatMessage.unique))

        XCTAssertEqual(controller.message?.id, messageId)
        XCTAssertEqual(controller.replies.count, expectedReplies.count)
    }

    // MARK: - Order

    func test_replies_haveCorrectOrder() throws {
        let reply1: MessagePayload = .dummy(
            messageId: .unique,
            parentId: messageId,
            showReplyInChannel: false,
            authorUserId: .unique
        )

        let reply2: MessagePayload = .dummy(
            messageId: .unique,
            parentId: messageId,
            showReplyInChannel: false,
            authorUserId: .unique
        )
        try saveReplies(with: [reply1, reply2])

        // Set top-to-bottom ordering
        controller.listOrdering = .topToBottom

        // Check the order of replies is correct
        let topToBottomIds = [reply1, reply2].sorted { $0.createdAt > $1.createdAt }.map(\.id)
        XCTAssertEqual(controller.replies.map(\.id), topToBottomIds)

        // Set bottom-to-top ordering
        controller.listOrdering = .bottomToTop

        // Check the order of replies is correct
        let bottomToTopIds = [reply1, reply2].sorted { $0.createdAt < $1.createdAt }.map(\.id)
        XCTAssertEqual(controller.replies.map(\.id), bottomToTopIds)
    }

    /// This test was added because we forgot to exclude deleted messages when fetching replies.
    /// Valid message for a thread is defined as:
    /// - `parentId` correctly set,
    /// - is not deleted, or current user owned non-ephemeral deleted,
    /// - newer than channel's truncation date (if channel is truncated)
    func test_replies_onlyIncludeValidMessages() throws {
        // Create dummy channel
        let truncatedDate = Date.unique
        let channel = dummyPayload(with: cid, truncatedAt: truncatedDate)

        // Set the deleted messages visibility to hide the message
        var config = ChatClient.defaultMockedConfig
        config.deletedMessagesVisibility = .alwaysHidden
        client = ChatClient_Mock(config: config)
        controller = ChatMessageController(client: client, cid: cid, messageId: messageId, environment: env.controllerEnvironment)

        let reply1: MessagePayload = .dummy(
            messageId: .unique,
            parentId: messageId,
            showReplyInChannel: false,
            authorUserId: .unique,
            createdAt: .unique(after: truncatedDate)
        )

        let createdAt = Date.unique(after: truncatedDate)
        let reply2: MessagePayload = .dummy(
            messageId: .unique,
            parentId: messageId,
            showReplyInChannel: false,
            authorUserId: .unique,
            createdAt: createdAt,
            deletedAt: .unique(after: createdAt)
        )

        // Insert 3rd reply before truncation date
        let reply3: MessagePayload = .dummy(
            messageId: .unique,
            parentId: messageId,
            showReplyInChannel: false,
            authorUserId: .unique,
            createdAt: .unique(before: truncatedDate)
        )

        // Save messages
        try saveReplies(with: [reply1, reply2, reply3], channelPayload: channel)

        // Check if the replies are correct
        let ids = [reply1].map(\.id)
        XCTAssertEqual(controller.replies.map(\.id), ids)
    }

    func test_replies_withVisibleForCurrentUser_messageVisibility() throws {
        let channel = dummyPayload(with: cid)
        let truncatedDate = Date.unique

        try client.databaseContainer.createCurrentUser(id: currentUserId)
        client.databaseContainer.viewContext.deletedMessagesVisibility = .visibleForCurrentUser
        controller = ChatMessageController(client: client, cid: cid, messageId: messageId, environment: env.controllerEnvironment)

        // Insert own deleted reply
        let ownReply: MessagePayload = .dummy(
            messageId: .unique,
            parentId: messageId,
            showReplyInChannel: false,
            authorUserId: currentUserId,
            createdAt: .unique(after: truncatedDate),
            deletedAt: .unique(after: truncatedDate)
        )

        // Insert deleted reply by another user
        let createdAt = Date.unique(after: truncatedDate)
        let otherReply: MessagePayload = .dummy(
            messageId: .unique,
            parentId: messageId,
            showReplyInChannel: false,
            authorUserId: .unique,
            createdAt: createdAt,
            deletedAt: .unique(after: createdAt)
        )

        try saveReplies(with: [ownReply, otherReply], channelPayload: channel)

        // Only own reply should be visible
        XCTAssertEqual(controller.replies.map(\.id), [ownReply.id])
    }

    func test_replies_withAlwaysHidden_messageVisibility() throws {
        // Create dummy channel
        let channel = dummyPayload(with: cid)
        let truncatedDate = Date.unique

        try client.databaseContainer.createCurrentUser(id: currentUserId)
        client.databaseContainer.viewContext.deletedMessagesVisibility = .alwaysHidden
        controller = ChatMessageController(client: client, cid: cid, messageId: messageId, environment: env.controllerEnvironment)

        // Save channel
        try client.databaseContainer.writeSynchronously {
            let dto = try $0.saveChannel(payload: channel)
            dto.truncatedAt = truncatedDate.bridgeDate
        }

        // Insert parent message
        try client.databaseContainer.createMessage(id: messageId, authorId: .unique, cid: cid, text: "Parent")

        // Insert own deleted reply
        let ownReply: MessagePayload = .dummy(
            messageId: .unique,
            parentId: messageId,
            showReplyInChannel: false,
            authorUserId: currentUserId,
            createdAt: .unique(after: truncatedDate),
            deletedAt: .unique(after: truncatedDate)
        )

        // Insert deleted reply by another user
        let createdAt = Date.unique(after: truncatedDate)
        let otherReply: MessagePayload = .dummy(
            messageId: .unique,
            parentId: messageId,
            showReplyInChannel: false,
            authorUserId: .unique,
            createdAt: createdAt,
            deletedAt: .unique(after: createdAt)
        )

        try saveReplies(with: [ownReply, otherReply])

        // both deleted replies should be hidden
        XCTAssertTrue(controller.replies.isEmpty)
    }

    func test_replies_withAlwaysVisible_messageVisibility() throws {
        // Create dummy channel
        let channel = dummyPayload(with: cid)
        let truncatedDate = Date.unique

        try client.databaseContainer.createCurrentUser(id: currentUserId)
        client.databaseContainer.viewContext.deletedMessagesVisibility = .alwaysVisible
        controller = ChatMessageController(client: client, cid: cid, messageId: messageId, environment: env.controllerEnvironment)

        // Save channel
        try client.databaseContainer.writeSynchronously {
            let dto = try $0.saveChannel(payload: channel)
            dto.truncatedAt = truncatedDate.bridgeDate
        }

        // Insert parent message
        try client.databaseContainer.createMessage(id: messageId, authorId: .unique, cid: cid, text: "Parent")

        // Insert own deleted reply
        let ownReply: MessagePayload = .dummy(
            messageId: .unique,
            parentId: messageId,
            showReplyInChannel: false,
            authorUserId: currentUserId,
            createdAt: .unique(after: truncatedDate),
            deletedAt: .unique(after: truncatedDate)
        )

        // Insert deleted reply by another user
        let createdAt = Date.unique(after: truncatedDate)
        let otherReply: MessagePayload = .dummy(
            messageId: .unique,
            parentId: messageId,
            showReplyInChannel: false,
            authorUserId: .unique,
            createdAt: createdAt,
            deletedAt: .unique(after: createdAt)
        )

        // Save messages
        try saveReplies(with: [ownReply, otherReply])

        // both deleted replies should be visible
        XCTAssertEqual(Set(controller.replies.map(\.id)), Set([ownReply.id, otherReply.id]))
    }

    func test_replies_whenShadowedMessagesVisible() throws {
        // Create dummy channel
        let channel = dummyPayload(with: cid)
        let truncatedDate = Date.unique

        try client.databaseContainer.createCurrentUser(id: currentUserId)
        client.databaseContainer.viewContext.shouldShowShadowedMessages = true
        controller = ChatMessageController(client: client, cid: cid, messageId: messageId, environment: env.controllerEnvironment)

        // Save channel
        try client.databaseContainer.writeSynchronously {
            let dto = try $0.saveChannel(payload: channel)
            dto.truncatedAt = truncatedDate.bridgeDate
        }

        // Insert parent message
        try client.databaseContainer.createMessage(id: messageId, authorId: .unique, cid: cid, text: "Parent")

        // Insert a reply
        let nonShadowedReply: MessagePayload = .dummy(
            messageId: .unique,
            parentId: messageId,
            showReplyInChannel: false,
            authorUserId: .unique,
            createdAt: .unique(after: truncatedDate),
            isShadowed: false
        )

        // Insert shadowed reply by another user
        let createdAt = Date.unique(after: truncatedDate)
        let shadowedReply: MessagePayload = .dummy(
            messageId: .unique,
            parentId: messageId,
            showReplyInChannel: false,
            authorUserId: .unique,
            createdAt: createdAt,
            isShadowed: true
        )

        // Save messages
        try saveReplies(with: [nonShadowedReply, shadowedReply])

        // all replies should be visible
        XCTAssertEqual(Set(controller.replies.map(\.id)), Set([nonShadowedReply.id, shadowedReply.id]))
    }

    func test_replies_withDefaultShadowedMessagesVisible() throws {
        // Create dummy channel
        let channel = dummyPayload(with: cid)
        let truncatedDate = Date.unique

        try client.databaseContainer.createCurrentUser(id: currentUserId)

        // Save channel
        try client.databaseContainer.writeSynchronously {
            let dto = try $0.saveChannel(payload: channel)
            dto.truncatedAt = truncatedDate.bridgeDate
        }

        // Insert parent message
        try client.databaseContainer.createMessage(id: messageId, authorId: .unique, cid: cid, text: "Parent")

        // Insert a reply
        let nonShadowedReply: MessagePayload = .dummy(
            messageId: .unique,
            parentId: messageId,
            showReplyInChannel: false,
            authorUserId: .unique,
            createdAt: .unique(after: truncatedDate),
            isShadowed: false
        )

        // Insert shadowed reply by another user
        let createdAt = Date.unique(after: truncatedDate)
        let shadowedReply: MessagePayload = .dummy(
            messageId: .unique,
            parentId: messageId,
            showReplyInChannel: false,
            authorUserId: .unique,
            createdAt: createdAt,
            isShadowed: true
        )

        try saveReplies(with: [nonShadowedReply, shadowedReply])

        // only non-shadowed reply should be visible
        XCTAssertEqual(Set(controller.replies.map(\.id)), Set([nonShadowedReply.id]))
    }

    // MARK: - Delegate

    func test_delegate_isAssignedCorrectly() {
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)

        // Set the delegate
        controller.delegate = delegate

        // Assert the delegate is assigned correctly
        XCTAssert(controller.delegate === delegate)
    }

    func test_settingDelegate_leadsToFetchingLocalDataa() {
        // Check initial state
        XCTAssertEqual(controller.state, .initialized)

        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        // Assert state changed
        AssertAsync.willBeEqual(controller.state, .localDataFetched)
    }

    func test_delegate_isNotifiedAboutStateChanges() throws {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)

        // Synchronize
        controller.synchronize()

        // Simulate network call response
        env.messageUpdater.getMessage_completion?(.success(ChatMessage.unique))

        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .remoteDataFetched)
    }

    func test_delegate_isNotifiedAboutCreatedMessage() throws {
        // Create current user in the database
        try client.databaseContainer.createCurrentUser(id: currentUserId)

        // Create channel in the database
        try client.databaseContainer.createChannel(cid: cid)

        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        // Simulate `synchronize` call
        controller.synchronize()

        // Simulate response from a backend with a message that doesn't exist locally
        let messagePayload: MessagePayload = .dummy(
            messageId: messageId,
            authorUserId: currentUserId
        )
        try client.databaseContainer.writeSynchronously { session in
            try session.saveMessage(payload: messagePayload, for: self.cid, syncOwnReactions: true, cache: nil)
        }
        env.messageUpdater.getMessage_completion?(.success(ChatMessage.unique))

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
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        // Simulate `synchronize` call
        controller.synchronize()

        // Simulate response from a backend with a message that exists locally but has out-dated text
        let messagePayload: MessagePayload = .dummy(
            messageId: messageId,
            authorUserId: currentUserId,
            text: "new text"
        )
        try client.databaseContainer.writeSynchronously { session in
            try session.saveMessage(payload: messagePayload, for: self.cid, syncOwnReactions: true, cache: nil)
        }
        env.messageUpdater.getMessage_completion?(.success(ChatMessage.unique))

        // Assert `update` entity change is received by the delegate
        AssertAsync {
            Assert.willBeEqual(delegate.didChangeMessage_change?.fieldChange(\.id), .update(messagePayload.id))
            Assert.willBeEqual(delegate.didChangeMessage_change?.fieldChange(\.text), .update(messagePayload.text))
        }
    }

    func test_delegate_isNotifiedAboutRepliesChanges() throws {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        // Simulate `synchronize` call
        controller.synchronize()

        // Add reply to DB
        let replyId = MessageId.unique
        try saveReplies(with: [replyId])

        var replyModel: ChatMessage?
        try client.databaseContainer.writeSynchronously { session in
            guard let reply = session.message(id: replyId) else { return }
            replyModel = try reply.asModel()
        }

        // Assert `insert` entity change is received by the delegate
        AssertAsync.willBeEqual(
            delegate.didChangeReplies_changes,
            [.insert(replyModel!, index: [0, 0])]
        )
    }

    func test_delegate_isNotifiedAboutReactionChanges() throws {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        controller.reactions = [.mock(type: "like")]

        AssertAsync.willBeEqual(
            delegate.didChangeReactions_reactions.map(\.type),
            [ChatMessageReaction.mock(type: "like").type]
        )
    }

    // MARK: - Delete message

    func test_deleteMessage_propagatesError() {
        // Simulate `deleteMessage` call and catch the completion
        var completionError: Error?
        controller.deleteMessage { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate network response with the error
        let networkError = TestError()
        env.messageUpdater.deleteMessage_completion?(networkError)

        // Assert error is propagated
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }

    func test_deleteMessage_propagatesNilError() {
        // Simulate `deleteMessage` call and catch the completion
        var completionCalled = false
        controller.deleteMessage { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil($0)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate successful network response
        env.messageUpdater.deleteMessage_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.messageUpdater.deleteMessage_completion = nil

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_deleteMessage_whenHardIsFalse_callsMessageUpdater_withCorrectValues() {
        // Simulate `deleteMessage` call
        controller.deleteMessage(hard: false)

        // Assert messageUpdater is called with correct `messageId`
        XCTAssertEqual(env.messageUpdater.deleteMessage_messageId, controller.messageId)
        XCTAssertEqual(env.messageUpdater.deleteMessage_hard, false)
    }

    func test_deleteMessage_whenHardIsTrue_callsMessageUpdater_withCorrectValues() {
        // Simulate `deleteMessage` call
        controller.deleteMessage(hard: true)

        // Assert messageUpdater is called with correct `messageId`
        XCTAssertEqual(env.messageUpdater.deleteMessage_messageId, controller.messageId)
        XCTAssertEqual(env.messageUpdater.deleteMessage_hard, true)
    }

    // MARK: - Edit message

    func test_editMessage_propagatesError() {
        // Simulate `editMessage` call and catch the completion
        var completionError: Error?
        controller.editMessage(text: .unique) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate network response with the error
        let networkError = TestError()
        env.messageUpdater.editMessage_completion?(networkError)

        // Assert error is propagated
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }

    func test_editMessage_propagatesNilError() {
        // Simulate `editMessage` call and catch the completion
        var completionCalled = false
        controller.editMessage(text: .unique) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil($0)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate successful network response
        env.messageUpdater.editMessage_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.messageUpdater.editMessage_completion = nil

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_editMessage_callsMessageUpdater_withCorrectValues() {
        let updatedText: String = .unique

        // Simulate `editMessage` call and catch the completion
        controller.editMessage(text: updatedText, skipEnrichUrl: true)

        // Assert message updater is called with correct `messageId` and `text`
        XCTAssertEqual(env.messageUpdater.editMessage_messageId, controller.messageId)
        XCTAssertEqual(env.messageUpdater.editMessage_text, updatedText)
        XCTAssertEqual(env.messageUpdater.editMessage_skipEnrichUrl, true)
    }

    func test_editMessage_callsMessageUpdater_withCorrectExtraParameters() {
        let updatedText: String = .unique
        let attachments = [AnyAttachmentPayload.mockAudio]
        let extraData: [String: RawJSON] = ["myKey": .string("myValue")]

        // Simulate `editMessage` call and catch the completion
        controller.editMessage(
            text: updatedText,
            attachments: attachments,
            extraData: extraData
        )

        // Assert message updater is called with correct `messageId` and `text`
        XCTAssertEqual(env.messageUpdater.editMessage_text, updatedText)
        XCTAssertEqual(env.messageUpdater.editMessage_attachments, attachments)
        XCTAssertEqual(env.messageUpdater.editMessage_extraData, extraData)
    }

    // MARK: - Flag message

    func test_flag_propagatesError() {
        // Simulate `flag` call and catch the completion.
        var completionError: Error?
        controller.flag { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate network response with the error.
        let networkError = TestError()
        env.messageUpdater.flagMessage_completion!(networkError)

        // Assert error is propagated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }

    func test_flag_propagatesNilError() {
        // Simulate `flag` call and catch the completion.
        var completionIsCalled = false
        controller.flag { [callbackQueueID] error in
            // Assert callback queue is correct.
            AssertTestQueue(withId: callbackQueueID)
            // Assert there is no error.
            XCTAssertNil(error)
            completionIsCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate successful network response.
        env.messageUpdater.flagMessage_completion!(nil)
        // Release reference of completion so we can deallocate stuff
        env.messageUpdater.flagMessage_completion = nil

        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_flag_callsUpdater_withCorrectValues() {
        // Simulate `flag` call.
        controller.flag()

        // Assert updater is called with correct `flag`.
        XCTAssertEqual(env.messageUpdater.flagMessage_flag, true)
        // Assert updater is called with correct `messageId`.
        XCTAssertEqual(env.messageUpdater.flagMessage_messageId, controller.messageId)
        // Assert updater is called with correct `cid`.
        XCTAssertEqual(env.messageUpdater.flagMessage_cid, controller.cid)
    }

    func test_flag_keepsControllerAlive() {
        // Simulate `flag` call.
        controller.flag()

        // Create a weak ref and release a controller.
        weak var weakController = controller
        controller = nil

        // Assert controller is kept alive.
        AssertAsync.staysTrue(weakController != nil)
    }

    // MARK: - Unflag message

    func test_unflag_propagatesError() {
        // Simulate `unflag` call and catch the completion.
        var completionError: Error?
        controller.unflag { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate network response with the error.
        let networkError = TestError()
        env.messageUpdater.flagMessage_completion!(networkError)

        // Assert error is propagated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }

    func test_unflag_propagatesNilError() {
        // Simulate `unflag` call and catch the completion.
        var completionIsCalled = false
        controller.unflag { [callbackQueueID] error in
            // Assert callback queue is correct.
            AssertTestQueue(withId: callbackQueueID)
            // Assert there is no error.
            XCTAssertNil(error)
            completionIsCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate successful network response.
        env.messageUpdater.flagMessage_completion!(nil)
        // Release reference of completion so we can deallocate stuff
        env.messageUpdater.flagMessage_completion = nil

        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_unflag_callsUpdater_withCorrectValues() {
        // Simulate `unflag` call.
        controller.unflag()

        // Assert updater is called with correct `flag`.
        XCTAssertEqual(env.messageUpdater.flagMessage_flag, false)
        // Assert updater is called with correct `messageId`.
        XCTAssertEqual(env.messageUpdater.flagMessage_messageId, controller.messageId)
        // Assert updater is called with correct `cid`.
        XCTAssertEqual(env.messageUpdater.flagMessage_cid, controller.cid)
    }

    // MARK: - Create new reply

    func test_createNewReply_callsMessageUpdater() {
        let newMessage = ChatMessage.mock()

        // New message values
        let text: String = .unique
        let showReplyInChannel = true
        let quotedMessageId: MessageId = .unique
        let extraData: [String: RawJSON] = [:]
        let attachments: [AnyAttachmentPayload] = [.mockFile, .mockImage, .init(payload: TestAttachmentPayload.unique)]
        let pin = MessagePinning(expirationDate: .unique)
        let skipPush = true
        let skipEnrichUrl = false

        // Simulate `createNewReply` calls and catch the completion
        var completionCalled = false
        controller.createNewReply(
            text: text,
            pinning: pin,
            attachments: attachments,
            showReplyInChannel: showReplyInChannel,
            quotedMessageId: quotedMessageId,
            skipPush: skipPush,
            skipEnrichUrl: skipEnrichUrl,
            extraData: extraData
        ) { [callbackQueueID] result in
            AssertTestQueue(withId: callbackQueueID)
            AssertResultSuccess(result, newMessage.id)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        XCTAssertEqual(env.messageUpdater.createNewReply_cid, cid)
        XCTAssertEqual(env.messageUpdater.createNewReply_text, text)
        //        XCTAssertEqual(env.channelUpdater?.createNewMessage_command, command)
        //        XCTAssertEqual(env.channelUpdater?.createNewMessage_arguments, arguments)
        XCTAssertEqual(env.messageUpdater.createNewReply_parentMessageId, messageId)
        XCTAssertEqual(env.messageUpdater.createNewReply_showReplyInChannel, showReplyInChannel)
        XCTAssertEqual(env.messageUpdater.createNewReply_extraData, extraData)
        XCTAssertEqual(env.messageUpdater.createNewReply_attachments, attachments)
        XCTAssertEqual(env.messageUpdater.createNewReply_skipPush, skipPush)
        XCTAssertEqual(env.messageUpdater.createNewReply_skipEnrichUrl, skipEnrichUrl)
        XCTAssertEqual(env.messageUpdater.createNewReply_quotedMessageId, quotedMessageId)

        // Simulate successful update
        env.messageUpdater.createNewReply_completion?(.success(newMessage))
        // Release reference of completion so we can deallocate stuff
        env.messageUpdater.createNewReply_completion = nil

        // Pin
        XCTAssertEqual(env.messageUpdater.createNewReply_pinning, pin)

        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_createNewReply_sendsNewMessagePendingEvent() throws {
        let exp = expectation(description: "should complete create new message")

        let mockedEventNotificationCenter = EventNotificationCenter_Mock(database: .init(kind: .inMemory))
        client.mockedEventNotificationCenter = mockedEventNotificationCenter

        controller.createNewReply(
            text: .unique
        ) { _ in
            exp.fulfill()
        }

        env.messageUpdater?.createNewReply_completion?(.success(.unique))

        wait(for: [exp], timeout: defaultTimeout)

        let event = try XCTUnwrap(mockedEventNotificationCenter.mock_process.calls.first?.0.first)
        XCTAssertTrue(event is NewMessagePendingEvent)
    }

    // MARK: - Load replies

    func test_loadPreviousReplies_propagatesError() {
        // Simulate `loadPreviousReplies` call and catch the completion
        var completionError: Error?
        controller.loadPreviousReplies { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate network response with the error
        let networkError = TestError()
        env.messageUpdater.loadReplies_completion?(.failure(networkError))

        // Assert error is propagated
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }

    func test_loadPreviousReplies_propagatesNilError() {
        // Simulate `loadPreviousReplies` call and catch the completion
        var completionCalled = false
        controller.loadPreviousReplies { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil($0)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate successful network response
        env.messageUpdater.loadReplies_completion?(.success(MessageRepliesPayload(messages: [])))
        // Release reference of completion so we can deallocate stuff
        env.messageUpdater.loadReplies_completion = nil

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_loadPreviousReplies_callsMessageUpdater_withCorrectValues() {
        controller.loadPreviousReplies()

        // Assert message updater is called with correct values
        XCTAssertEqual(env.messageUpdater.loadReplies_cid, controller.cid)
        XCTAssertEqual(env.messageUpdater.loadReplies_messageId, messageId)
        XCTAssertEqual(env.messageUpdater.loadReplies_pagination, .init(pageSize: 25))
    }

    func test_loadPreviousReplies_noMessageIdPassed_noLastMessageFetched_fetchWithoutParemeter() {
        _ = controller.replies
        env.repliesObserver.items_mock = [
            .mock(
                id: "first message", cid: .unique, text: .unique, author: .unique
            ),
            .mock(
                id: "last message", cid: .unique, text: .unique, author: .unique
            ),
            // The last message used for pagination, needs to be in the server as well,
            // so this one should not be used
            .mock(
                id: "last message only local", cid: .unique, text: .unique, author: .unique, localState: .pendingSync
            )
        ]

        controller.loadPreviousReplies(
            limit: 21,
            completion: nil
        )

        XCTAssertEqual(env.messageUpdater.loadReplies_pagination, .init(pageSize: 21))
        XCTAssertEqual(env.messageUpdater.loadReplies_pagination?.parameter, nil)
    }

    func test_loadPreviousReplies_noMessageIdPassed_usesLastFetchedId() {
        let lastFetchedId = MessageId.unique
        env.messageUpdater.mockPaginationState.oldestFetchedMessage = .dummy(messageId: lastFetchedId)

        controller.loadPreviousReplies(
            limit: 21,
            completion: nil
        )

        XCTAssertEqual(
            env.messageUpdater.loadReplies_pagination?.parameter,
            .lessThan(lastFetchedId)
        )
    }

    func test_loadPreviousReplies_messageIdPassed_properlyHandlesPagination() {
        controller.loadPreviousReplies(
            before: "last message",
            limit: 21,
            completion: nil
        )

        XCTAssertEqual(
            env.messageUpdater.loadReplies_pagination?.parameter,
            .lessThan("last message")
        )
    }

    func test_loadPreviousReplies_whenHasLoadedAllPreviousReplies_doesNotCallUpdater() throws {
        env.messageUpdater.mockPaginationState.hasLoadedAllPreviousMessages = true

        let exp = expectation(description: "load replies completes")
        controller.loadPreviousReplies(before: "last message", limit: 2) { _ in
            exp.fulfill()
        }

        env.messageUpdater.loadReplies_completion?(.success(.init(messages: [.dummy()])))
        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(env.messageUpdater.loadReplies_callCount, 0)
    }

    func test_loadPreviousReplies_whenIsLoadingPreviousReplies_doesNotCallUpdater() throws {
        env.messageUpdater.mockPaginationState.isLoadingPreviousMessages = true

        let exp = expectation(description: "load replies completes")
        controller.loadPreviousReplies(before: "last message", limit: 2) { _ in
            exp.fulfill()
        }

        env.messageUpdater.loadReplies_completion?(.success(.init(messages: [.dummy()])))
        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(env.messageUpdater.loadReplies_callCount, 0)
    }

    func test_loadPreviousReplies_whenMessagesAreEmpty_callDelegateWithEmptyChanges() {
        let exp = expectation(description: "load replies completes")
        controller.loadPreviousReplies(before: "last message", limit: 2) { _ in
            exp.fulfill()
        }

        class MockTestDelegate: ChatMessageControllerDelegate {
            var callCount = 0
            func messageController(_ controller: ChatMessageController, didChangeReplies changes: [ListChange<ChatMessage>]) {
                callCount += 1
            }
        }

        let testDelegate = MockTestDelegate()
        controller.delegate = testDelegate

        env.messageUpdater.loadReplies_completion?(.success(.init(messages: [])))
        waitForExpectations(timeout: defaultTimeout)
        
        XCTAssertEqual(env.messageUpdater.loadReplies_callCount, 1)
        // It should call the didChangeReplies with empty changes
        // in order to add the parent message to the list again.
        XCTAssertEqual(testDelegate.callCount, 1)
    }

    // MARK: - Load Next Replies

    func test_loadNextReplies_propagatesError() throws {
        // Simulate controller is in mid-page
        try saveReplies(with: [.unique, .unique])
        env.messageUpdater.mockPaginationState.hasLoadedAllNextMessages = false

        // Simulate `loadNextReplies` call and catch the completion
        var completionError: Error?
        controller.loadNextReplies(after: .unique) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate network response with the error
        let networkError = TestError()
        env.messageUpdater.loadReplies_completion?(.failure(networkError))

        // Assert error is propagated
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }

    func test_loadNextReplies_propagatesNilError() throws {
        // Simulate controller is in mid-page
        try saveReplies(with: [.unique, .unique])
        env.messageUpdater.mockPaginationState.hasLoadedAllNextMessages = false

        // Simulate `loadNextReplies` call and catch the completion
        var completionCalled = false
        controller.loadNextReplies(after: .unique) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil($0)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate successful network response
        env.messageUpdater.loadReplies_completion?(.success(MessageRepliesPayload(messages: [])))
        // Release reference of completion so we can deallocate stuff
        env.messageUpdater.loadReplies_completion = nil

        // Clean message updater
        env.messageUpdater.cleanUp()

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_loadNextReplies_callsMessageUpdater_withCorrectValues() throws {
        // Simulate controller is in mid-page
        try saveReplies(with: [.unique, .unique])
        env.messageUpdater.mockPaginationState.hasLoadedAllNextMessages = false

        // Simulate `loadNextReplies` call
        let afterMessageId: MessageId = .unique
        controller.loadNextReplies(after: afterMessageId)

        // Assert message updater is called with correct values
        XCTAssertEqual(env.messageUpdater.loadReplies_cid, controller.cid)
        XCTAssertEqual(env.messageUpdater.loadReplies_messageId, messageId)
        XCTAssertEqual(env.messageUpdater.loadReplies_pagination, .init(pageSize: 25, parameter: .greaterThan(afterMessageId)))
    }

    func test_loadNextReplies_whenHasLoadedAllNextReplies_doesNotCallUpdater() throws {
        // Simulate controller has loaded all next replies
        try saveReplies(with: [.unique, .unique])
        env.messageUpdater.mockPaginationState.hasLoadedAllNextMessages = true

        let exp = expectation(description: "load replies completes")
        controller.loadNextReplies(after: "last message", limit: 2) { _ in
            exp.fulfill()
        }

        env.messageUpdater.loadReplies_completion?(.success(.init(messages: [.dummy()])))
        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(env.messageUpdater.loadReplies_callCount, 0)
    }

    func test_loadNextReplies_whenIsLoadingNextReplies_doesNotCallUpdater() throws {
        // Simulate controller is loading next replies
        try saveReplies(with: [.unique, .unique])
        env.messageUpdater.mockPaginationState.hasLoadedAllNextMessages = false
        env.messageUpdater.mockPaginationState.isLoadingNextMessages = true

        let exp = expectation(description: "load replies completes")
        controller.loadNextReplies(after: "last message", limit: 2) { _ in
            exp.fulfill()
        }

        env.messageUpdater.loadReplies_completion?(.success(.init(messages: [.dummy()])))
        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(env.messageUpdater.loadReplies_callCount, 0)
    }

    // MARK: - Load Page Around Reply Id

    func test_loadPageAroundReplyId() {
        let exp = expectation(description: "should load page around reply id")
        let replyId = MessageId.unique
        controller.loadPageAroundReplyId(replyId, limit: 5) { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        env.messageUpdater.loadReplies_completion?(.success(.init(
            messages: [.dummy(), .dummy(), .dummy()]
        )))

        waitForExpectations(timeout: defaultTimeout)

        let expectedPagination = MessagesPagination(pageSize: 5, parameter: .around(replyId))
        XCTAssertEqual(env.messageUpdater.loadReplies_callCount, 1)
        XCTAssertEqual(env.messageUpdater.loadReplies_pagination, expectedPagination)
    }

    func test_loadPageAroundReplyId_whenError_shouldCompleteWithError() {
        let exp = expectation(description: "should load page around reply id")
        let replyId = MessageId.unique
        controller.loadPageAroundReplyId(replyId, limit: 5) { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        }

        env.messageUpdater.loadReplies_completion?(.failure(NSError(domain: "dummy", code: 3)))

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(env.messageUpdater.loadReplies_callCount, 1)
    }

    func test_loadPageAroundReplyId_whenIsLoadingMiddleMessages_shouldNotLoadMoreReplies() {
        // Simulate controller is loading middle messages
        env.messageUpdater.mockPaginationState.isLoadingMiddleMessages = true

        let exp = expectation(description: "should load page around reply id")
        let replyId = MessageId.unique
        controller.loadPageAroundReplyId(replyId, limit: 5) { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        let oldestReply = MessagePayload.dummy()
        let newestReply = MessagePayload.dummy()
        env.messageUpdater.loadReplies_completion?(.success(.init(
            messages: [oldestReply, .dummy(), newestReply]
        )))

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(env.messageUpdater.loadReplies_callCount, 0)
    }

    // MARK: - Load first page

    func test_loadFirstPage_loadsFirstPageOfReplies() throws {
        let firstPage = MessagesPagination(pageSize: 25, parameter: nil)

        let exp = expectation(description: "load first page completes")
        controller.loadFirstPage() { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        env.messageUpdater.loadReplies_completion?(.success(.init(messages: [.dummy()])))

        waitForExpectations(timeout: defaultTimeout)

        // Assert message updater is called with correct values
        XCTAssertEqual(env.messageUpdater.loadReplies_cid, controller.cid)
        XCTAssertEqual(env.messageUpdater.loadReplies_messageId, messageId)
        XCTAssertEqual(env.messageUpdater.loadReplies_pagination, firstPage)
    }

    func test_loadFirstPage_whenError() throws {
        let exp = expectation(description: "load first page completes")
        var expectedError: Error?
        controller.loadFirstPage() { error in
            expectedError = error
            exp.fulfill()
        }

        env.messageUpdater.loadReplies_completion?(.failure(NSError(domain: "dummy", code: 3)))

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertNotNil(expectedError)
    }

    // MARK: - Load Reactions

    func test_reactions_shouldReturnLatestReactionsWhenObserversStarts() throws {
        try client.databaseContainer.createCurrentUser(id: currentUserId)

        var mockedReactions: [MessageReactionPayload] = []

        for _ in (0..<20) {
            mockedReactions.append(MessageReactionPayload.dummy(
                messageId: messageId,
                user: .dummy(userId: .unique)
            ))
        }

        try client.databaseContainer.createMessage(
            id: messageId,
            authorId: currentUserId,
            cid: cid,
            text: .unique,
            latestReactions: mockedReactions
        )

        let expectedLatestReactions = mockedReactions
            .sorted(by: { $0.updatedAt > $1.updatedAt })

        controller.startObserversIfNeeded()

        XCTAssertEqual(controller.reactions.count, 20)
        XCTAssertEqual(
            controller.reactions.map(\.author).map(\.id),
            expectedLatestReactions.map(\.user).map(\.id)
        )
    }

    func test_loadReactions_propagatesError() {
        var completionError: Error?
        controller.loadReactions(limit: 25) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0.error
        }

        // Simulate network response with the error
        let networkError = TestError()
        env.messageUpdater.loadReactions_completion?(.failure(networkError))

        // Assert error is propagated
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }

    func test_loadReactions_propagatesReactions() {
        var completionCalled = false
        controller.loadReactions(limit: 25) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            let reactions = try? $0.get()
            XCTAssertEqual(reactions!.count, 1)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate successful network response
        env.messageUpdater.loadReactions_completion?(.success([.mock(type: "like")]))
        // Release reference of completion so we can deallocate stuff
        env.messageUpdater.loadReactions_completion = nil

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_loadReactions_callsMessageUpdater_withCorrectValues() {
        controller.loadReactions(limit: 25, offset: 15) { _ in }

        XCTAssertEqual(env.messageUpdater.loadReactions_cid, cid)
        XCTAssertEqual(env.messageUpdater.loadReactions_messageId, messageId)
        XCTAssertEqual(env.messageUpdater.loadReactions_pagination, .init(pageSize: 25, offset: 15))
    }

    func test_loadNextReactions_whenAllReactionsLoaded_doNotCallMessageUpdater() throws {
        controller.loadNextReactions()

        XCTAssertNotNil(env.messageUpdater.loadReactions_messageId)

        env.messageUpdater.loadReactions_messageId = nil

        controller.hasLoadedAllReactions = true
        controller.loadNextReactions()

        XCTAssertNil(env.messageUpdater.loadReactions_messageId)
    }

    func test_loadNextReactions_whenResultLowerThanLimit_shouldSetLoadedAllReactions() {
        // This is required somehow to initialise the env.messageUpdater
        controller.loadNextReactions()

        controller.callbackQueue = .main

        let exp = expectation(description: "should succeed load next reactions call")

        env.messageUpdater.loadReactions_result = .success([.mock(type: "like"), .mock(type: "like")])

        controller.loadNextReactions(limit: 5) { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)

        XCTAssertEqual(controller.hasLoadedAllReactions, true)
    }

    func test_loadNextReactions_whenResultHigherThanLimit_shouldNotSetLoadedAllReactions() {
        // This is required somehow to initialise the env.messageUpdater
        controller.loadNextReactions()

        controller.callbackQueue = .main

        let exp = expectation(description: "should succeed load next reactions call")

        env.messageUpdater.loadReactions_result = .success(
            [.mock(type: "like"), .mock(type: "sad"), .mock(type: "wow")]
        )

        controller.loadNextReactions(limit: 1) { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)

        XCTAssertEqual(controller.hasLoadedAllReactions, false)
    }

    func test_loadNextReactions_shouldPaginateFromLastReaction() {
        controller.startObserversIfNeeded()

        let mockedReactions = repeatElement(
            ChatMessageReaction(
                type: "likes",
                score: 1,
                createdAt: .unique,
                updatedAt: .unique,
                author: .unique,
                extraData: [:]
            ),
            count: 20
        )

        controller.reactions = Array(mockedReactions)

        controller.loadNextReactions(
            limit: 10,
            completion: nil
        )

        XCTAssertEqual(env.messageUpdater.loadReactions_pagination?.pageSize, 10)
        XCTAssertEqual(env.messageUpdater.loadReactions_pagination?.offset, mockedReactions.count)
    }

    func test_loadNextReactions_shouldAppendNewReactions() {
        // This is required somehow to initialise the env.messageUpdater
        controller.loadNextReactions()

        controller.callbackQueue = .main

        let exp = expectation(description: "should succeed load next reactions call")

        let mockedReactions: [ChatMessageReaction] = [
            .mock(type: "like"), .mock(type: "like"), .mock(type: "like")
        ]
        env.messageUpdater.loadReactions_result = .success(mockedReactions)

        controller.loadNextReactions { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)

        XCTAssertEqual(controller.reactions.count, mockedReactions.count)
    }

    func test_loadNextReactions_shouldNotAppendDuplicatedReactions() {
        // This is required somehow to initialise the env.messageUpdater
        controller.loadNextReactions()

        controller.callbackQueue = .main

        let exp = expectation(description: "should succeed load next reactions call")

        let duplicatedReaction = ChatMessageReaction.mock(type: "like", author: .unique)
        let mockedReactions: [ChatMessageReaction] = [
            .mock(type: "sad", author: .unique),
            duplicatedReaction,
            .mock(type: "wow", author: .unique)
        ]
        env.messageUpdater.loadReactions_result = .success(mockedReactions)

        controller.reactions = [
            duplicatedReaction,
            .mock(type: "sad", author: .unique),
            .mock(type: "wow", author: .unique)
        ]

        controller.loadNextReactions { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)

        XCTAssertEqual(controller.reactions.count, 5)
    }

    func test_loadNextReactions_shouldCallDelegateWhenReactionsChange() {
        // This is required somehow to initialise the env.messageUpdater
        controller.loadNextReactions()

        controller.callbackQueue = .main
        controller.state = .localDataFetched

        controller.reactions = [
            .mock(type: "like", author: .unique),
            .mock(type: "like", author: .unique)
        ]

        class SpyTestDelegate: ChatMessageControllerDelegate {
            var callCount = 0
            func messageController(
                _ controller: ChatMessageController,
                didChangeReactions reactions: [ChatMessageReaction]
            ) {
                callCount += 1
            }
        }

        let testDelegate = SpyTestDelegate()
        controller.delegate = testDelegate

        let exp = expectation(description: "should succeed load next reactions call")

        let mockedReactions: [ChatMessageReaction] = [
            .mock(type: "like", author: .unique),
            .mock(type: "like", author: .unique),
            .mock(type: "like", author: .unique)
        ]
        env.messageUpdater.loadReactions_result = .success(mockedReactions)

        controller.loadNextReactions { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)

        XCTAssertEqual(controller.reactions.count, 5)
        XCTAssertEqual(testDelegate.callCount, 1)
    }

    // MARK: - Add reaction

    func test_addReaction_propagatesError() {
        // Simulate `addReaction` call and catch the completion.
        var completionError: Error?
        controller.addReaction(.init(rawValue: .unique)) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate network response with the error.
        let networkError = TestError()
        env.messageUpdater.addReaction_completion!(networkError)

        // Assert error is propagated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }

    func test_addReaction_propagatesNilError() {
        // Simulate `addReaction` call and catch the completion.
        var completionIsCalled = false
        controller.addReaction(.init(rawValue: .unique)) { [callbackQueueID] error in
            // Assert callback queue is correct.
            AssertTestQueue(withId: callbackQueueID)
            // Assert there is no error.
            XCTAssertNil(error)
            completionIsCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate successful network response.
        env.messageUpdater.addReaction_completion!(nil)
        // Release reference of completion so we can deallocate stuff
        env.messageUpdater.addReaction_completion = nil

        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_addReaction_callsUpdater_withCorrectValues() {
        let type: MessageReactionType = "like"
        let score = 5
        let enforceUnique = true
        let extraData: [String: RawJSON] = [:]

        // Simulate `addReaction` call.
        controller.addReaction(type, score: score, enforceUnique: true, extraData: extraData)

        // Assert updater is called with correct `type`.
        XCTAssertEqual(env.messageUpdater.addReaction_type, type)
        // Assert updater is called with correct `score`.
        XCTAssertEqual(env.messageUpdater.addReaction_score, score)
        // Assert updater is called with correct `enforceUnique`.
        XCTAssertEqual(env.messageUpdater.addReaction_enforceUnique, enforceUnique)
        // Assert updater is called with correct `extraData`.
        XCTAssertEqual(env.messageUpdater.addReaction_extraData, extraData)
        // Assert updater is called with correct `messageId`.
        XCTAssertEqual(env.messageUpdater.addReaction_messageId, controller.messageId)
    }

    func test_addReaction_keepsControllerAlive() {
        // Simulate `addReaction` call.
        controller.addReaction(.init(rawValue: .unique))

        // Create a weak ref and release a controller.
        weak var weakController = controller
        controller = nil

        // Assert controller is kept alive.
        AssertAsync.staysTrue(weakController != nil)
    }

    // MARK: - Delete reaction

    func test_deleteReaction_propagatesError() {
        // Simulate `deleteReaction` call and catch the completion.
        var completionError: Error?
        controller.deleteReaction(.init(rawValue: .unique)) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate network response with the error.
        let networkError = TestError()
        env.messageUpdater.deleteReaction_completion!(networkError)

        // Assert error is propagated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }

    func test_deleteReaction_propagatesNilError() {
        // Simulate `deleteReaction` call and catch the completion.
        var completionIsCalled = false
        controller.deleteReaction(.init(rawValue: .unique)) { [callbackQueueID] error in
            // Assert callback queue is correct.
            AssertTestQueue(withId: callbackQueueID)
            // Assert there is no error.
            XCTAssertNil(error)
            completionIsCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate successful network response.
        env.messageUpdater.deleteReaction_completion!(nil)
        // Release reference of completion so we can deallocate stuff
        env.messageUpdater.deleteReaction_completion = nil

        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_deleteReaction_callsUpdater_withCorrectValues() {
        let type: MessageReactionType = "like"

        // Simulate `deleteReaction` call.
        controller.deleteReaction(type)

        // Assert updater is called with correct `type`.
        XCTAssertEqual(env.messageUpdater.deleteReaction_type, type)
        // Assert updater is called with correct `messageId`.
        XCTAssertEqual(env.messageUpdater.deleteReaction_messageId, controller.messageId)
    }

    func test_deleteReaction_keepsControllerAlive() {
        // Simulate `deleteReaction` call.
        controller.deleteReaction(.init(rawValue: .unique))

        // Create a weak ref and release a controller.
        weak var weakController = controller
        controller = nil

        // Assert controller is kept alive.
        AssertAsync.staysTrue(weakController != nil)
    }

    // MARK: - Pinning message

    func test_pinMessage_callsMessageUpdater() throws {
        let pinning = MessagePinning(expirationDate: .unique)

        // Simulate `pin` calls and catch the completion
        var completionCalled = false
        controller.pin(pinning) { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        XCTAssertEqual(env.messageUpdater?.pinMessage_messageId, messageId)
        XCTAssertEqual(env.messageUpdater?.pinMessage_pinning, pinning)

        // Simulate successful update
        env.messageUpdater?.pinMessage_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.messageUpdater!.pinMessage_completion = nil

        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_pinMessage_callsMessageUpdaterWithError() {
        // Simulate `pin` call and catch the completion
        var completionCalledError: Error?
        controller.pin(.noExpiration) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.messageUpdater!.pinMessage_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    func test_unpinMessage_callsMessageUpdater() throws {
        // Simulate `unpin` calls and catch the completion
        var completionCalled = false
        controller.unpin { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        XCTAssertEqual(env.messageUpdater?.unpinMessage_messageId, messageId)

        // Simulate successful update
        env.messageUpdater?.unpinMessage_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.messageUpdater!.unpinMessage_completion = nil

        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_unpinMessage_callsMessageUpdaterWithError() {
        // Simulate `unpin` call and catch the completion
        var completionCalledError: Error?
        controller.unpin { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.messageUpdater!.unpinMessage_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // MARK: - Restart uploading for failed attachment

    func test_restartFailedAttachmentUploading_callsMessageUpdater() {
        let attachmentId: AttachmentId = .unique

        // Simulate `restartFailedAttachmentUploading` call and catch the completion
        var completionCalled = false
        controller.restartFailedAttachmentUploading(with: attachmentId) { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Assert `id` is passed to `messageUpdater`, completion is not called yet
        XCTAssertEqual(env.messageUpdater.restartFailedAttachmentUploading_id, attachmentId)
        XCTAssertFalse(completionCalled)

        // Simulate successful database operation.
        env.messageUpdater.restartFailedAttachmentUploading_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.messageUpdater.restartFailedAttachmentUploading_completion = nil

        // Assert completion is called.
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_restartFailedAttachmentUploading_propagatesErrorFromUpdater() {
        // Simulate `restartFailedAttachmentUploading` call and catch the error.
        var completionCalledError: Error?
        controller.restartFailedAttachmentUploading(with: .unique) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed restart.
        let restartError = TestError()
        env.messageUpdater.restartFailedAttachmentUploading_completion?(restartError)

        // Assert error is propagated.
        AssertAsync.willBeEqual(completionCalledError as? TestError, restartError)
    }

    // MARK: - Resend message

    func test_resendMessage_propagatesError() {
        // Simulate `resend` call and catch the completion.
        var completionError: Error?
        controller.resendMessage { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate network response with the error.
        let updaterError = TestError()
        env.messageUpdater.resendMessage_completion!(updaterError)

        // Assert error is propagated.
        AssertAsync.willBeEqual(completionError as? TestError, updaterError)
    }

    func test_resend_propagatesNilError() {
        // Simulate `resend` call and catch the completion.
        var completionIsCalled = false
        controller.resendMessage { [callbackQueueID] error in
            // Assert callback queue is correct.
            AssertTestQueue(withId: callbackQueueID)
            // Assert there is no error.
            XCTAssertNil(error)
            completionIsCalled = true
        }

        // Simulate successful updater call.
        env.messageUpdater.resendMessage_completion!(nil)

        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
    }

    func test_resendMessage_callsUpdater_withCorrectValues() {
        // Simulate `resendMessage` call.
        controller.resendMessage()

        // Assert updater is called with correct `messageId`.
        XCTAssertEqual(env.messageUpdater.resendMessage_messageId, controller.messageId)
    }

    func test_resendMessage_keepsControllerAlive() {
        // Simulate `resendMessage` call.
        controller.resendMessage()

        // Create a weak ref and release a controller.
        weak var weakController = controller
        controller = nil

        // Assert controller is kept alive.
        AssertAsync.staysTrue(weakController != nil)
    }

    // MARK: - Dispatch ephemeral message action

    func test_dispatchEphemeralMessageAction_propagatesError() {
        // Simulate `dispatchEphemeralMessageAction` call and catch the completion.
        var completionError: Error?
        controller.dispatchEphemeralMessageAction(.unique) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate network response with the error.
        let updaterError = TestError()
        env.messageUpdater.dispatchEphemeralMessageAction_completion!(updaterError)

        // Assert error is propagated.
        AssertAsync.willBeEqual(completionError as? TestError, updaterError)
    }

    func test_dispatchEphemeralMessageAction_propagatesNilError() {
        // Simulate `dispatchEphemeralMessageAction` call and catch the completion.
        var completionIsCalled = false
        controller.dispatchEphemeralMessageAction(.unique) { [callbackQueueID] error in
            // Assert callback queue is correct.
            AssertTestQueue(withId: callbackQueueID)
            // Assert there is no error.
            XCTAssertNil(error)
            completionIsCalled = true
        }

        // Simulate successful updater call.
        env.messageUpdater.dispatchEphemeralMessageAction_completion!(nil)

        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
    }

    func test_dispatchEphemeralMessageAction_callsUpdater_withCorrectValues() {
        let action: AttachmentAction = .unique

        // Simulate `dispatchEphemeralMessageAction` call.
        controller.dispatchEphemeralMessageAction(action)

        // Assert updater is called with correct values.
        XCTAssertEqual(env.messageUpdater.dispatchEphemeralMessageAction_cid, controller.cid)
        XCTAssertEqual(env.messageUpdater.dispatchEphemeralMessageAction_messageId, controller.messageId)
        XCTAssertEqual(env.messageUpdater.dispatchEphemeralMessageAction_action, action)
    }

    func test_dispatchEphemeralMessageAction_keepsControllerAlive() {
        // Simulate `dispatchEphemeralMessageAction` call.
        controller.dispatchEphemeralMessageAction(.unique)

        // Create a weak ref and release a controller.
        weak var weakController = controller
        controller = nil

        // Assert controller is kept alive.
        AssertAsync.staysTrue(weakController != nil)
    }

    // MARK: - Translate message

    func test_translate_propagatesError() {
        // Simulate `translate` call and catch the completion.
        var completionError: Error?
        controller.translate(to: .english) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate network response with the error.
        let updaterError = TestError()
        env.messageUpdater.translate_completion!(updaterError)

        // Assert error is propagated.
        AssertAsync.willBeEqual(completionError as? TestError, updaterError)
    }

    func test_translate_propagatesNilError() {
        // Simulate `transate` call and catch the completion.
        var completionIsCalled = false
        controller.translate(to: .english) { [callbackQueueID] error in
            // Assert callback queue is correct.
            AssertTestQueue(withId: callbackQueueID)
            // Assert there is no error.
            XCTAssertNil(error)
            completionIsCalled = true
        }

        // Simulate successful updater call.
        env.messageUpdater.translate_completion!(nil)

        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
    }

    func test_translate_callsUpdater_withCorrectValues() {
        // Simulate `resendMessage` call.
        controller.translate(to: .english)
        // Assert updater is called with correct `messageId` and language
        XCTAssertEqual(env.messageUpdater.translate_messageId, controller.messageId)
        XCTAssertEqual(env.messageUpdater.translate_language, .english)
    }

    func test_translate_keepsControllerAlive() {
        // Simulate `resendMessage` call.
        controller.translate(to: .english)

        // Create a weak ref and release a controller.
        weak var weakController = controller
        controller = nil

        // Assert controller is kept alive.
        AssertAsync.staysTrue(weakController != nil)
    }

    @discardableResult
    private func saveReplies(with ids: [MessageId], channelPayload: ChannelPayload? = nil) throws -> [MessageDTO] {
        let payloads: [MessagePayload] = ids.map {
            MessagePayload.dummy(messageId: $0, parentId: self.messageId)
        }

        return try saveReplies(with: payloads, channelPayload: channelPayload)
    }

    @discardableResult
    private func saveReplies(with payloads: [MessagePayload], channelPayload: ChannelPayload? = nil) throws -> [MessageDTO] {
        var replies: [MessageDTO] = []

        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload ?? .dummy(channel: .dummy(cid: self.cid)))
            let parentMessage = try session.saveMessage(
                payload: .dummy(messageId: self.messageId),
                for: self.cid,
                syncOwnReactions: false,
                cache: nil
            )
            replies = try payloads.compactMap { payload in
                let reply = try session.saveMessage(
                    payload: payload,
                    for: self.cid,
                    syncOwnReactions: false,
                    cache: nil
                )
                reply.showInsideThread = true
                return reply
            }
            parentMessage.replies = Set(replies)
        }

        return replies
    }
}

private class TestDelegate: QueueAwareDelegate, ChatMessageControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didChangeMessage_change: EntityChange<ChatMessage>?
    @Atomic var didChangeReplies_changes: [ListChange<ChatMessage>] = []
    @Atomic var didChangeReactions_reactions: [ChatMessageReaction] = []

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }

    func messageController(_ controller: ChatMessageController, didChangeMessage change: EntityChange<ChatMessage>) {
        didChangeMessage_change = change
        validateQueue()
    }

    func messageController(_ controller: ChatMessageController, didChangeReplies changes: [ListChange<ChatMessage>]) {
        didChangeReplies_changes = changes
        validateQueue()
    }

    func messageController(_ controller: ChatMessageController, didChangeReactions reactions: [ChatMessageReaction]) {
        didChangeReactions_reactions = reactions
        validateQueue()
    }
}

private class TestEnvironment {
    var messageUpdater: MessageUpdater_Mock!
    var messageObserver: EntityDatabaseObserver_Mock<ChatMessage, MessageDTO>!
    var repliesObserver: ListDatabaseObserverWrapper_Mock<ChatMessage, MessageDTO>!

    var messageObserver_synchronizeError: Error?

    lazy var controllerEnvironment: ChatMessageController
        .Environment = .init(
            messageObserverBuilder: { [unowned self] in
                self.messageObserver = .init(
                    context: $0,
                    fetchRequest: $1,
                    itemCreator: $2,
                    fetchedResultsControllerType: $3
                )
                self.messageObserver.synchronizeError = self.messageObserver_synchronizeError
                return self.messageObserver!
            },
            repliesObserverBuilder: { [unowned self] in
                self.repliesObserver = .init(
                    isBackground: $0,
                    database: $1,
                    fetchRequest: $2,
                    itemCreator: $3,
                    fetchedResultsControllerType: $4
                )
                return self.repliesObserver!
            },
            messageUpdaterBuilder: { [unowned self] in
                self.messageUpdater = MessageUpdater_Mock(
                    isLocalStorageEnabled: $0,
                    messageRepository: $1,
                    paginationStateHandler: $2,
                    database: $3,
                    apiClient: $4
                )
                return self.messageUpdater
            }
        )
}
