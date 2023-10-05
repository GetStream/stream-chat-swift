//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelController_Tests: XCTestCase {
    fileprivate var env: TestEnvironment!

    var client: ChatClient_Mock!

    var channelId: ChannelId!

    var controller: ChatChannelController!
    var controllerCallbackQueueID: UUID!
    /// Workaround for unwrapping **controllerCallbackQueueID!** in each closure that captures it
    private var callbackQueueID: UUID { controllerCallbackQueueID }

    override func setUp() {
        super.setUp()

        env = TestEnvironment()
        client = ChatClient.mock
        channelId = ChannelId.unique
        controller = ChatChannelController(
            channelQuery: .init(cid: channelId),
            channelListQuery: nil,
            client: client,
            environment: env.environment
        )
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }

    override func tearDown() {
        env?.channelUpdater?.cleanUp()
        env?.eventSender?.cleanUp()
        env = nil

        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
            Assert.canBeReleased(&env)
        }

        channelId = nil
        controllerCallbackQueueID = nil

        super.tearDown()
    }

    // MARK: - Init tests

    func test_init_assignsValuesCorrectly() {
        let channelQuery = ChannelQuery(cid: channelId)
        let channelListQuery = ChannelListQuery(filter: .containMembers(userIds: [.unique]))

        let controller = ChatChannelController(
            channelQuery: channelQuery,
            channelListQuery: channelListQuery,
            client: client
        )

        XCTAssertEqual(controller.channelQuery.cid, channelId)
        XCTAssertEqual(controller.channelListQuery, channelListQuery)
        XCTAssert(controller.client === client)
    }

    // MARK: - Channel

    func test_channel_accessible_initially() throws {
        let payload = dummyPayload(with: channelId)

        // Save two channels to DB (only one matching the query) and wait for completion
        try client.databaseContainer.writeSynchronously { session in
            // Channel with the id matching the query
            try session.saveChannel(payload: payload)
            // Other channel
            try session.saveChannel(payload: self.dummyPayload(with: .unique))
        }

        // Assert the channel and messages are loaded
        XCTAssertEqual(controller.channel?.cid, channelId)
        XCTAssertEqual(Set(controller.messages.map(\.id)), Set(payload.messages.map(\.id)))
    }

    // MARK: - hasLoadedAllPreviousMessages

    func test_hasLoadedAllPreviousMessages_whenPaginationStateHasLoadedAllPreviousMessages_thenReturnsTrue() {
        // Given
        env.channelUpdater?.mockPaginationState.hasLoadedAllPreviousMessages = true

        // When
        let result = controller.hasLoadedAllPreviousMessages

        // Then
        XCTAssertTrue(result)
    }

    func test_hasLoadedAllPreviousMessages_whenPaginationStateHasNotLoadedAllPreviousMessages_thenReturnsFalse() {
        // Given
        env.channelUpdater?.mockPaginationState.hasLoadedAllPreviousMessages = false

        // When
        let result = controller.hasLoadedAllPreviousMessages

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - hasLoadedAllNextMessages

    func test_hasLoadedAllNextMessages_whenPaginationStateHasLoadedAllNextMessagesOrMessagesAreEmpty_thenReturnsTrue() throws {
        // Given
        try setupChannel(
            channelPayload: .dummy(messages: []),
            withAllNextMessagesLoaded: true
        )

        // When
        let result = controller.hasLoadedAllNextMessages

        // Then
        XCTAssertTrue(result)
    }

    func test_hasLoadedAllNextMessages_whenPaginationStateHasNotLoadedAllNextMessagesAndMessagesAreNotEmpty_thenReturnsFalse() throws {
        // Given
        try setupChannel(
            channelPayload: .dummy(channel: .dummy(cid: controller.cid!), messages: [.dummy(), .dummy()]),
            withAllNextMessagesLoaded: false
        )

        // When
        let result = controller.hasLoadedAllNextMessages

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - isLoadingPreviousMessages

    func test_isLoadingPreviousMessages_whenPaginationStateIsLoadingPreviousMessages_thenReturnsTrue() {
        // Given
        env.channelUpdater?.mockPaginationState.isLoadingPreviousMessages = true

        // When
        let result = controller.isLoadingPreviousMessages

        // Then
        XCTAssertTrue(result)
    }

    func test_isLoadingPreviousMessages_whenPaginationStateIsNotLoadingPreviousMessages_thenReturnsFalse() {
        // Given
        env.channelUpdater?.mockPaginationState.isLoadingPreviousMessages = false

        // When
        let result = controller.isLoadingPreviousMessages

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Tests for isLoadingNextMessages

    func test_isLoadingNextMessages_whenPaginationStateIsLoadingNextMessages_thenReturnsTrue() {
        // Given
        env.channelUpdater?.mockPaginationState.isLoadingNextMessages = true

        // When
        let result = controller.isLoadingNextMessages

        // Then
        XCTAssertTrue(result)
    }

    func test_isLoadingNextMessages_whenPaginationStateIsNotLoadingNextMessages_thenReturnsFalse() {
        // Given
        env.channelUpdater?.mockPaginationState.isLoadingNextMessages = false

        // When
        let result = controller.isLoadingNextMessages

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Tests for isLoadingMiddleMessages

    func test_isLoadingMiddleMessages_whenPaginationStateIsLoadingMiddleMessages_thenReturnsTrue() {
        // Given
        env.channelUpdater?.mockPaginationState.isLoadingMiddleMessages = true

        // When
        let result = controller.isLoadingMiddleMessages

        // Then
        XCTAssertTrue(result)
    }

    func test_isLoadingMiddleMessages_whenPaginationStateIsNotLoadingMiddleMessages_thenReturnsFalse() {
        // Given
        env.channelUpdater?.mockPaginationState.isLoadingMiddleMessages = false

        // When
        let result = controller.isLoadingMiddleMessages

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Tests for isJumpingToMessage

    func test_isJumpingToMessage_whenPaginationStateIsJumpingToMessage_thenReturnsTrue() {
        // Given
        env.channelUpdater?.mockPaginationState.hasLoadedAllNextMessages = false

        // When
        let result = controller.isJumpingToMessage

        // Then
        XCTAssertTrue(result)
    }

    func test_isJumpingToMessage_whenPaginationStateIsNotJumpingToMessage_thenReturnsFalse() {
        // Given
        env.channelUpdater?.mockPaginationState.hasLoadedAllNextMessages = true

        // When
        let result = controller.isJumpingToMessage

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Tests for lastOldestMessageId

    func test_lastOldestMessageId_whenPaginationStateHasOldestFetchedMessage_thenReturnsItsId() {
        // Given
        let oldestFetchedMessage = MessagePayload.dummy()
        env.channelUpdater?.mockPaginationState.oldestFetchedMessage = oldestFetchedMessage

        // When
        let result = controller.lastOldestMessageId

        // Then
        XCTAssertEqual(result, oldestFetchedMessage.id)
    }

    func test_lastOldestMessageId_whenPaginationStateHasNoOldestFetchedMessage_thenReturnsNil() {
        // Given
        env.channelUpdater?.mockPaginationState.oldestFetchedMessage = nil

        // When
        let result = controller.lastOldestMessageId

        // Then
        XCTAssertNil(result)
    }

    // MARK: - Tests for lastNewestMessageId

    func test_lastNewestMessageId_whenPaginationStateHasNewestFetchedMessage_thenReturnsItsId() {
        // Given
        let newestFetchedMessage = MessagePayload.dummy()
        env.channelUpdater?.mockPaginationState.newestFetchedMessage = newestFetchedMessage

        // When
        let result = controller.lastNewestMessageId

        // Then
        XCTAssertEqual(result, newestFetchedMessage.id)
    }

    func test_lastNewestMessageId_whenPaginationStateHasNoNewestFetchedMessage_thenReturnsNil() {
        // Given
        env.channelUpdater?.mockPaginationState.newestFetchedMessage = nil

        // When
        let result = controller.lastNewestMessageId

        // Then
        XCTAssertNil(result)
    }

    // MARK: - First Unread Message Id

    func test_firstUnreadMessageId_whenThereIsNoChannel() {
        XCTAssertNil(controller.firstUnreadMessageId)
    }

    func test_firstUnreadMessageId_whenReadsDoesNotContainCurrentUserId_whenNOTAllPreviousMessagesAreLoaded() throws {
        let oldestMessageId = MessageId.unique
        let newestMessageId = MessageId.unique
        try createChannel(oldestMessageId: oldestMessageId, newestMessageId: newestMessageId)

        try mockHasLoadedAllPreviousMessages(false)

        XCTAssertNil(controller.firstUnreadMessageId)
    }

    func test_firstUnreadMessageId_whenReadsDoesNotContainCurrentUserId_whenAllPreviousMessagesAreLoaded() throws {
        let oldestMessageId = MessageId.unique
        let newestMessageId = MessageId.unique
        try createChannel(oldestMessageId: oldestMessageId, newestMessageId: newestMessageId)

        try mockHasLoadedAllPreviousMessages(true)

        XCTAssertEqual(controller.firstUnreadMessageId, oldestMessageId)
    }

    func test_firstUnreadMessageId_whenReadsContainsCurrentUserId_whenUnreadMessageCountIsZero() throws {
        let userId = UserId.unique
        let oldestMessageId = MessageId.unique
        let newestMessageId = MessageId.unique
        try createChannel(
            oldestMessageId: oldestMessageId,
            newestMessageId: newestMessageId,
            channelReads: [
                ChannelReadPayload(
                    user: .dummy(userId: userId),
                    lastReadAt: .unique,
                    lastReadMessageId: nil,
                    unreadMessagesCount: 0
                )
            ]
        )

        client.currentUserId_mock = userId

        XCTAssertEqual(controller.firstUnreadMessageId, nil)
    }

    func test_firstUnreadMessageId_whenReadsContainsCurrentUserId_whenLastReadMessageIdIsNil_whenNotAllPreviousMessagesAreLoaded() throws {
        let userId = UserId.unique
        let channelRead = ChannelReadPayload(
            user: .dummy(userId: userId),
            lastReadAt: .unique,
            lastReadMessageId: nil,
            unreadMessagesCount: 3
        )
        let token = Token(rawValue: "", userId: userId, expiration: nil)
        controller.client.authenticationRepository.setMockToken(token)

        let oldestMessageId = MessageId.unique
        let newestMessageId = MessageId.unique
        try createChannel(oldestMessageId: oldestMessageId, newestMessageId: newestMessageId, channelReads: [channelRead])
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: .dummy(userId: userId, role: .user))
        }

        try mockHasLoadedAllPreviousMessages(false)

        XCTAssertNil(controller.firstUnreadMessageId)
    }

    func test_firstUnreadMessageId_whenReadsContainsCurrentUserId_whenLastReadMessageIdIsNil_whenAllPreviousMessagesAreLoaded() throws {
        let userId = UserId.unique
        let channelRead = ChannelReadPayload(
            user: .dummy(userId: userId),
            lastReadAt: .unique,
            lastReadMessageId: nil,
            unreadMessagesCount: 3
        )
        let token = Token(rawValue: "", userId: userId, expiration: nil)
        controller.client.authenticationRepository.setMockToken(token)

        let oldestMessageId = MessageId.unique
        let newestMessageId = MessageId.unique
        try createChannel(oldestMessageId: oldestMessageId, newestMessageId: newestMessageId, channelReads: [channelRead])
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: .dummy(userId: userId, role: .user))
        }

        try mockHasLoadedAllPreviousMessages(true)

        XCTAssertEqual(controller.firstUnreadMessageId, oldestMessageId)
    }

    func test_firstUnreadMessageId_whenReadsContainsCurrentUserId_whenLastReadMessageIdIsNil_whenOldestMessageIsDeleted() throws {
        try mockHasLoadedAllPreviousMessages(true)
        try AssertFirstUnreadMessageIsOldestRegularMessageId(oldestMessageType: .deleted)
    }

    func test_firstUnreadMessageId_whenReadsContainsCurrentUserId_whenLastReadMessageIdIsNil_whenOldestMessageIsEphemeral() throws {
        try mockHasLoadedAllPreviousMessages(true)
        try AssertFirstUnreadMessageIsOldestRegularMessageId(oldestMessageType: .ephemeral)
    }

    func test_firstUnreadMessageId_whenReadsContainsCurrentUserId_whenLastReadMessageIdIsNil_whenOldestMessageIsError() throws {
        try mockHasLoadedAllPreviousMessages(true)
        try AssertFirstUnreadMessageIsOldestRegularMessageId(oldestMessageType: .error)
    }

    func test_firstUnreadMessageId_whenReadsContainsCurrentUserId_whenLastReadMessageIdIsNil_whenOldestMessageIsSystem() throws {
        try mockHasLoadedAllPreviousMessages(true)
        try AssertFirstUnreadMessageIsOldestRegularMessageId(oldestMessageType: .system)
    }

    func test_firstUnreadMessageId_whenReadsContainsCurrentUserId_whenLastReadMessageIdDoesNotExist() throws {
        let oldestMessageId = MessageId.unique
        let newestMessageId = MessageId.unique
        let notLoadedLastReadMessageId = MessageId.unique

        let userId = UserId.unique
        let channelRead = ChannelReadPayload(
            user: .dummy(userId: userId),
            lastReadAt: .unique,
            lastReadMessageId: notLoadedLastReadMessageId,
            unreadMessagesCount: 3
        )
        let token = Token(rawValue: "", userId: userId, expiration: nil)
        controller.client.authenticationRepository.setMockToken(token)

        try createChannel(oldestMessageId: oldestMessageId, newestMessageId: newestMessageId, channelReads: [channelRead])

        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: .dummy(userId: userId, role: .user))
        }

        XCTAssertNil(controller.firstUnreadMessageId)
    }

    func test_firstUnreadMessageId_whenReadsContainsCurrentUserId_whenLastReadMessageIdIsTheSameAsTheLastMessage() throws {
        let oldestMessageId = MessageId.unique
        let newestMessageId = MessageId.unique

        let userId = UserId.unique
        let channelRead = ChannelReadPayload(
            user: .dummy(userId: userId),
            lastReadAt: .unique,
            lastReadMessageId: newestMessageId,
            unreadMessagesCount: 3
        )
        let token = Token(rawValue: "", userId: userId, expiration: nil)
        controller.client.authenticationRepository.setMockToken(token)

        try createChannel(oldestMessageId: oldestMessageId, newestMessageId: newestMessageId, channelReads: [channelRead])

        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: .dummy(userId: userId, role: .user))
        }

        XCTAssertNil(controller.firstUnreadMessageId)
    }

    func test_firstUnreadMessageId_whenReadsContainsCurrentUserId_whenLastReadMessageIdIsNotTheLatestMessage() throws {
        let oldestMessageId = MessageId.unique
        let newestMessageId = MessageId.unique

        let userId = UserId.unique
        let channelRead = ChannelReadPayload(
            user: .dummy(userId: userId),
            lastReadAt: .unique,
            lastReadMessageId: oldestMessageId,
            unreadMessagesCount: 3
        )
        let token = Token(rawValue: "", userId: userId, expiration: nil)
        controller.client.authenticationRepository.setMockToken(token)

        try createChannel(oldestMessageId: oldestMessageId, newestMessageId: newestMessageId, channelReads: [channelRead])

        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: .dummy(userId: userId, role: .user))
        }

        XCTAssertEqual(controller.firstUnreadMessageId, newestMessageId)
    }

    func test_firstUnreadMessageId_whenMessagesAfterLastReadAreDeletedAndOwned() throws {
        let notOwnMessageId = MessageId.unique
        let deletedMessageId = MessageId.unique
        let ownMessageId = MessageId.unique

        let userId = UserId.unique
        let channelRead = ChannelReadPayload(
            user: .dummy(userId: userId),
            lastReadAt: .unique,
            lastReadMessageId: notOwnMessageId,
            unreadMessagesCount: 3
        )
        let token = Token(rawValue: "", userId: userId, expiration: nil)
        controller.client.authenticationRepository.setMockToken(token)

        let messages: [MessagePayload] = [
            .dummy(messageId: notOwnMessageId, authorUserId: .unique, createdAt: Date().addingTimeInterval(-1000)),
            .dummy(messageId: deletedMessageId, authorUserId: .unique, createdAt: Date().addingTimeInterval(0), deletedAt: Date()),
            .dummy(messageId: ownMessageId, authorUserId: userId, createdAt: Date().addingTimeInterval(1000))
        ]

        try createChannel(messages: messages, channelReads: [channelRead])
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: .dummy(userId: userId, role: .user))
        }

        XCTAssertNil(controller.firstUnreadMessageId)
    }

    func test_firstUnreadMessageId_whenMessagesAfterLastReadAlsoContainDeletedAndOwned_willPickTheFirstOneThatIsNotOwnedAndIsNotDeleted() throws {
        let notOwnMessageId = MessageId.unique
        let deletedMessageId = MessageId.unique
        let ownMessageId = MessageId.unique
        let notOwnNextValidId = MessageId.unique

        let userId = UserId.unique
        let channelRead = ChannelReadPayload(
            user: .dummy(userId: userId),
            lastReadAt: .unique,
            lastReadMessageId: notOwnMessageId,
            unreadMessagesCount: 3
        )
        let token = Token(rawValue: "", userId: userId, expiration: nil)
        controller.client.authenticationRepository.setMockToken(token)

        let messages: [MessagePayload] = [
            .dummy(messageId: notOwnMessageId, authorUserId: .unique, createdAt: Date().addingTimeInterval(-1000)),
            .dummy(messageId: deletedMessageId, authorUserId: .unique, createdAt: Date().addingTimeInterval(0), deletedAt: Date()),
            .dummy(messageId: ownMessageId, authorUserId: userId, createdAt: Date().addingTimeInterval(1000)),
            .dummy(messageId: notOwnNextValidId, authorUserId: .unique, createdAt: Date().addingTimeInterval(2000))
        ]

        try createChannel(messages: messages, channelReads: [channelRead])
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: .dummy(userId: userId, role: .user))
        }

        XCTAssertEqual(controller.firstUnreadMessageId, notOwnNextValidId)
    }

    // MARK: - Synchronize tests

    func test_synchronize_changesControllerState() throws {
        // Check if controller has initialized state initially.
        XCTAssertEqual(controller.state, .initialized)

        // Simulate `synchronize` call.
        controller.synchronize()

        // Save channel to database.
        try client.mockDatabaseContainer.createChannel(cid: channelId)

        // Simulate successful network call.
        env.channelUpdater?.update_completion?(.success(dummyPayload(with: .unique)))

        // Check if state changed after successful network call.
        AssertAsync.willBeEqual(controller.state, .remoteDataFetched)
    }

    func test_synchronize_changesControllerStateOnError() {
        // Check if controller has `initialized` state initially.
        assert(controller.state == .initialized)

        // Simulate `synchronize` call
        controller.synchronize()

        // Simulate failed network call.
        let error = TestError()
        env.channelUpdater?.update_completion?(.failure(error))

        // Check if state changed after failed network call.
        XCTAssertEqual(controller.state, .remoteDataFetchFailed(ClientError(with: error)))
    }

    func test_synchronize_callsChannelUpdater() throws {
        // Simulate `synchronize` calls and catch the completion
        var completionCalled = false
        controller.synchronize { [callbackQueueID] error in
            XCTAssertNil(error)
            AssertTestQueue(withId: callbackQueueID)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Assert the updater is called with the query
        XCTAssertEqual(env.channelUpdater!.update_channelQuery?.cid, channelId)
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)

        // Save channel to database.
        try client.mockDatabaseContainer.createChannel(cid: channelId)

        // Simulate successful update
        env.channelUpdater!.update_completion?(.success(dummyPayload(with: .unique)))
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.update_completion = nil

        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    /// This test simulates a bug where the `channel` and `messages` fields were not updated if
    /// they weren't touched before calling synchronize.
    func test_synchronize_fieldsAreFetched_evenAfterCallingSynchronize() throws {
        // Simulate synchronize call
        controller.synchronize()

        let payload = dummyPayload(with: channelId)
        assert(!payload.messages.isEmpty)

        // Simulate successful updater response
        try client.databaseContainer.writeSynchronously {
            try $0.saveChannel(payload: payload, query: nil, cache: nil)
        }
        env.channelUpdater?.update_completion?(.success(dummyPayload(with: .unique)))

        XCTAssertEqual(controller.channel?.cid, channelId)
        XCTAssertEqual(controller.messages.count, payload.messages.count)
    }

    /// This test simulates a bug where the `channel` and `messages` fields were not updated if
    /// they weren't touched before calling synchronize.
    func test_synchronize_newChannelController_fieldsAreFetched_evenAfterCallingSynchronize() throws {
        setupControllerForNewChannel(query: .init(cid: channelId))

        // Simulate synchronize call
        controller.synchronize()

        let payload = dummyPayload(with: channelId)
        assert(!payload.messages.isEmpty)

        // Simulate successful updater response
        try client.databaseContainer.writeSynchronously {
            try $0.saveChannel(payload: payload, query: nil, cache: nil)
        }
        env.channelUpdater?.update_onChannelCreated?(channelId)
        env.channelUpdater?.update_completion?(.success(dummyPayload(with: .unique)))

        XCTAssertEqual(controller.channel?.cid, channelId)
        XCTAssertEqual(controller.messages.count, payload.messages.count)
    }

    /// This test simulates a bug where the `channel` and `messages` fields were not updated if
    /// they weren't touched before calling synchronize.
    func test_synchronize_newMessageChannelController_fieldsAreFetched_evenAfterCallingSynchronize() throws {
        setupControllerForNewMessageChannel(cid: channelId)

        // Simulate synchronize call
        controller.synchronize()

        let payload = dummyPayload(with: channelId)
        assert(!payload.messages.isEmpty)

        // Simulate successful updater response
        try client.databaseContainer.writeSynchronously {
            try $0.saveChannel(payload: payload, query: nil, cache: nil)
        }
        env.channelUpdater?.update_onChannelCreated?(channelId)
        env.channelUpdater?.update_completion?(.success(dummyPayload(with: .unique)))

        XCTAssertEqual(controller.channel?.cid, channelId)
        XCTAssertEqual(controller.messages.count, payload.messages.count)
    }

    /// This test simulates a bug where the `channel` and `messages` fields were not updated if
    /// they weren't touched before calling synchronize.
    func test_synchronize_newDMChannelController_fieldsAreFetched_evenAfterCallingSynchronize() throws {
        setupControllerForNewDirectMessageChannel(
            currentUserId: .unique,
            otherUserId: .unique
        )

        // Simulate synchronize call
        controller.synchronize()

        let payload = dummyPayload(with: channelId)
        assert(!payload.messages.isEmpty)

        // Simulate successful updater response
        try client.databaseContainer.writeSynchronously {
            try $0.saveChannel(payload: payload, query: nil, cache: nil)
        }

        // We call these callbacks on a queue other than main queue
        // to simulate the actual scenario where callbacks will be called
        // from NSURLSession-delegate (serial) queue
        let _: Bool = try waitFor { completion in
            DispatchQueue.global().async {
                self.env.channelUpdater?.update_onChannelCreated?(self.channelId)
                self.env.channelUpdater?.update_completion?(.success(self.dummyPayload(with: .unique)))
                completion(true)
            }
        }

        XCTAssertEqual(controller.channel?.cid, channelId)
        XCTAssertEqual(controller.messages.count, payload.messages.count)
    }

    func test_synchronize_propagesErrorFromUpdater() {
        // Simulate `synchronize` call and catch the completion
        var completionCalledError: Error?
        controller.synchronize { [callbackQueueID] in
            completionCalledError = $0
            AssertTestQueue(withId: callbackQueueID)
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.update_completion?(.failure(testError))

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // MARK: - Creating `ChannelController` tests

    func test_channelControllerForNewChannel_createdCorrectly() throws {
        // Simulate currently logged-in user
        let currentUserId: UserId = .unique
        client.setToken(token: .unique(userId: currentUserId))

        let cid: ChannelId = .unique
        let team: String = .unique
        let members: Set<UserId> = [.unique]
        let invites: Set<UserId> = [.unique]

        // Create a new `ChannelController`
        for isCurrentUserMember in [true, false] {
            let controller = try client.channelController(
                createChannelWithId: cid,
                name: .unique,
                imageURL: .unique(),
                team: team,
                members: members,
                isCurrentUserMember: isCurrentUserMember,
                invites: invites,
                extraData: [:]
            )

            // Assert `ChannelQuery` created correctly
            XCTAssertEqual(cid, controller.channelQuery.cid)
            XCTAssertEqual(team, controller.channelQuery.channelPayload?.team)
            XCTAssertEqual(
                members.union(isCurrentUserMember ? [currentUserId] : []),
                controller.channelQuery.channelPayload?.members
            )
            XCTAssertEqual(invites, controller.channelQuery.channelPayload?.invites)
            XCTAssertEqual([:], controller.channelQuery.channelPayload?.extraData)
        }
    }

    func test_channelControllerForNewChannel_throwsError_ifCurrentUserDoesNotExist() throws {
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
            Assert.canBeReleased(&env)
        }

        let clientWithoutCurrentUser = ChatClient(config: .init(apiKeyString: .unique))

        for isCurrentUserMember in [true, false] {
            // Try to create `ChannelController` while current user is missing
            XCTAssertThrowsError(
                try clientWithoutCurrentUser.channelController(
                    createChannelWithId: .unique,
                    name: .unique,
                    imageURL: .unique(),
                    team: .unique,
                    members: [.unique, .unique],
                    isCurrentUserMember: isCurrentUserMember,
                    invites: [.unique, .unique],
                    extraData: [:]
                )
            ) { error in
                // Assert `ClientError.CurrentUserDoesNotExist` is thrown
                XCTAssertTrue(error is ClientError.CurrentUserDoesNotExist)
            }
        }
    }

    func test_channelControllerForNewChannel_includesCurrentUser_byDefault() throws {
        // Simulate currently logged-in user
        let currentUserId: UserId = .unique
        client.setToken(token: .unique(userId: currentUserId))

        // Create DM channel members.
        let members: Set<UserId> = [.unique, .unique, .unique]

        // Try to create `ChannelController` with non-empty members while current user is missing
        let controller = try client.channelController(
            createChannelWithId: .unique,
            name: .unique,
            imageURL: .unique(),
            team: .unique,
            members: members,
            extraData: [:]
        )

        XCTAssertEqual(controller.channelQuery.channelPayload?.members, members.union([currentUserId]))
    }

    func test_channelControllerForNew1on1Channel_createdCorrectly() throws {
        // Simulate currently logged-in user
        let currentUserId: UserId = .unique
        client.setToken(token: .unique(userId: currentUserId))

        for isCurrentUserMember in [true, false] {
            let team: String = .unique
            let members: Set<UserId> = [.unique]
            let channelType: ChannelType = .custom(.unique)

            // Create a new `ChannelController`
            let controller = try client.channelController(
                createDirectMessageChannelWith: members,
                type: channelType,
                isCurrentUserMember: isCurrentUserMember,
                name: .unique,
                imageURL: .unique(),
                team: team,
                extraData: [:]
            )

            // Assert `ChannelQuery` created correctly
            XCTAssertEqual(controller.channelQuery.channelPayload?.team, team)
            XCTAssertEqual(controller.channelQuery.type, channelType)
            XCTAssertEqual(
                members.union(isCurrentUserMember ? [currentUserId] : []),
                controller.channelQuery.channelPayload?.members
            )
            XCTAssertEqual(controller.channelQuery.channelPayload?.extraData, [:])
        }
    }

    func test_channelControllerForNew1on1Channel_throwsError_OnEmptyMembers() {
        // Simulate currently logged-in user
        let currentUserId: UserId = .unique
        client.setToken(token: .unique(userId: currentUserId))

        let members: Set<UserId> = []

        // Create a new `ChannelController`
        do {
            _ = try client.channelController(
                createDirectMessageChannelWith: members,
                name: .unique,
                imageURL: .unique(),
                team: .unique,
                extraData: .init()
            )
        } catch {
            XCTAssert(error is ClientError.ChannelEmptyMembers)
        }
    }

    func test_channelControllerForNewChannel_failedMessageKeepsOrdering_whenLocalTimeIsNotSynced() throws {
        let userId: UserId = .unique
        let channelId: ChannelId = .unique

        // Create current user
        try client.databaseContainer.createCurrentUser(id: userId)

        // Setup controller
        setupControllerForNewMessageChannel(cid: channelId)

        // Save channel with some messages
        let channelPayload: ChannelPayload = dummyPayload(with: channelId, numberOfMessages: 5)
        let originalLastMessageAt: Date = channelPayload.channel.lastMessageAt ?? channelPayload.channel.createdAt
        try client.databaseContainer.writeSynchronously {
            try $0.saveChannel(payload: channelPayload)
        }

        // Get sorted messages (we'll use their createdAt later)
        let sortedMessages = channelPayload.messages.sorted(by: { $0.createdAt > $1.createdAt })

        // Create a new message payload that's older than `channel.lastMessageAt`
        // but newer than 2nd to last message
        let oldMessageCreatedAt = Date.unique(
            before: sortedMessages[0].createdAt,
            after: sortedMessages[1].createdAt
        )
        var oldMessageId: MessageId?
        // Save the message payload and check `channel.lastMessageAt` is not updated by older message
        try client.databaseContainer.writeSynchronously {
            let dto = try $0.createNewMessage(
                in: channelId,
                messageId: .unique,
                text: .unique,
                pinning: nil,
                command: nil,
                arguments: nil,
                parentMessageId: nil,
                attachments: [],
                mentionedUserIds: [],
                showReplyInChannel: false,
                isSilent: false,
                quotedMessageId: nil,
                createdAt: oldMessageCreatedAt,
                skipPush: false,
                skipEnrichUrl: false,
                extraData: [:]
            )
            // Simulate sending failed for this message
            dto.localMessageState = .sendingFailed
            oldMessageId = dto.id
        }
        var channel = try XCTUnwrap(client.databaseContainer.viewContext.channel(cid: channelId))
        XCTAssertNearlySameDate(channel.lastMessageAt?.bridgeDate, originalLastMessageAt)

        // Create a new message payload that's newer than `channel.lastMessageAt`
        let newerMessagePayload: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: userId,
            createdAt: .unique(after: channelPayload.channel.lastMessageAt!)
        )
        // Save the message payload and check `channel.lastMessageAt` is updated
        try client.databaseContainer.writeSynchronously {
            try $0.saveMessage(payload: newerMessagePayload, for: channelId, syncOwnReactions: true, cache: nil)
        }
        channel = try XCTUnwrap(client.databaseContainer.viewContext.channel(cid: channelId))
        XCTAssertEqual(channel.lastMessageAt?.bridgeDate, newerMessagePayload.createdAt)

        // Check if the message ordering is correct
        // First message should be the newest message
        XCTAssertEqual(controller.messages[0].id, newerMessagePayload.id)
        // Third message is the failed one
        XCTAssertEqual(controller.messages[2].id, oldMessageId)
    }

    func test_channelControllerForNewDirectMessagesChannel_throwsError_ifCurrentUserDoesNotExist() {
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&self.client)
            Assert.canBeReleased(&env)
        }

        let client = ChatClient(config: .init(apiKeyString: .unique))

        for isCurrentUserMember in [true, false] {
            // Try to create `ChannelController` with non-empty members while current user is missing
            XCTAssertThrowsError(
                try client.channelController(
                    createDirectMessageChannelWith: [.unique],
                    isCurrentUserMember: isCurrentUserMember,
                    name: .unique,
                    imageURL: .unique(),
                    team: .unique,
                    extraData: .init()
                )
            ) { error in
                // Assert `ClientError.CurrentUserDoesNotExist` is thrown
                XCTAssertTrue(error is ClientError.CurrentUserDoesNotExist)
            }
        }
    }

    func test_channelControllerForNewDirectMessagesChannel_includesCurrentUser_byDefault() throws {
        // Simulate currently logged-in user
        let currentUserId: UserId = .unique
        client.setToken(token: .unique(userId: currentUserId))

        // Create DM channel members.
        let members: Set<UserId> = [.unique, .unique, .unique]

        // Try to create `ChannelController` with non-empty members while current user is missing
        let controller = try client.channelController(
            createDirectMessageChannelWith: members,
            name: .unique,
            imageURL: .unique(),
            team: .unique,
            extraData: .init()
        )

        XCTAssertEqual(controller.channelQuery.channelPayload?.members, members.union([currentUserId]))
    }

    func test_channelController_returnsNilCID_forNewDirectMessageChannel() throws {
        // Simulate currently logged-in user
        let currentUserId: UserId = .unique
        client.setToken(token: .unique(userId: currentUserId))

        // Create ChatChannelController for new channel
        controller = try client.channelController(
            createDirectMessageChannelWith: [.unique],
            name: .unique,
            imageURL: .unique(),
            extraData: [:]
        )

        // Assert cid is nil
        XCTAssertNil(controller.cid)
    }

    // MARK: - Channel change propagation tests

    func test_channelChanges_arePropagated() throws {
        // Simulate changes in the DB:
        _ = try waitFor {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: self.channelId), query: nil, cache: nil)
            }, completion: $0)
        }

        // Assert the resulting value is updated
        AssertAsync.willBeEqual(controller.channel?.cid, channelId)
        AssertAsync.willBeTrue(controller.channel?.isFrozen)

        // Simulate channel changes
        _ = try waitFor {
            client.databaseContainer.write({ session in
                let context = (session as! NSManagedObjectContext)
                let channelDTO = try! context.fetch(ChannelDTO.fetchRequest(for: self.channelId)).first!
                channelDTO.isFrozen = false
            }, completion: $0)
        }

        AssertAsync.willBeTrue(controller.channel?.isFrozen == false)
    }

    func test_messageChanges_arePropagated() throws {
        let payload = dummyPayload(with: channelId)

        // Simulate changes in the DB:
        _ = try waitFor {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: payload)
            }, completion: $0)
        }

        // Simulate `synchronize` call
        controller.synchronize()

        // Simulate an incoming message
        let newMessageId: MessageId = .unique
        let newMessagePayload: MessagePayload = .dummy(
            messageId: newMessageId,
            authorUserId: .unique,
            createdAt: Date()
        )
        _ = try waitFor {
            client.databaseContainer.write({ session in
                try session.saveMessage(payload: newMessagePayload, for: self.channelId, syncOwnReactions: true, cache: nil)
            }, completion: $0)
        }

        // Assert the new message is presented
        AssertAsync.willBeTrue(controller.messages.contains { $0.id == newMessageId })
    }

    func test_messagesOrdering_topToBottom_HaveCorrectOrder() throws {
        // Create a channel
        try client.databaseContainer.createChannel(
            cid: channelId,
            withMessages: false
        )

        controller = client.channelController(
            for: channelId,
            messageOrdering: .topToBottom
        )

        // Insert two messages
        let message1: MessagePayload = .dummy(messageId: .unique, authorUserId: .unique)
        let message2: MessagePayload = .dummy(messageId: .unique, authorUserId: .unique)

        try client.databaseContainer.writeSynchronously {
            try $0.saveMessage(payload: message1, for: self.channelId, syncOwnReactions: true, cache: nil)
            try $0.saveMessage(payload: message2, for: self.channelId, syncOwnReactions: true, cache: nil)
        }

        // Check the order of messages is correct
        let topToBottomIds = [message1, message2].sorted { $0.createdAt > $1.createdAt }.map(\.id)
        XCTAssertEqual(controller.messages.map(\.id), topToBottomIds)
    }

    func test_messagesOrdering_bottomToTop_HaveCorrectOrder() throws {
        // Create a channel
        try client.databaseContainer.createChannel(
            cid: channelId,
            withMessages: false
        )

        controller = client.channelController(
            for: channelId,
            messageOrdering: .bottomToTop
        )

        // Insert two messages
        let message1: MessagePayload = .dummy(messageId: .unique, authorUserId: .unique)
        let message2: MessagePayload = .dummy(messageId: .unique, authorUserId: .unique)

        try client.databaseContainer.writeSynchronously {
            try $0.saveMessage(payload: message1, for: self.channelId, syncOwnReactions: true, cache: nil)
            try $0.saveMessage(payload: message2, for: self.channelId, syncOwnReactions: true, cache: nil)
        }

        // Check the order of messages is correct
        let bottomToTopIds = [message1, message2].sorted { $0.createdAt < $1.createdAt }.map(\.id)
        XCTAssertEqual(controller.messages.map(\.id), bottomToTopIds)
    }

    func test_threadReplies_areNotShownInChannel() throws {
        // Create a channel
        try client.databaseContainer.createChannel(cid: channelId, withMessages: false)
        controller = client.channelController(
            for: channelId,
            messageOrdering: .topToBottom
        )

        // Insert two messages
        let message1: MessagePayload = .dummy(messageId: "msg1-" + .unique, authorUserId: .unique)
        let message2: MessagePayload = .dummy(messageId: "msg2-" + .unique, authorUserId: .unique)

        // Insert reply that should be shown in channel.
        let reply1: MessagePayload = .dummy(
            messageId: "reply1-" + .unique,
            parentId: message2.id,
            showReplyInChannel: true,
            authorUserId: .unique
        )

        // Insert reply that should be visible only in thread.
        let reply2: MessagePayload = .dummy(
            messageId: "reply2-" + .unique,
            parentId: message2.id,
            showReplyInChannel: false,
            authorUserId: .unique
        )

        try client.databaseContainer.writeSynchronously {
            try $0.saveMessage(payload: message1, for: self.channelId, syncOwnReactions: true, cache: nil)
            try $0.saveMessage(payload: message2, for: self.channelId, syncOwnReactions: true, cache: nil)
            try $0.saveMessage(payload: reply1, for: self.channelId, syncOwnReactions: true, cache: nil)
            try $0.saveMessage(payload: reply2, for: self.channelId, syncOwnReactions: true, cache: nil)
        }

        // Check the relevant reply is shown in channel
        let messagesWithReply = [message1, message2, reply1].sorted { $0.createdAt > $1.createdAt }.map(\.id)
        XCTAssertEqual(controller.messages.map(\.id), messagesWithReply)
    }

    func test_threadEphemeralMessages_areNotShownInChannel() throws {
        // Create a channel
        try client.databaseContainer.createChannel(cid: channelId, withMessages: false)
        controller = client.channelController(
            for: channelId,
            messageOrdering: .topToBottom
        )

        // Insert a message
        let message1: MessagePayload = .dummy(messageId: .unique, authorUserId: .unique)

        // Insert ephemeral message in message1's thread
        let ephemeralMessage: MessagePayload = .dummy(
            type: .ephemeral,
            messageId: .unique,
            parentId: message1.id,
            authorUserId: .unique
        )

        try client.databaseContainer.writeSynchronously {
            try $0.saveMessage(payload: message1, for: self.channelId, syncOwnReactions: true, cache: nil)
            try $0.saveMessage(payload: ephemeralMessage, for: self.channelId, syncOwnReactions: true, cache: nil)
        }

        // Check the relevant ephemeral message is not shown in channel
        XCTAssertEqual(controller.messages.map(\.id), [message1].map(\.id))
    }

    func test_deletedMessages_withVisibleForCurrentUser_messageVisibility() throws {
        // Simulate the config setting
        client.databaseContainer.viewContext.deletedMessagesVisibility = .visibleForCurrentUser

        let currentUserID: UserId = .unique

        // Create current user
        try client.databaseContainer.createCurrentUser(id: currentUserID)

        // Create a channel
        try client.databaseContainer.createChannel(cid: channelId, withMessages: false)

        // Create incoming deleted message
        let incomingDeletedMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            deletedAt: .unique
        )

        // Create outgoing deleted message
        let outgoingDeletedMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: currentUserID,
            deletedAt: .unique
        )

        try client.databaseContainer.writeSynchronously {
            try $0.saveMessage(payload: incomingDeletedMessage, for: self.channelId, syncOwnReactions: true, cache: nil)
            try $0.saveMessage(payload: outgoingDeletedMessage, for: self.channelId, syncOwnReactions: true, cache: nil)
        }

        // Only outgoing deleted messages are returned by controller
        XCTAssertEqual(controller.messages.map(\.id), [outgoingDeletedMessage.id])
    }

    func test_deletedMessages_withAlwaysHidden_messageVisibility() throws {
        // Simulate the config setting
        client.databaseContainer.viewContext.deletedMessagesVisibility = .alwaysHidden

        let currentUserID: UserId = .unique

        // Create current user
        try client.databaseContainer.createCurrentUser(id: currentUserID)

        // Create a channel
        try client.databaseContainer.createChannel(cid: channelId, withMessages: false)

        // Create incoming deleted message
        let incomingDeletedMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            deletedAt: .unique
        )

        // Create outgoing deleted message
        let outgoingDeletedMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: currentUserID,
            deletedAt: .unique
        )

        try client.databaseContainer.writeSynchronously {
            try $0.saveMessage(payload: incomingDeletedMessage, for: self.channelId, syncOwnReactions: true, cache: nil)
            try $0.saveMessage(payload: outgoingDeletedMessage, for: self.channelId, syncOwnReactions: true, cache: nil)
        }

        // Both outgoing and incoming messages should NOT be visible
        XCTAssertTrue(controller.messages.isEmpty)
    }

    func test_deletedMessages_withAlwaysVisible_messageVisibility() throws {
        // Simulate the config setting
        client.databaseContainer.viewContext.deletedMessagesVisibility = .alwaysVisible

        let currentUserID: UserId = .unique

        // Create current user
        try client.databaseContainer.createCurrentUser(id: currentUserID)

        // Create a channel
        try client.databaseContainer.createChannel(cid: channelId, withMessages: false)

        // Create incoming deleted message
        let incomingDeletedMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            deletedAt: .unique
        )

        // Create outgoing deleted message
        let outgoingDeletedMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: currentUserID,
            deletedAt: .unique
        )

        try client.databaseContainer.writeSynchronously {
            try $0.saveMessage(payload: incomingDeletedMessage, for: self.channelId, syncOwnReactions: true, cache: nil)
            try $0.saveMessage(payload: outgoingDeletedMessage, for: self.channelId, syncOwnReactions: true, cache: nil)
        }

        // Both outgoing and incoming messages should be visible
        XCTAssertEqual(Set(controller.messages.map(\.id)), Set([outgoingDeletedMessage.id, incomingDeletedMessage.id]))
    }

    func test_shadowedMessages_whenVisible() throws {
        // Simulate the config setting
        client.databaseContainer.viewContext.shouldShowShadowedMessages = true

        let currentUserID: UserId = .unique

        // Create current user
        try client.databaseContainer.createCurrentUser(id: currentUserID)

        // Create a channel
        try client.databaseContainer.createChannel(cid: channelId, withMessages: false)

        // Create incoming shadowed message
        let shadowedMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            isShadowed: true
        )

        // Create incoming non-shadowed message
        let nonShadowedMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            isShadowed: false
        )

        try client.databaseContainer.writeSynchronously {
            try $0.saveMessage(payload: shadowedMessage, for: self.channelId, syncOwnReactions: true, cache: nil)
            try $0.saveMessage(payload: nonShadowedMessage, for: self.channelId, syncOwnReactions: true, cache: nil)
        }

        // Both messages should be visible
        XCTAssertEqual(Set(controller.messages.map(\.id)), Set([nonShadowedMessage.id, shadowedMessage.id]))
    }

    func test_shadowedMessages_defaultBehavior_isToHide() throws {
        let currentUserID: UserId = .unique

        // Create current user
        try client.databaseContainer.createCurrentUser(id: currentUserID)

        // Create a channel
        try client.databaseContainer.createChannel(cid: channelId, withMessages: false)

        // Create incoming shadowed message
        let shadowedMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            isShadowed: true
        )

        // Create incoming non-shadowed message
        let nonShadowedMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            isShadowed: false
        )

        try client.databaseContainer.writeSynchronously {
            try $0.saveMessage(payload: shadowedMessage, for: self.channelId, syncOwnReactions: true, cache: nil)
            try $0.saveMessage(payload: nonShadowedMessage, for: self.channelId, syncOwnReactions: true, cache: nil)
        }

        // Only non-shadowed message should be visible
        XCTAssertEqual(Set(controller.messages.map(\.id)), Set([nonShadowedMessage.id]))
    }

    // MARK: - Delegate tests

    func test_settingDelegate_leadsToFetchingLocalData() {
        let delegate = ChannelController_Delegate(expectedQueueId: controllerCallbackQueueID)

        // Check initial state
        XCTAssertEqual(controller.state, .initialized)

        controller.delegate = delegate

        // Assert state changed
        AssertAsync.willBeEqual(controller.state, .localDataFetched)
    }

    func test_delegate_isNotifiedAboutStateChanges() throws {
        // Set the delegate
        let delegate = ChannelController_Delegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate

        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)

        // Synchronize
        controller.synchronize()

        // Save channel to database.
        try client.mockDatabaseContainer.createChannel(cid: channelId)

        // Simulate network call response
        env.channelUpdater?.update_completion?(.success(dummyPayload(with: .unique)))

        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .remoteDataFetched)
    }

    func test_delegateContinueToReceiveEvents_afterObserversReset() throws {
        // Assign `ChannelController` that creates new channel
        controller = ChatChannelController(
            channelQuery: ChannelQuery(cid: channelId),
            channelListQuery: nil,
            client: client,
            environment: env.environment,
            isChannelAlreadyCreated: false
        )
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)

        // Setup delegate
        let delegate = ChannelController_Delegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate

        // Simulate `synchronize` call
        controller.synchronize()
        
        // Simulate updater's onChannelCreated call
        env.channelUpdater!.update_onChannelCreated!(channelId)

        // Simulate DB update
        var error = try waitFor {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: self.channelId), query: nil, cache: nil)
            }, completion: $0)
        }
        XCTAssertNil(error)
        let channel = try XCTUnwrap(client.databaseContainer.viewContext.channel(cid: channelId)).asModel()
        XCTAssertEqual(channel.latestMessages.count, 1)
        let message: ChatMessage = try XCTUnwrap(channel.latestMessages.first)

        // Assert DB observers call delegate updates
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateChannel_channel, .create(channel))
            Assert.willBeEqual(delegate.didUpdateMessages_messages, [.insert(message, index: [0, 0])])
        }

        let newCid: ChannelId = .unique

        // Simulate `onChannelCreated` call that will reset DB observers to observing data with new `cid`
        env.channelUpdater!.update_onChannelCreated?(newCid)

        // Simulate DB update
        error = try waitFor {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: newCid), query: nil, cache: nil)
            }, completion: $0)
        }
        XCTAssertNil(error)
        let newChannel = try XCTUnwrap(client.databaseContainer.viewContext.channel(cid: newCid)).asModel()
        assert(channel.latestMessages.count == 1)
        let newMessage: ChatMessage = newChannel.latestMessages.first!

        // Assert DB observers call delegate updates for new `cid`
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateChannel_channel, .create(newChannel))
            Assert.willBeEqual(delegate.didUpdateMessages_messages, [.insert(newMessage, index: [0, 0])])
        }
    }

    func test_channelMemberEvents_areForwardedToDelegate() throws {
        let delegate = ChannelController_Delegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate

        // Simulate `synchronize()` call
        controller.synchronize()

        // Send notification with event happened in the observed channel
        let event = TestMemberEvent(cid: controller.channelQuery.cid!, memberUserId: .unique)
        let notification = Notification(newEventReceived: event, sender: self)
        client.webSocketClient!.eventNotificationCenter.post(notification)

        // Assert the event is received
        AssertAsync.willBeEqual(delegate.didReceiveMemberEvent_event as? TestMemberEvent, event)
    }

    func test_channelTypingEvents_areForwardedToDelegate() throws {
        let userId: UserId = .unique
        // Create channel in the database
        try client.databaseContainer.createChannel(cid: channelId)
        // Create user in the database
        try client.databaseContainer.createUser(id: userId)

        // Set the queue for delegate calls
        let delegate = ChannelController_Delegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate

        // Simulate `synchronize()` call
        controller.synchronize()

        // Save user as a typing member
        try client.databaseContainer.writeSynchronously { session in
            let channel = try XCTUnwrap(session.channel(cid: self.channelId))
            let user = try XCTUnwrap(session.user(id: userId))
            channel.currentlyTypingUsers.insert(user)
        }

        // Load the user
        let typingUser = try XCTUnwrap(client.databaseContainer.viewContext.user(id: userId)).asModel()

        // Assert the delegate receives typing user
        AssertAsync.willBeEqual(delegate.didChangeTypingUsers_typingUsers, [typingUser])
    }

    func test_delegateMethodsAreCalled() throws {
        let delegate = ChannelController_Delegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate

        // Assert the delegate is assigned correctly. We should test this because of the type-erasing we
        // do in the controller.
        XCTAssert(controller.delegate === delegate)

        // Simulate `synchronize()` call
        controller.synchronize()

        // Simulate DB update
        let error = try waitFor {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: self.channelId), query: nil, cache: nil)
            }, completion: $0)
        }
        XCTAssertNil(error)
        let channel = try XCTUnwrap(client.databaseContainer.viewContext.channel(cid: channelId)).asModel()
        XCTAssertEqual(channel.latestMessages.count, 1)
        let message: ChatMessage = try XCTUnwrap(channel.latestMessages.first)

        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateChannel_channel, .create(channel))
            Assert.willBeEqual(delegate.didUpdateMessages_messages, [.insert(message, index: [0, 0])])
        }
    }

    func test_channelUpdateDelegate_isCalled_whenChannelReadsAreUpdated() throws {
        let delegate = ChannelController_Delegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate

        let userId: UserId = .unique

        let originalReadDate: Date = .unique

        // Create a channel in the DB
        try client.databaseContainer.writeSynchronously {
            try $0.saveChannel(payload: self.dummyPayload(with: self.channelId), query: nil, cache: nil)
            // Create a read for the channel
            try $0.saveChannelRead(
                payload: ChannelReadPayload(
                    user: self.dummyUser(id: userId),
                    lastReadAt: originalReadDate,
                    lastReadMessageId: .unique,
                    unreadMessagesCount: .unique // This value doesn't matter at all. It's not updated by events. We cam ignore it.
                ),
                for: self.channelId,
                cache: nil
            )
        }

        XCTAssertEqual(
            controller.channel?.reads.first(where: { $0.user.id == userId })?.lastReadAt,
            originalReadDate
        )

        // Simulate `synchronize()` call
        controller.synchronize()

        let newReadDate: Date = .unique

        // Update the read
        try client.databaseContainer.writeSynchronously {
            let read = try XCTUnwrap($0.loadChannelRead(cid: self.channelId, userId: userId))
            read.lastReadAt = newReadDate.bridgeDate
        }

        // Assert the value is updated and the delegate is called
        XCTAssertEqual(
            controller.channel?.reads.first(where: { $0.user.id == userId })?.lastReadAt,
            newReadDate
        )

        AssertAsync.willBeEqual(delegate.didUpdateChannel_channel, .update(controller.channel!))
    }

    // MARK: - New direct message channel creation tests

    func test_controller_reportsInitialValues_forDMChannel_ifChannelDoesntExistLocally() throws {
        // Create mock users
        let currentUserId = UserId.unique
        let otherUserId = UserId.unique

        // Create controller for the non-existent new DM channel
        setupControllerForNewDirectMessageChannel(currentUserId: currentUserId, otherUserId: otherUserId)

        // Create and set delegate
        let delegate = ChannelController_Delegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate

        // Simulate synchronize
        controller.synchronize()

        // Create dummy channel with messages
        let dummyChannel = dummyPayload(
            with: .unique,
            numberOfMessages: 10,
            members: [
                .dummy(user: .dummy(userId: currentUserId)),
                .dummy(user: .dummy(userId: otherUserId))
            ]
        )

        // Simulate successful backend channel creation
        env.channelUpdater!.update_onChannelCreated?(dummyChannel.channel.cid)
        
        // Simulate new channel creation in DB
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: dummyChannel)
        }

        // Simulate successful network call
        env.channelUpdater!.update_completion?(.success(dummyPayload(with: .unique)))

        // Assert that initial reported values are correct
        XCTAssertEqual(controller.channel?.cid, dummyChannel.channel.cid)
        XCTAssertEqual(controller.messages.count, dummyChannel.messages.count)

        // Assert the delegate is called for initial values
        XCTAssertEqual(delegate.didUpdateChannel_channel?.item.cid, dummyChannel.channel.cid)
        XCTAssertEqual(delegate.didUpdateMessages_messages?.count, dummyChannel.messages.count)
    }

    func test_controller_reportsInitialValues_forDMChannel_ifChannelExistsLocally() throws {
        // Create mock users
        let currentUserId = UserId.unique
        let otherUserId = UserId.unique

        // Create dummy channel with messages
        let dummyChannel = dummyPayload(
            with: .unique,
            numberOfMessages: 10,
            members: [
                .dummy(user: .dummy(userId: currentUserId)),
                .dummy(user: .dummy(userId: otherUserId))
            ]
        )

        // Simulate new channel creation in DB
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: dummyChannel)
        }

        // Create controller for the existing new DM channel
        setupControllerForNewDirectMessageChannel(currentUserId: currentUserId, otherUserId: otherUserId)

        // Create and set delegate
        let delegate = ChannelController_Delegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate

        // Simulate synchronize
        controller.synchronize()

        // Simulate successful backend channel creation
        env.channelUpdater!.update_onChannelCreated?(dummyChannel.channel.cid)
        
        // Simulate successful network call.
        env.channelUpdater!.update_completion?(.success(dummyPayload(with: .unique)))

        // Since initially the controller doesn't know it's final `cid`, it can't report correct initial values.
        // That's why we simulate delegate callbacks for initial values.
        // Assert that delegate gets initial values as callback
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateChannel_channel?.item.cid, dummyChannel.channel.cid)
            Assert.willBeEqual(delegate.didUpdateMessages_messages?.count, dummyChannel.messages.count)
        }
    }

    // MARK: - New channel creation tests

    func test_controller_reportsInitialValues_forNewChannel_ifChannelDoesntExistLocally() throws {
        // Create controller for the non-existent new DM channel
        setupControllerForNewMessageChannel(cid: channelId)

        // Simulate synchronize
        controller.synchronize()

        // Create dummy channel with messages
        let dummyChannel = dummyPayload(
            with: channelId,
            numberOfMessages: 10,
            members: [.dummy()]
        )

        // Simulate successful backend channel creation
        env.channelUpdater!.update_onChannelCreated?(dummyChannel.channel.cid)
        
        // Simulate new channel creation in DB
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: dummyChannel)
        }

        // Simulate successful network call
        env.channelUpdater!.update_completion?(.success(dummyPayload(with: .unique)))

        // Assert that initial reported values are correct
        XCTAssertEqual(controller.channel?.cid, dummyChannel.channel.cid)
        XCTAssertEqual(controller.messages.count, dummyChannel.messages.count)
    }

    func test_controller_reportsInitialValues_forNewChannel_ifChannelExistsLocally() throws {
        // Create dummy channel with messages
        let dummyChannel = dummyPayload(
            with: channelId,
            numberOfMessages: 10,
            members: [.dummy()]
        )

        // Simulate new channel creation in DB
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: dummyChannel)
        }

        // Create controller for the existing new DM channel
        setupControllerForNewMessageChannel(cid: channelId)

        // Unlike new DM ChannelController, this ChannelController knows it's final `cid` so it should be able to fetch initial values
        // from DB, without the `synchronize` call
        // Assert that initial reported values are correct
        XCTAssertEqual(controller.channel?.cid, dummyChannel.channel.cid)
        XCTAssertEqual(controller.messages.count, dummyChannel.messages.count)
    }

    // MARK: - Updating channel

    func test_updateChannel_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `updateChannel` call and assert the error is returned
        var error: Error? = try waitFor { [callbackQueueID] completion in
            controller.updateChannel(name: .unique, imageURL: .unique(), team: nil, extraData: .init()) { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_onChannelCreated?(query.cid!)

        // Simulate `updateChannel` call and assert no error is returned
        error = try waitFor { [callbackQueueID] completion in
            controller.updateChannel(name: .unique, imageURL: .unique(), team: nil, extraData: .init()) { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
            env.channelUpdater!.updateChannel_completion?(nil)
        }
        XCTAssertNil(error)
    }

    func test_updateChannel_callsChannelUpdater() {
        // Simulate `updateChannel` call and catch the completion
        var completionCalled = false
        controller.updateChannel(name: .unique, imageURL: .unique(), team: .unique, extraData: .init()) { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Assert payload is passed to `channelUpdater`, completion is not called yet
        XCTAssertNotNil(env.channelUpdater!.updateChannel_payload)

        // Simulate successful update
        env.channelUpdater!.updateChannel_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.updateChannel_completion = nil

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_updateChannel_propagesErrorFromUpdater() {
        // Simulate `updateChannel` call and catch the completion
        var completionCalledError: Error?
        controller.updateChannel(name: .unique, imageURL: .unique(), team: .unique, extraData: .init()) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.updateChannel_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // MARK: - Channel partial update

    func test_partialChannelUpdate_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        var receivedError: Error?
        let expectation = self.expectation(description: "partialChannelUpdate completes")
        controller.partialChannelUpdate { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            receivedError = error
            expectation.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)
        XCTAssert(receivedError is ClientError.ChannelNotCreatedYet)
    }

    func test_partialChannelUpdate_propagatesSuccess() throws {
        let name = "Jason Bourne"
        let imageURL: URL? = nil
        let team = "team-one"
        let members: Set<UserId> = ["member1", "member2"]
        let invites: Set<UserId> = ["invite1"]
        let extraData: [String: RawJSON] = ["scope": "test"]
        let unsetProperties: [String] = ["user.id", "channel_store"]

        var receivedError: Error?
        let expectation = self.expectation(description: "partialChannelUpdate completes")
        controller.partialChannelUpdate(
            name: name,
            imageURL: imageURL,
            team: team,
            members: members,
            invites: invites,
            extraData: extraData,
            unsetProperties: unsetProperties
        ) { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            receivedError = error
            expectation.fulfill()
        }

        let updater = try XCTUnwrap(env.channelUpdater)

        // Simulate successful update
        updater.partialChannelUpdate_completion?(nil)
        updater.partialChannelUpdate_completion = nil

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(updater.partialChannelUpdate_updates?.name, name)
        XCTAssertEqual(updater.partialChannelUpdate_updates?.imageURL, imageURL)
        XCTAssertEqual(updater.partialChannelUpdate_updates?.team, team)
        XCTAssertEqual(updater.partialChannelUpdate_updates?.members, members)
        XCTAssertEqual(updater.partialChannelUpdate_updates?.invites, invites)
        XCTAssertEqual(updater.partialChannelUpdate_updates?.extraData, extraData)
        XCTAssertEqual(updater.partialChannelUpdate_unsetProperties, unsetProperties)
        XCTAssertNil(receivedError)
    }

    func test_partialChannelUpdate_propagatesError() throws {
        var receivedError: Error?
        let expectation = self.expectation(description: "partialChannelUpdate completes")
        controller.partialChannelUpdate(
            name: .unique,
            imageURL: .unique(),
            team: .unique,
            members: [],
            invites: [],
            extraData: [:],
            unsetProperties: []
        ) { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            receivedError = error
            expectation.fulfill()
        }

        let updater = try XCTUnwrap(env.channelUpdater)

        // Simulate failed update
        let testError = TestError()
        updater.partialChannelUpdate_completion?(testError)
        updater.partialChannelUpdate_completion = nil

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(receivedError, testError)
    }

    // MARK: - Muting channel

    func test_muteChannel_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `muteChannel` call and assert error is returned
        var error: Error? = try waitFor { [callbackQueueID] completion in
            controller.muteChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_onChannelCreated?(query.cid!)

        // Simulate `muteChannel` call and assert no error is returned
        error = try waitFor { [callbackQueueID] completion in
            controller.muteChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
            env.channelUpdater!.muteChannel_completion?(nil)
        }

        XCTAssertNil(error)
    }

    func test_muteChannel_callsChannelUpdater() {
        // Simulate `muteChannel` call and catch the completion
        var completionCalled = false
        controller.muteChannel { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Assert cid and muted state are passed to `channelUpdater`, completion is not called yet
        XCTAssertEqual(env.channelUpdater!.muteChannel_cid, channelId)
        XCTAssertEqual(env.channelUpdater!.muteChannel_mute, true)
        XCTAssertFalse(completionCalled)

        // Simulate successful update
        env.channelUpdater!.muteChannel_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.muteChannel_completion = nil

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_muteChannel_propagatesErrorFromUpdater() {
        // Simulate `muteChannel` call and catch the completion
        var completionCalledError: Error?
        controller.muteChannel { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.muteChannel_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // MARK: - Unmuting channel

    func test_unmuteChannel_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `unmuteChannel` call and assert error is returned
        var error: Error? = try waitFor { [callbackQueueID] completion in
            controller.muteChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_onChannelCreated?(query.cid!)

        // Simulate `unmuteChannel` call and assert no error is returned
        error = try waitFor { [callbackQueueID] completion in
            controller.unmuteChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
            env.channelUpdater!.muteChannel_completion?(nil)
        }

        XCTAssertNil(error)
    }

    func test_unmuteChannel_callsChannelUpdater() {
        // Simulate `unmuteChannel` call and catch the completion
        var completionCalled = false
        controller.unmuteChannel { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Assert cid and muted state are passed to `channelUpdater`, completion is not called yet
        XCTAssertEqual(env.channelUpdater!.muteChannel_cid, channelId)
        XCTAssertEqual(env.channelUpdater!.muteChannel_mute, false)
        XCTAssertFalse(completionCalled)

        // Simulate successful update
        env.channelUpdater!.muteChannel_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.muteChannel_completion = nil

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_unmuteChannel_propagatesErrorFromUpdater() {
        // Simulate `unmuteChannel` call and catch the completion
        var completionCalledError: Error?
        controller.unmuteChannel { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.muteChannel_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // MARK: - Deleting channel

    func test_deleteChannel_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `deleteChannel` call and assert error is returned
        var error: Error? = try waitFor { [callbackQueueID] completion in
            controller.deleteChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_onChannelCreated?(query.cid!)

        // Simulate `deleteChannel` call and assert no error is returned
        error = try waitFor { [callbackQueueID] completion in
            controller.deleteChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
            env.channelUpdater!.deleteChannel_completion?(nil)
        }

        XCTAssertNil(error)
    }

    func test_deleteChannel_callsChannelUpdater() {
        // Simulate `deleteChannel` calls and catch the completion
        var completionCalled = false
        controller.deleteChannel { [callbackQueueID] error in
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
        XCTAssertEqual(env.channelUpdater?.deleteChannel_cid, channelId)

        // Simulate successful update
        env.channelUpdater?.deleteChannel_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.deleteChannel_completion = nil

        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_deleteChannel_callsChannelUpdaterWithError() {
        // Simulate `muteChannel` call and catch the completion
        var completionCalledError: Error?
        controller.deleteChannel { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.deleteChannel_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // MARK: - Truncating channel

    func test_truncateChannel_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `truncateChannel` call and assert error is returned
        var error: Error? = try waitFor { [callbackQueueID] completion in
            controller.truncateChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_onChannelCreated?(query.cid!)

        // Simulate `truncateChannel` call and assert no error is returned
        error = try waitFor { [callbackQueueID] completion in
            controller.truncateChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
            env.channelUpdater!.truncateChannel_completion?(nil)
        }

        XCTAssertNil(error)
    }

    func test_truncateChannel_callsChannelUpdater() {
        // Simulate `truncateChannel` calls and catch the completion
        var completionCalled = false
        controller.truncateChannel { [callbackQueueID] error in
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
        XCTAssertEqual(env.channelUpdater?.truncateChannel_cid, channelId)

        // Simulate successful update
        env.channelUpdater?.truncateChannel_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.truncateChannel_completion = nil

        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_truncateChannel_callsChannelUpdaterWithError() {
        // Simulate `truncateChannel` call and catch the completion
        var completionCalledError: Error?
        controller.truncateChannel { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.truncateChannel_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // MARK: - Hiding channel

    func test_hideChannel_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `hideChannel` call and assert error is returned
        var error: Error? = try waitFor { [callbackQueueID] completion in
            controller.hideChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_onChannelCreated?(query.cid!)

        // Simulate `hideChannel` call and assert no error is returned
        error = try waitFor { [callbackQueueID] completion in
            controller.hideChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
            env.channelUpdater!.hideChannel_completion?(nil)
        }

        XCTAssertNil(error)
    }

    func test_hideChannel_callsChannelUpdater() {
        // Simulate `hideChannel` calls and catch the completion
        var completionCalled = false
        controller.hideChannel(clearHistory: false) { [callbackQueueID] error in
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
        XCTAssertEqual(env.channelUpdater?.hideChannel_cid, channelId)
        XCTAssertEqual(env.channelUpdater?.hideChannel_clearHistory, false)

        // Simulate successful update
        env.channelUpdater?.hideChannel_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.hideChannel_completion = nil

        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_hideChannel_callsChannelUpdaterWithError() {
        // Simulate `hideChannel` call and catch the completion
        var completionCalledError: Error?
        controller.hideChannel(clearHistory: false) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.hideChannel_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // MARK: - Showing channel

    func test_showChannel_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `showChannel` call and assert error is returned
        var error: Error? = try waitFor { [callbackQueueID] completion in
            controller.showChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_onChannelCreated?(query.cid!)

        // Simulate `showChannel` call and assert no error is returned
        error = try waitFor { [callbackQueueID] completion in
            controller.showChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
            env.channelUpdater!.showChannel_completion?(nil)
        }

        XCTAssertNil(error)
    }

    func test_showChannel_callsChannelUpdater() {
        // Simulate `showChannel` calls and catch the completion
        var completionCalled = false
        controller.showChannel { [callbackQueueID] error in
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
        XCTAssertEqual(env.channelUpdater?.showChannel_cid, channelId)

        // Simulate successful update
        env.channelUpdater?.showChannel_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.showChannel_completion = nil

        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_showChannel_callsChannelUpdaterWithError() {
        // Simulate `showChannel` call and catch the completion
        var completionCalledError: Error?
        controller.showChannel { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.showChannel_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // MARK: - `loadPreviousMessages`

    func test_loadPreviousMessages_callsChannelUpdater() throws {
        let channel = try setupChannel(channelPayload: dummyPayload(with: channelId, numberOfMessages: 1))
        let messageId = channel.messages.first?.id

        var completionCalled = false
        controller.loadPreviousMessages(before: messageId, limit: 25) { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        // Assert correct `MessagesPagination` is created
        XCTAssertEqual(
            env!.channelUpdater?.update_channelQuery?.pagination,
            MessagesPagination(pageSize: 25, parameter: .lessThan(messageId!))
        )

        // Simulate successful update
        let channelPayload = dummyPayload(
            with: .unique,
            numberOfMessages: 5
        )
        env.channelUpdater?.update_completion?(.success(channelPayload))

        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_loadPreviousMessages_whenHasLoadedAllPreviousMessages_dontCallChannelUpdater() throws {
        env.channelUpdater?.mockPaginationState.hasLoadedAllPreviousMessages = true

        let exp = expectation(description: "should still call the completion block")
        controller.loadPreviousMessages(before: .unique, limit: 5) { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        env.channelUpdater?
            .update_completion?(.success(dummyPayload(
                with: .unique,
                numberOfMessages: 1
            )))

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(env.channelUpdater?.update_callCount, 0)
    }

    func test_loadPreviousMessages_whenIsLoadingPreviousMessages_shouldNotCallChannelUpdater() throws {
        env.channelUpdater?.mockPaginationState.isLoadingPreviousMessages = true

        let exp = expectation(description: "should still call the completion block")
        controller.loadPreviousMessages(before: .unique, limit: 5) { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        env.channelUpdater?
            .update_completion?(.success(dummyPayload(
                with: .unique,
                numberOfMessages: 1
            )))

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(env.channelUpdater?.update_callCount, 0)
    }

    func test_loadPreviousMessages_throwsError_on_emptyMessages() throws {
        // Simulate `loadPreviousMessages` call and assert error is returned
        let error: Error? = try waitFor { [callbackQueueID] completion in
            controller.loadPreviousMessages { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelEmptyMessages)
    }

    func test_loadPreviousMessages_callsChannelUpdaterWithError() throws {
        try setupChannel(channelPayload: dummyPayload(with: channelId, numberOfMessages: 1))

        // Simulate `loadPreviousMessages` call and catch the completion
        var completionCalledError: Error?
        controller.loadPreviousMessages(before: .unique) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.update_completion?(.failure(testError))

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    func test_loadPreviousMessages_usesPassedMessageId() throws {
        let expectation = self.expectation(description: "synchronize completes")
        controller.synchronize { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        // Generate messages bigger than pageSize (25)
        let messages: [MessagePayload] = MessagePayload.multipleDummies(amount: 30)
        let payload = ChannelPayload.dummy(messages: messages)
        env.channelUpdater?.update_completion?(.success(payload))

        waitForExpectations(timeout: defaultTimeout)

        let expectation2 = self.expectation(description: "loadPreviousMessage completes")
        var receivedError: Error?
        controller.loadPreviousMessages(before: "3") { error in
            receivedError = error
            expectation2.fulfill()
        }

        let error = TestError()
        env.channelUpdater!.update_completion?(.failure(error))

        waitForExpectations(timeout: defaultTimeout)

        let paginationParameter = env.channelUpdater?.update_channelQuery?.pagination?.parameter
        guard case let .lessThan(paginationMessageId) = paginationParameter else {
            XCTFail("Missing pagination parameter")
            return
        }
        XCTAssertEqual(paginationMessageId, "3")
        XCTAssertEqual(receivedError, error)
    }

    func test_loadPreviousMessages_usesLastFetchedId() throws {
        let lastFetchedId = MessageId.unique
        env.channelUpdater?.mockPaginationState.oldestFetchedMessage = .dummy(messageId: lastFetchedId)

        let exp = expectation(description: "loadPreviousMessage completes")
        var receivedError: Error?
        controller.loadPreviousMessages() { error in
            receivedError = error
            exp.fulfill()
        }

        let error = TestError()
        env.channelUpdater!.update_completion?(.failure(error))

        waitForExpectations(timeout: defaultTimeout)

        let paginationParameter = env.channelUpdater?.update_channelQuery?.pagination?.parameter
        guard case let .lessThan(paginationMessageId) = paginationParameter else {
            XCTFail("Missing pagination parameter")
            return
        }
        XCTAssertEqual(paginationMessageId, lastFetchedId)
        XCTAssertEqual(receivedError, error)
    }

    func test_loadPreviousMessages_usesLastLocalId_whenThereIsNot_lastFetchedId() throws {
        // We purposefully don't perform a synchronize. We are trying to simulate a case where a synchronize call fails.
        // We store some messages in the database so those can be used to try to paginate.
        let oldestPendingId = "oldest-pending"
        let newestId = "newest-notpending"
        let messages: [MessagePayload] = [
            .dummy(
                messageId: oldestPendingId,
                authorUserId: "1",
                updatedAt: Date().addingTimeInterval(100)
            ),
            .dummy(
                messageId: newestId,
                authorUserId: "1",
                updatedAt: Date()
            )
        ]
        let payload = dummyPayload(with: channelId, messages: messages)
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: payload)
            let pendingMessage = session.message(id: oldestPendingId)
            pendingMessage?.localMessageState = .pendingSend
        }

        let expectation2 = expectation(description: "loadPreviousMessage completes")
        var receivedError: Error?
        controller.loadPreviousMessages() { error in
            receivedError = error
            expectation2.fulfill()
        }

        let error = TestError()
        env.channelUpdater!.update_completion?(.failure(error))

        waitForExpectations(timeout: defaultTimeout)

        let paginationParameter = env.channelUpdater?.update_channelQuery?.pagination?.parameter
        guard case let .lessThan(paginationMessageId) = paginationParameter else {
            XCTFail("Missing pagination parameter")
            return
        }

        // Should use the latest message in database that is also available on the server
        XCTAssertEqual(paginationMessageId, newestId)
        XCTAssertEqual(receivedError, error)
    }
    
    // MARK: - `loadNextMessages`

    func test_loadNextMessages() throws {
        var messageId: MessageId?

        // Create new channel with message in DB
        let channel = try setupChannel(channelPayload: dummyPayload(
            with: channelId,
            numberOfMessages: 20
        ), withAllNextMessagesLoaded: false)

        messageId = channel.messages.first?.id

        var completionCalled = false
        controller.loadNextMessages(after: messageId, limit: 25) { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        // Assert correct `MessagesPagination` is created
        AssertAsync.willBeEqual(
            env!.channelUpdater?.update_channelQuery?.pagination,
            MessagesPagination(pageSize: 25, parameter: .greaterThan(messageId!))
        )

        // Simulate successful update
        let channelPayload = dummyPayload(with: .unique, numberOfMessages: 5)
        env.channelUpdater?.update_completion?(.success(channelPayload))

        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_loadNextMessages_whenEmptyMessages() throws {
        // Simulate `loadNextMessages` call and assert error is returned
        let error: Error? = try waitFor { [callbackQueueID] completion in
            controller.loadNextMessages { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelEmptyMessages)
    }

    func test_loadNextMessages_callsChannelUpdaterWithError() throws {
        try setupChannel(
            channelPayload: dummyPayload(with: channelId, numberOfMessages: 20),
            withAllNextMessagesLoaded: false
        )

        var completionCalledError: Error?
        let exp = expectation(description: "load next messages completion called")
        controller.loadNextMessages(after: .unique) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
            exp.fulfill()
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater?.update_completion?(.failure(testError))

        waitForExpectations(timeout: defaultTimeout)

        // Completion should be called with the error
        XCTAssertEqual(completionCalledError as? TestError, testError)
    }

    func test_loadNextMessages_whenHasLoadedAllNextMessages_shouldNotCallChannelUpdater() throws {
        // Create new channel
        try setupChannel(
            channelPayload: dummyPayload(with: channelId),
            withAllNextMessagesLoaded: true
        )

        let exp = expectation(description: "should still call the completion block")
        controller.loadNextMessages() { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(env.channelUpdater?.update_callCount, 0)
    }

    func test_loadNextMessages_whenIsLoadingNextMessages_shouldNotCallChannelUpdater() throws {
        env.channelUpdater?.mockPaginationState.isLoadingNextMessages = true
        env.channelUpdater?.mockPaginationState.hasLoadedAllNextMessages = false

        let exp = expectation(description: "should still call the completion block")
        controller.loadNextMessages(after: .unique) { error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(env.channelUpdater?.update_callCount, 0)
    }

    func test_loadNextMessages_usesPassedMessageId() throws {
        try setupChannel(withAllNextMessagesLoaded: false)

        let exp = expectation(description: "loadNextMessage completes")
        var receivedError: Error?
        controller.loadNextMessages(after: "3") { error in
            receivedError = error
            exp.fulfill()
        }

        let error = TestError()
        env.channelUpdater!.update_completion?(.failure(error))

        waitForExpectations(timeout: defaultTimeout)

        let paginationParameter = env.channelUpdater?.update_channelQuery?.pagination?.parameter
        guard case let .greaterThan(paginationMessageId) = paginationParameter else {
            XCTFail("Missing pagination parameter")
            return
        }
        XCTAssertEqual(paginationMessageId, "3")
        XCTAssertEqual(receivedError, error)
    }

    func test_loadNextMessages_usesLastFetchedId() throws {
        try setupChannel(withAllNextMessagesLoaded: false)
        
        let lastFetchedId = MessageId.unique
        env.channelUpdater?.mockPaginationState.newestFetchedMessage = .dummy(messageId: lastFetchedId)

        let exp = expectation(description: "loadNextMessage completes")
        var receivedError: Error?
        controller.loadNextMessages() { error in
            receivedError = error
            exp.fulfill()
        }

        let error = TestError()
        env.channelUpdater!.update_completion?(.failure(error))

        waitForExpectations(timeout: defaultTimeout)

        let paginationParameter = env.channelUpdater?.update_channelQuery?.pagination?.parameter
        guard case let .greaterThan(paginationMessageId) = paginationParameter else {
            XCTFail("Missing pagination parameter")
            return
        }
        XCTAssertEqual(paginationMessageId, lastFetchedId)
        XCTAssertEqual(receivedError, error)
    }

    // MARK: - Load messages around given message id.

    func test_loadPageAroundMessageId() throws {
        // Create dummy channel with messages
        let dummyChannel = dummyPayload(
            with: channelId,
            numberOfMessages: 10
        )
        let messageId: MessageId = .unique

        // Simulate new channel creation in DB
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: dummyChannel)
        }

        var completionCalled = false
        controller.loadPageAroundMessageId(messageId, limit: 5) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Simulate successful update
        let expectedMessages: [MessagePayload] = [
            .dummy(),
            .dummy(),
            .dummy(),
            .dummy(),
            .dummy()
        ]
        env.channelUpdater?
            .update_completion?(.success(dummyPayload(
                with: .unique,
                messages: expectedMessages
            )))

        // Assert correct `MessagesPagination` is created
        let pagination = env!.channelUpdater?.update_channelQuery?.pagination
        XCTAssertEqual(pagination?.pageSize, 5)
        XCTAssertEqual(pagination?.parameter?.parameters as! [String: String], ["id_around": messageId])

        AssertAsync.willBeTrue(completionCalled)

        // Should not leak memory
        weak var weakController = controller
        controller = nil
        env.channelUpdater!.update_completion = nil
        AssertAsync.canBeReleased(&weakController)
    }

    func test_loadPageAroundMessageId_whenChannelNotYetCreated() throws {
        controller = ChatChannelController(
            channelQuery: .init(cid: channelId),
            channelListQuery: nil,
            client: client,
            isChannelAlreadyCreated: false
        )
        let exp = expectation(description: "load message around completes")
        controller.loadPageAroundMessageId(.unique, limit: 5) { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_loadPageAroundMessageId_whenRequestFails() throws {
        // Create dummy channel with messages
        let dummyChannel = dummyPayload(
            with: channelId,
            numberOfMessages: 10
        )
        let messageId: MessageId = .unique

        // Simulate new channel creation in DB
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: dummyChannel)
        }

        let exp = expectation(description: "should complete load messages around")
        controller.loadPageAroundMessageId(messageId, limit: 5) { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        }

        env.channelUpdater?.update_completion?(.failure(ClientError("fake")))

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_loadPageAroundMessageId_whenIsLoadingMessagesAround_shouldNotCallChannelUpdater() throws {
        env.channelUpdater?.mockPaginationState.isLoadingMiddleMessages = true

        let exp = expectation(description: "should still call the completion block")
        controller.loadPageAroundMessageId(.unique) { error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(env.channelUpdater?.update_callCount, 0)
    }

    // MARK: - loadFirstPage

    func test_loadFirstPage_shouldCallSynchronize_shouldChangeChannelQueryPagination() throws {
        // Create new channel
        try setupChannel(channelPayload: .dummy())

        let controller = ChatChannelController(
            channelQuery: .init(cid: channelId, paginationParameter: .around(.unique)),
            channelListQuery: nil,
            client: client,
            environment: env.environment
        )

        let exp = expectation(description: "loadFirstPage should complete")
        controller.loadFirstPage { _ in
            exp.fulfill()
        }

        env.channelUpdater?.update_completion?(.success(.dummy()))

        waitForExpectations(timeout: defaultTimeout)

        AssertAsync.willBeEqual(env.channelUpdater?.update_channelQuery?.pagination?.parameter, nil)
        AssertAsync.willBeEqual(env.channelUpdater?.update_callCount, 1)
    }
    
    // MARK: - Keystroke

    func test_keystroke() throws {
        let payload = dummyPayload(with: channelId, ownCapabilities: [ChannelCapability.sendTypingEvents.rawValue])
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        controller.sendKeystrokeEvent {
            XCTAssertNil($0)
        }

        // Simulate `keystroke` call and catch the completion
        var completionCalledError: Error?
        controller.sendKeystrokeEvent { completionCalledError = $0 }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Check keystroke cid.
        XCTAssertEqual(env.eventSender!.keystroke_cid, channelId)

        // Simulate failed update
        let testError = TestError()
        env.eventSender!.keystroke_completion!(testError)
        // Release reference of completion so we can deallocate stuff
        env.eventSender!.keystroke_completion = nil

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_keystroke_withParentMessageId() throws {
        let payload = dummyPayload(with: channelId, ownCapabilities: [ChannelCapability.sendTypingEvents.rawValue])
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        let parentMessageId = MessageId.unique

        // Simulate `keystroke` call and catch the completion
        var completionCalledError: Error?
        controller.sendKeystrokeEvent(parentMessageId: parentMessageId) { completionCalledError = $0 }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Check keystroke cid and parentMessageId.
        XCTAssertEqual(env.eventSender!.keystroke_cid, channelId)
        XCTAssertEqual(env.eventSender!.keystroke_parentMessageId, parentMessageId)

        // Simulate failed update
        let testError = TestError()
        env.eventSender!.keystroke_completion!(testError)
        // Release reference of completion so we can deallocate stuff
        env.eventSender!.keystroke_completion = nil

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_startTyping() throws {
        let payload = dummyPayload(with: channelId, ownCapabilities: [ChannelCapability.sendTypingEvents.rawValue])
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        controller.sendStartTypingEvent {
            XCTAssertNil($0)
        }

        // Simulate `startTyping` call and catch the completion
        var completionCalledError: Error?
        controller.sendStartTypingEvent { completionCalledError = $0 }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Check `startTyping` cid.
        XCTAssertEqual(env.eventSender!.startTyping_cid, channelId)

        // Simulate failed update
        let testError = TestError()
        env.eventSender!.startTyping_completion!(testError)
        // Release reference of completion so we can deallocate stuff
        env.eventSender!.startTyping_completion = nil

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_startTyping_withParentMessageId() throws {
        let payload = dummyPayload(with: channelId, ownCapabilities: [ChannelCapability.sendTypingEvents.rawValue])
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        let parentMessageId = MessageId.unique

        // Simulate `startTyping` call and catch the completion
        var completionCalledError: Error?
        controller.sendStartTypingEvent(parentMessageId: parentMessageId) { completionCalledError = $0 }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Check `startTyping` cid and parentMessageId.
        XCTAssertEqual(env.eventSender!.startTyping_cid, channelId)
        XCTAssertEqual(env.eventSender!.startTyping_parentMessageId, parentMessageId)

        // Simulate failed update
        let testError = TestError()
        env.eventSender!.startTyping_completion!(testError)
        // Release reference of completion so we can deallocate stuff
        env.eventSender!.startTyping_completion = nil

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_stopTyping() throws {
        let payload = dummyPayload(with: channelId, ownCapabilities: [ChannelCapability.sendTypingEvents.rawValue])
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        controller.sendStopTypingEvent {
            XCTAssertNil($0)
        }

        // Simulate `stopTyping` call and catch the completion
        var completionCalledError: Error?
        controller.sendStopTypingEvent { completionCalledError = $0 }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Check `stopTyping` cid.
        XCTAssertEqual(env.eventSender!.stopTyping_cid, channelId)

        // Simulate failed update
        let testError = TestError()
        env.eventSender!.stopTyping_completion!(testError)
        // Release reference of completion so we can deallocate stuff
        env.eventSender!.stopTyping_completion = nil

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_stopTyping_withParentMessageId() throws {
        let payload = dummyPayload(with: channelId, ownCapabilities: [ChannelCapability.sendTypingEvents.rawValue])
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        let parentMessageId = MessageId.unique

        // Simulate `stopTyping` call and catch the completion
        var completionCalledError: Error?
        controller.sendStopTypingEvent(parentMessageId: parentMessageId) { completionCalledError = $0 }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Check `stopTyping` cid and parentMessageId.
        XCTAssertEqual(env.eventSender!.stopTyping_cid, channelId)
        XCTAssertEqual(env.eventSender!.stopTyping_parentMessageId, parentMessageId)

        // Simulate failed update
        let testError = TestError()
        env.eventSender!.stopTyping_completion!(testError)
        // Release reference of completion so we can deallocate stuff
        env.eventSender!.stopTyping_completion = nil

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_sendKeystrokeEvent_whenTypingEventsAreDisabled_doesNothing() throws {
        let payload = dummyPayload(with: channelId, ownCapabilities: [])
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        var completionCalled = false

        let error: Error? = try waitFor { completion in
            controller.sendKeystrokeEvent {
                completionCalled = true
                completion($0)
            }
        }

        XCTAssertTrue(completionCalled)
        XCTAssertNil(error)
    }

    func test_sendStartTypingEvent_whenTypingEventsAreDisabled_errors() throws {
        let payload = dummyPayload(with: channelId, ownCapabilities: [])
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        var completionCalled = false

        let error: Error? = try waitFor { completion in
            controller.sendStartTypingEvent {
                completionCalled = true
                completion($0)
            }
        }

        XCTAssertTrue(completionCalled)
        XCTAssertNotNil(error)

        guard let channelFeatureError = error as? ClientError.ChannelFeatureDisabled else {
            XCTFail()
            return
        }

        XCTAssertEqual(channelFeatureError.localizedDescription, "Channel feature: typing events is disabled for this channel.")
    }

    func test_sendStopTypingEvent_whenTypingEventsAreDisabled_errors() throws {
        let payload = dummyPayload(with: channelId, ownCapabilities: [])
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        var completionCalled = false

        let error: Error? = try waitFor { completion in
            controller.sendStopTypingEvent {
                completionCalled = true
                completion($0)
            }
        }

        XCTAssertTrue(completionCalled)
        XCTAssertNotNil(error)

        guard let channelFeatureError = error as? ClientError.ChannelFeatureDisabled else {
            XCTFail()
            return
        }

        XCTAssertEqual(channelFeatureError.localizedDescription, "Channel feature: typing events is disabled for this channel.")
    }

    func test_keystroke_keepsControllerAlive() throws {
        // Save channel with typing events enabled to database
        try client.mockDatabaseContainer.writeSynchronously {
            try $0.saveChannel(
                payload: self.dummyPayload(
                    with: self.channelId,
                    ownCapabilities: [ChannelCapability.sendTypingEvents.rawValue]
                )
            )
        }

        // Simulate `sendKeystrokeEvent` call.
        controller.sendKeystrokeEvent()

        // Create a weak ref and release a controller.
        weak var weakController = controller
        controller = nil

        // Assert controller is kept alive
        AssertAsync.staysTrue(weakController != nil)
    }

    func test_startTyping_keepsControllerAlive() throws {
        // Save channel with typing events enabled to database
        try client.mockDatabaseContainer.writeSynchronously {
            try $0.saveChannel(
                payload: self.dummyPayload(
                    with: self.channelId,
                    ownCapabilities: [ChannelCapability.sendTypingEvents.rawValue]
                )
            )
        }

        // Simulate `sendStartTypingEvent` call.
        controller.sendStartTypingEvent()

        // Create a weak ref and release a controller.
        weak var weakController = controller
        controller = nil

        // Assert controller is kept alive
        AssertAsync.staysTrue(weakController != nil)
    }

    func test_stopTyping_keepsControllerAlive() throws {
        // Save channel with typing events enabled to database
        try client.mockDatabaseContainer.writeSynchronously {
            try $0.saveChannel(
                payload: self.dummyPayload(
                    with: self.channelId,
                    ownCapabilities: [ChannelCapability.sendTypingEvents.rawValue]
                )
            )
        }

        // Simulate `sendStopTypingEvent` call.
        controller.sendStopTypingEvent()

        // Create a weak ref and release a controller.
        weak var weakController = controller
        controller = nil

        // Assert controller is kept alive
        AssertAsync.staysTrue(weakController != nil)
    }

    // MARK: - Message sending

    func test_createNewMessage_callsChannelUpdater() {
        let newMessage = ChatMessage.mock()

        // New message values
        let text: String = .unique
        let extraData: [String: RawJSON] = [:]
        let attachments: [AnyAttachmentPayload] = [
            .init(payload: TestAttachmentPayload.unique),
            .mockImage,
            .mockFile
        ]
        let quotedMessageId: MessageId = .unique
        let pin = MessagePinning(expirationDate: .unique)
        let skipPush = true
        let skipEnrichUrl = false

        // Simulate `createNewMessage` calls and catch the completion
        var completionCalled = false
        controller.createNewMessage(
            text: text,
            pinning: pin,
            attachments: attachments,
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
        XCTAssertEqual(env.channelUpdater?.createNewMessage_cid, channelId)
        XCTAssertEqual(env.channelUpdater?.createNewMessage_text, text)
        //        XCTAssertEqual(env.channelUpdater?.createNewMessage_command, command)
        //        XCTAssertEqual(env.channelUpdater?.createNewMessage_arguments, arguments)
        XCTAssertEqual(env.channelUpdater?.createNewMessage_extraData, extraData)
        XCTAssertEqual(env.channelUpdater?.createNewMessage_attachments, attachments)
        XCTAssertEqual(env.channelUpdater?.createNewMessage_quotedMessageId, quotedMessageId)
        XCTAssertEqual(env.channelUpdater?.createNewMessage_skipPush, skipPush)
        XCTAssertEqual(env.channelUpdater?.createNewMessage_skipEnrichUrl, skipEnrichUrl)
        XCTAssertEqual(env.channelUpdater?.createNewMessage_pinning?.expirationDate, pin.expirationDate!)

        // Simulate successful update
        env.channelUpdater?.createNewMessage_completion?(.success(newMessage))
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.createNewMessage_completion = nil

        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_createNewMessage_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `createNewMessage` call and assert error is returned
        let result: Result<MessageId, Error> = try waitFor { [callbackQueueID] completion in
            controller.createNewMessage(
                text: .unique,
//                command: .unique,
//                arguments: .unique,
                extraData: [:]
            ) { result in
                AssertTestQueue(withId: callbackQueueID)
                completion(result)
            }
        }

        if case let .failure(error) = result {
            XCTAssert(error is ClientError.ChannelNotCreatedYet)
        } else {
            XCTFail("Expected .failure but received \(result)")
        }
    }

    func test_createNewMessage_sendsNewMessagePendingEvent() throws {
        let exp = expectation(description: "should complete create new message")

        let mockedEventNotificationCenter = EventNotificationCenter_Mock(database: .init(kind: .inMemory))
        client.mockedEventNotificationCenter = mockedEventNotificationCenter

        controller.createNewMessage(
            text: .unique
        ) { _ in
            exp.fulfill()
        }

        env.channelUpdater?.createNewMessage_completion?(.success(.unique))

        wait(for: [exp], timeout: defaultTimeout)

        let event = try XCTUnwrap(mockedEventNotificationCenter.mock_process.calls.first?.0.first)
        XCTAssertTrue(event is NewMessagePendingEvent)
    }

    // MARK: - Adding members

    func test_addMembers_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)
        let members: Set<UserId> = [.unique]

        // Simulate `addMembers` call and assert error is returned
        var error: Error? = try waitFor { [callbackQueueID] completion in
            controller.addMembers(userIds: members) { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_onChannelCreated?(query.cid!)

        // Simulate `addMembers` call and assert no error is returned
        error = try waitFor { [callbackQueueID] completion in
            controller.addMembers(userIds: members) { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
            env.channelUpdater!.addMembers_completion?(nil)
        }

        XCTAssertNil(error)
    }

    func test_addMembers_callsChannelUpdater() {
        let members: Set<UserId> = [.unique]

        // Simulate `addMembers` call and catch the completion
        var completionCalled = false
        controller.addMembers(userIds: members) { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Assert cid and members state are passed to `channelUpdater`, completion is not called yet
        XCTAssertEqual(env.channelUpdater!.addMembers_cid, channelId)
        XCTAssertEqual(env.channelUpdater!.addMembers_userIds, members)
        XCTAssertFalse(completionCalled)

        // Simulate successful update
        env.channelUpdater!.addMembers_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.addMembers_completion = nil

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_addMembers_propagatesErrorFromUpdater() {
        let members: Set<UserId> = [.unique]

        // Simulate `addMembers` call and catch the completion
        var completionCalledError: Error?
        controller.addMembers(userIds: members) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.addMembers_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // MARK: - Inviting members

    func test_inviteMembers_callsChannelUpdater() {
        let members: Set<UserId> = [.unique, .unique]

        // Simulate `inviteMembers` call and catch the completion
        var completionCalled = false
        controller.inviteMembers(userIds: members) { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Assert cid and members state are passed to `channelUpdater`, completion is not called yet
        XCTAssertEqual(env.channelUpdater!.inviteMembers_cid, channelId)
        XCTAssertEqual(env.channelUpdater!.inviteMembers_userIds, members)
        XCTAssertFalse(completionCalled)

        // Simulate successful update
        env.channelUpdater!.inviteMembers_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.inviteMembers_completion = nil

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_inviteMembers_propagatesErrorFromUpdater() {
        let members: Set<UserId> = [.unique, .unique]

        // Simulate `inviteMembers` call and catch the completion
        var completionCalledError: Error?
        controller.inviteMembers(userIds: members) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.inviteMembers_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
        controller = nil
    }

    // MARK: - Accepting invites

    func test_acceptInvite_callsChannelUpdater() {
        // Simulate `acceptInvite` call and catch the completion
        var completionCalled = false
        let message = "Hooray"
        controller.acceptInvite(message: message) { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Assert cid and members state are passed to `channelUpdater`, completion is not called yet
        XCTAssertEqual(env.channelUpdater!.acceptInvite_cid, channelId)
        XCTAssertEqual(env.channelUpdater!.acceptInvite_message, message)
        XCTAssertFalse(completionCalled)

        // Simulate successful update
        env.channelUpdater!.acceptInvite_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.acceptInvite_completion = nil

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_acceptInvite_propagatesErrorFromUpdater() {
        // Simulate `inviteMembers` call and catch the completion
        var completionCalledError: Error?
        controller.acceptInvite(message: "Hooray") { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.acceptInvite_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
        controller = nil
    }

    // MARK: - Accepting invites

    func test_rejectInvite_callsChannelUpdater() {
        // Simulate `acceptInvite` call and catch the completion
        var completionCalled = false
        controller.rejectInvite { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Assert cid and members state are passed to `channelUpdater`, completion is not called yet
        XCTAssertEqual(env.channelUpdater!.rejectInvite_cid, channelId)
        XCTAssertFalse(completionCalled)

        // Simulate successful update
        env.channelUpdater!.rejectInvite_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.rejectInvite_completion = nil

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_rejectInvite_propagatesErrorFromUpdater() {
        // Simulate `inviteMembers` call and catch the completion
        var completionCalledError: Error?
        controller.rejectInvite { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.rejectInvite_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
        controller = nil
    }

    // MARK: - Removing members

    func test_removeMembers_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)
        let members: Set<UserId> = [.unique]

        // Simulate `removeMembers` call and assert error is returned
        var error: Error? = try waitFor { [callbackQueueID] completion in
            controller.removeMembers(userIds: members) { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_onChannelCreated?(query.cid!)

        // Simulate `removeMembers` call and assert no error is returned
        error = try waitFor { [callbackQueueID] completion in
            controller.removeMembers(userIds: members) { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
            env.channelUpdater!.removeMembers_completion?(nil)
        }

        XCTAssertNil(error)
    }

    func test_removeMembers_callsChannelUpdater() {
        let members: Set<UserId> = [.unique]

        // Simulate `removeMembers` call and catch the completion
        var completionCalled = false
        controller.removeMembers(userIds: members) { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Assert cid and members state are passed to `channelUpdater`, completion is not called yet
        XCTAssertEqual(env.channelUpdater!.removeMembers_cid, channelId)
        XCTAssertEqual(env.channelUpdater!.removeMembers_userIds, members)
        XCTAssertFalse(completionCalled)

        // Simulate successful update
        env.channelUpdater!.removeMembers_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.removeMembers_completion = nil

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_removeMembers_propagatesErrorFromUpdater() {
        let members: Set<UserId> = [.unique]

        // Simulate `removeMembers` call and catch the completion
        var completionCalledError: Error?
        controller.removeMembers(userIds: members) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.removeMembers_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // MARK: - Mark read

    func test_markRead_whenReadEventsAreDisabled_errors() throws {
        let payload = dummyPayload(with: channelId, ownCapabilities: [])
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        let error: Error? = try waitFor { completion in
            controller.markRead { error in
                completion(error)
            }
        }

        guard let channelFeatureError = error as? ClientError.ChannelFeatureDisabled else {
            XCTFail()
            return
        }

        XCTAssertEqual(channelFeatureError.localizedDescription, "Channel feature: read events is disabled for this channel.")
    }

    func test_markRead_whenChannelIsMissing_throws() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `markRead` call and assert error is returned
        var error: Error? = try waitFor { [callbackQueueID] completion in
            controller.markRead { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: query.cid!, ownCapabilities: [ChannelCapability.readEvents.rawValue]))
        }
        env.channelUpdater!.update_onChannelCreated?(query.cid!)
        
        // Simulate `markRead` call and assert no error is returned
        error = try waitFor { [callbackQueueID] completion in
            controller.markRead { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
            env.channelUpdater!.markRead_completion?(nil)
        }

        XCTAssertNil(error)
    }

    func test_markRead_whenChannelIsEmpty_doesNothing() throws {
        // GIVEN
        let currentUser: CurrentUserPayload = .dummy(userId: .unique, role: .user)

        let emptyChannel: ChannelPayload = .dummy(
            channel: .dummy(
                cid: channelId,
                lastMessageAt: nil,
                ownCapabilities: [ChannelCapability.readEvents.rawValue]
            ),
            messages: [],
            channelReads: []
        )

        try client.databaseContainer.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)

            try session.saveChannel(payload: emptyChannel)
        }

        client.setToken(token: .unique(userId: currentUser.id))

        // WHEN
        var completionCalled = false
        controller.markRead { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // THEN
        AssertAsync {
            Assert.willBeTrue(completionCalled)
            Assert.staysTrue(self.env.channelUpdater?.markRead_cid == nil)
        }
    }

    func test_markRead_whenCurrentUserIsMissing_doesNothing() throws {
        // GIVEN
        let lastMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            cid: channelId
        )

        let channel: ChannelPayload = .dummy(
            channel: .dummy(
                cid: channelId,
                lastMessageAt: lastMessage.createdAt,
                ownCapabilities: [ChannelCapability.readEvents.rawValue]
            ),
            messages: [lastMessage]
        )

        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        var completionCalled = false
        controller.markRead { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // THEN
        AssertAsync {
            Assert.willBeTrue(completionCalled)
            Assert.staysTrue(self.env.channelUpdater?.markRead_cid == nil)
        }
    }

    func test_markRead_whenCurrentUserReadIsMissing_doesNothing() throws {
        // GIVEN
        let lastMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            cid: channelId
        )

        let currentUser: CurrentUserPayload = .dummy(userId: .unique, role: .user)

        let channel: ChannelPayload = .dummy(
            channel: .dummy(
                cid: channelId,
                lastMessageAt: lastMessage.createdAt,
                ownCapabilities: [ChannelCapability.readEvents.rawValue]
            ),
            messages: [lastMessage],
            channelReads: []
        )

        try client.databaseContainer.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)

            try session.saveChannel(payload: channel)
        }

        client.setToken(token: .unique(userId: currentUser.id))

        // WHEN
        var completionCalled = false
        controller.markRead { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // THEN
        AssertAsync {
            Assert.willBeTrue(completionCalled)
            Assert.staysTrue(self.env.channelUpdater?.markRead_cid == nil)
        }
    }

    func test_markRead_whenChannelIsRead_doesNothing() throws {
        // GIVEN
        let lastMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            cid: channelId
        )

        let currentUser: CurrentUserPayload = .dummy(userId: .unique, role: .user)

        let channel: ChannelPayload = .dummy(
            channel: .dummy(cid: channelId, lastMessageAt: lastMessage.createdAt, ownCapabilities: [ChannelCapability.readEvents.rawValue]),
            messages: [lastMessage],
            channelReads: [
                .init(
                    user: currentUser,
                    lastReadAt: lastMessage.createdAt,
                    lastReadMessageId: .unique,
                    unreadMessagesCount: 0
                )
            ]
        )

        try client.databaseContainer.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)

            try session.saveChannel(payload: channel)
        }

        client.setToken(token: .unique(userId: currentUser.id))

        // WHEN
        var completionCalled = false
        controller.markRead { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // THEN
        AssertAsync {
            Assert.willBeTrue(completionCalled)
            Assert.staysTrue(self.env.channelUpdater?.markRead_cid == nil)
        }
    }

    func test_markRead_whenLastMessageInUnread_callsChannelUpdater() throws {
        // GIVEN
        let lastMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            cid: channelId
        )

        let currentUser: CurrentUserPayload = .dummy(userId: .unique, role: .user)

        let channel: ChannelPayload = .dummy(
            channel: .dummy(cid: channelId, lastMessageAt: lastMessage.createdAt, ownCapabilities: [ChannelCapability.readEvents.rawValue]),
            messages: [lastMessage],
            channelReads: [
                .init(
                    user: currentUser,
                    lastReadAt: lastMessage.createdAt.addingTimeInterval(-1),
                    lastReadMessageId: .unique,
                    unreadMessagesCount: 0
                )
            ]
        )

        try client.databaseContainer.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            try session.saveChannel(payload: channel)
        }

        client.setToken(token: .unique(userId: currentUser.id))

        // WHEN
        var completionCalled = false
        controller.markRead { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // THEN
        XCTAssertEqual(env.channelUpdater!.markRead_cid, channelId)
        XCTAssertEqual(env.channelUpdater!.markRead_userId, currentUser.id)
        env.channelUpdater!.markRead_completion?(nil)

        AssertAsync.willBeTrue(completionCalled)
    }

    func test_markRead_propagatesErrorFromUpdater() throws {
        let payload = dummyPayload(with: channelId, numberOfMessages: 3, ownCapabilities: [ChannelCapability.readEvents.rawValue])
        let dummyUserPayload: CurrentUserPayload = .dummy(userId: payload.channelReads.first!.user.id, role: .user)

        try client.databaseContainer.writeSynchronously { session in
            try session.saveCurrentUser(payload: dummyUserPayload)
            try session.saveChannel(payload: payload)
        }

        // This is needed to determine if the channel needs to be marked as read
        client.setToken(token: .unique(userId: dummyUserPayload.id))

        // Simulate `markRead` call and catch the completion
        var completionCalledError: Error?
        controller.markRead { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.markRead_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    func test_markRead_keepsControllerAlive() throws {
        // GIVEN
        let channel = dummyPayload(with: channelId, numberOfMessages: 3, ownCapabilities: [ChannelCapability.readEvents.rawValue])
        let currentUser: CurrentUserPayload = .dummy(userId: channel.channelReads.first!.user.id, role: .user)
        client.setToken(token: .unique(userId: currentUser.id))

        try client.databaseContainer.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            try session.saveChannel(payload: channel)
        }

        controller.markRead { _ in }

        // WHEN
        weak var weakController = controller
        controller = nil

        // Assert controller is kept alive
        AssertAsync.staysTrue(weakController != nil)
    }

    // MARK: - Mark unread

    func test_markUnread_whenChannelDoesNotExist() {
        var receivedError: Error?
        let expectation = self.expectation(description: "Mark Unread completes")
        controller.markUnread(from: .unique) { error in
            receivedError = error
            expectation.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertTrue(receivedError is ClientError.ChannelNotCreatedYet)
    }

    func test_markUnread_whenReadEventsAreNotEnabled() throws {
        let channel: ChannelPayload = .dummy(
            channel: .dummy(cid: channelId, ownCapabilities: [])
        )

        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        var receivedError: Error?
        let expectation = self.expectation(description: "Mark Unread completes")
        controller.markUnread(from: .unique) { error in
            receivedError = error
            expectation.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertTrue(receivedError is ClientError.ChannelFeatureDisabled)
    }

    private func simulateMarkingAsRead(userId: UserId) throws {
        let lastMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            cid: channelId
        )

        let currentUser: CurrentUserPayload = .dummy(userId: userId, role: .user)

        let channel: ChannelPayload = .dummy(
            channel: .dummy(cid: channelId, lastMessageAt: lastMessage.createdAt, ownCapabilities: [ChannelCapability.readEvents.rawValue]),
            messages: [lastMessage],
            channelReads: [
                .init(
                    user: currentUser,
                    lastReadAt: lastMessage.createdAt.addingTimeInterval(-1),
                    lastReadMessageId: nil,
                    unreadMessagesCount: 0
                )
            ]
        )

        try client.databaseContainer.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            try session.saveChannel(payload: channel)
        }

        controller.markRead()
    }

    func test_markUnread_whenIsMarkingAsRead_andCurrentUserIdIsPresent() throws {
        let channel: ChannelPayload = .dummy(
            channel: .dummy(cid: channelId, ownCapabilities: [ChannelCapability.readEvents.rawValue])
        )

        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        let currentUserId = UserId.unique
        client.setToken(token: .unique(userId: currentUserId))
        try simulateMarkingAsRead(userId: currentUserId)

        var receivedError: Error?
        let expectation = self.expectation(description: "Mark Unread completes")
        controller.markUnread(from: .unique) { error in
            receivedError = error
            expectation.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertNil(receivedError)
    }

    func test_markUnread_whenIsNotMarkingAsRead_andCurrentUserIdIsNotPresent() throws {
        let channel: ChannelPayload = .dummy(
            channel: .dummy(cid: channelId, ownCapabilities: [ChannelCapability.readEvents.rawValue])
        )

        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        var receivedError: Error?
        let expectation = self.expectation(description: "Mark Unread completes")
        controller.markUnread(from: .unique) { error in
            receivedError = error
            expectation.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertNil(receivedError)
    }

    func test_markUnread_whenIsNotMarkingAsRead_andCurrentUserIdIsPresent_whenUpdaterFails() throws {
        let channel: ChannelPayload = .dummy(
            channel: .dummy(cid: channelId, ownCapabilities: [ChannelCapability.readEvents.rawValue])
        )
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        client.setToken(token: .unique(userId: .unique))

        var receivedError: Error?
        let expectation = self.expectation(description: "Mark Unread completes")
        controller.markUnread(from: .unique) { error in
            receivedError = error
            expectation.fulfill()
        }
        let mockedError = TestError()
        env.channelUpdater?.markUnread_completion?(mockedError)

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertNotNil(receivedError)
    }

    func test_markUnread_whenIsNotMarkingAsRead_andCurrentUserIdIsPresent_whenThereAreNoMessages_whenUpdaterSucceeds() throws {
        let channel: ChannelPayload = .dummy(
            channel: .dummy(cid: channelId, ownCapabilities: [ChannelCapability.readEvents.rawValue])
        )
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        client.setToken(token: .unique(userId: .unique))

        var receivedError: Error?
        let messageId = MessageId.unique
        let expectation = self.expectation(description: "Mark Unread completes")
        controller.markUnread(from: messageId) { error in
            receivedError = error
            expectation.fulfill()
        }
        let updater = try XCTUnwrap(env.channelUpdater)

        updater.markUnread_completion?(nil)

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertNil(receivedError)

        // Because we don't have other messages, we fallback to the passed messageId as lastReadMessageId.
        XCTAssertNil(updater.markUnread_lastReadMessageId)
        XCTAssertEqual(updater.markUnread_messageId, messageId)
    }

    func test_markUnread_whenIsNotMarkingAsRead_andCurrentUserIdIsPresent_whenThereAreOtherMessages_whenUpdaterSucceeds() throws {
        let messageId = MessageId.unique
        let previousMessageId = MessageId.unique
        let markedAsUnreadMessage = MessagePayload.dummy(messageId: messageId, createdAt: Date())
        let previousMessage = MessagePayload.dummy(messageId: previousMessageId, createdAt: Date().addingTimeInterval(-10))
        let payload = dummyPayload(with: channelId, messages: [markedAsUnreadMessage, previousMessage], ownCapabilities: [ChannelCapability.readEvents.rawValue])
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }
        client.setToken(token: .unique(userId: .unique))

        var receivedError: Error?
        let expectation = self.expectation(description: "Mark Unread completes")
        controller.markUnread(from: messageId) { error in
            receivedError = error
            expectation.fulfill()
        }
        let updater = try XCTUnwrap(env.channelUpdater)

        updater.markUnread_completion?(nil)

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertNil(receivedError)
        XCTAssertEqual(updater.markUnread_lastReadMessageId, previousMessageId)
        XCTAssertEqual(updater.markUnread_messageId, messageId)
    }

    // MARK: - Enable slow mode (cooldown)

    func test_enableSlowMode_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `enableSlowMode` call and assert error is returned
        var error: Error? = try waitFor { [callbackQueueID] completion in
            controller.enableSlowMode(cooldownDuration: .random(in: 1...120)) { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_onChannelCreated?(query.cid!)
        
        // Simulate `enableSlowMode` call and assert no error is returned
        error = try waitFor { [callbackQueueID] completion in
            controller.enableSlowMode(cooldownDuration: .random(in: 1...120)) { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
            env.channelUpdater!.enableSlowMode_completion?(nil)
        }

        XCTAssertNil(error)
    }

    func test_enableSlowMode_failsForInvalidCooldown() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_onChannelCreated?(query.cid!)
        
        // Simulate `enableSlowMode` call with invalid cooldown and assert error is returned
        var error: Error? = try waitFor { [callbackQueueID] completion in
            controller.enableSlowMode(cooldownDuration: .random(in: 130...250)) { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.InvalidCooldownDuration)

        // Simulate `enableSlowMode` call with another invalid cooldown and assert error is returned
        error = try waitFor { [callbackQueueID] completion in
            controller.enableSlowMode(cooldownDuration: .random(in: -100...0)) { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.InvalidCooldownDuration)
    }

    func test_enableSlowMode_callsChannelUpdater() {
        // Simulate `enableSlowMode` call and catch the completion
        var completionCalled = false
        controller.enableSlowMode(cooldownDuration: .random(in: 1...120)) { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Assert cid is passed to `channelUpdater`, completion is not called yet
        XCTAssertEqual(env.channelUpdater!.enableSlowMode_cid, channelId)
        XCTAssertFalse(completionCalled)

        // Simulate successful update
        env.channelUpdater!.enableSlowMode_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.enableSlowMode_completion = nil

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_enableSlowMode_propagatesErrorFromUpdater() {
        // Simulate `enableSlowMode` call and catch the completion
        var completionCalledError: Error?
        controller.enableSlowMode(cooldownDuration: .random(in: 1...120)) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.enableSlowMode_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // MARK: - Disable slow mode (cooldown)

    func test_disableSlowMode_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `disableSlowMode` call and assert error is returned
        var error: Error? = try waitFor { [callbackQueueID] completion in
            controller.disableSlowMode { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_onChannelCreated?(query.cid!)
        
        // Simulate `disableSlowMode` call and assert no error is returned
        error = try waitFor { [callbackQueueID] completion in
            controller.disableSlowMode { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
            env.channelUpdater!.enableSlowMode_completion?(nil)
        }

        XCTAssertNil(error)
    }

    func test_disableSlowMode_callsChannelUpdater() {
        // Simulate `disableSlowMode` call and catch the completion
        var completionCalled = false
        controller.disableSlowMode { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Assert cid is passed to `channelUpdater`, completion is not called yet
        XCTAssertEqual(env.channelUpdater!.enableSlowMode_cid, channelId)
        // Assert that passed cooldown duration is 0
        XCTAssertEqual(env.channelUpdater!.enableSlowMode_cooldownDuration, 0)
        XCTAssertFalse(completionCalled)

        // Simulate successful update
        env.channelUpdater!.enableSlowMode_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.enableSlowMode_completion = nil

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_disableSlowMode_propagatesErrorFromUpdater() {
        // Simulate `disableSlowMode` call and catch the completion
        var completionCalledError: Error?
        controller.disableSlowMode { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.enableSlowMode_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    func test_currentCooldownTime_whenSlowModeIsActive_andLastMessageFromCurrentUserExists_thenCooldownTimeIsGreaterThanZero(
    ) throws {
        // GIVEN
        let user: UserPayload = dummyCurrentUser
        let message: MessagePayload = .dummy(messageId: .unique, authorUserId: user.id, createdAt: Date())
        let channelPayload = dummyPayload(with: channelId, messages: [message], cooldownDuration: 5)

        try client.databaseContainer.createCurrentUser(id: user.id)

        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }

        // WHEN
        let currentCooldownTime = controller.currentCooldownTime()

        // THEN
        XCTAssertGreaterThan(currentCooldownTime, 0)
    }

    func test_currentCooldownTime_whenSlowModeIsNotActive_thenCooldownTimeIsZero() throws {
        // GIVEN
        let user: UserPayload = dummyCurrentUser
        let channelPayload = dummyPayload(with: channelId, cooldownDuration: 0)

        try client.databaseContainer.createCurrentUser(id: user.id)

        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }

        // WHEN
        let currentCooldownTime = controller.currentCooldownTime()

        // THEN
        XCTAssertEqual(currentCooldownTime, 0)
    }

    func test_currentCooldownTime_doesNotReturnNegativeValues() throws {
        // GIVEN
        let user: UserPayload = dummyCurrentUser

        let message: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: user.id,
            createdAt: Date().addingTimeInterval(-20)
        )

        let channelPayload = dummyPayload(
            with: channelId,
            messages: [message],
            cooldownDuration: 5
        )

        try client.databaseContainer.createCurrentUser(id: user.id)

        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }

        // WHEN
        let currentCooldownTime = controller.currentCooldownTime()

        // THEN
        XCTAssertEqual(currentCooldownTime, 0)
    }

    // MARK: - Start watching

    func test_startWatching_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `startWatching` call and assert error is returned
        var error: Error? = try waitFor { [callbackQueueID] completion in
            controller.startWatching(isInRecoveryMode: false) { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_onChannelCreated?(query.cid!)
        
        // Simulate `startWatching` call and assert no error is returned
        error = try waitFor { [callbackQueueID] completion in
            controller.startWatching(isInRecoveryMode: false) { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
            env.channelUpdater!.startWatching_completion?(nil)
        }

        XCTAssertNil(error)
    }

    func test_startWatching_callsChannelUpdater() {
        // Simulate `startWatching` call and catch the completion
        var completionCalled = false
        controller.startWatching(isInRecoveryMode: false) { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Assert cid is passed to `channelUpdater`, completion is not called yet
        XCTAssertEqual(env.channelUpdater!.startWatching_cid, channelId)
        XCTAssertFalse(completionCalled)

        // Simulate successful update
        env.channelUpdater!.startWatching_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.startWatching_completion = nil

        AssertAsync {
            // Assert completion is called
            Assert.willBeTrue(completionCalled)
            // `weakController` should be deallocated too
            Assert.canBeReleased(&weakController)
        }
    }

    func test_startWatching_propagatesErrorFromUpdater() {
        // Simulate `startWatching` call and catch the completion
        var completionCalledError: Error?
        controller.startWatching(isInRecoveryMode: false) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.startWatching_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    func test_watchActiveChannelWithoutCidAlreadyCreated() {
        let editPayload = ChannelEditDetailPayload(
            type: .messaging,
            name: nil,
            imageURL: nil,
            team: nil,
            members: Set(),
            invites: Set(),
            extraData: [:]
        )

        let receivedError = watchActiveChannelAndWait(
            channelQuery: ChannelQuery(channelPayload: editPayload),
            isChannelAlreadyCreated: true,
            requestBlock: { channelUpdater in
                channelUpdater?.update_completion?(.success(dummyPayload(with: .unique)))
            }
        )

        XCTAssertNil(receivedError)
        XCTAssertNil(env.channelUpdater?.startWatching_cid)
        XCTAssertEqual(env.channelUpdater?.update_callCount, 1)
    }

    func test_watchActiveChannelWithCidNotAlreadyCreated() {
        let receivedError = watchActiveChannelAndWait(isChannelAlreadyCreated: false, requestBlock: { channelUpdater in
            channelUpdater?.update_completion?(.success(dummyPayload(with: .unique)))
        })

        XCTAssertNil(receivedError)
        XCTAssertNil(env.channelUpdater?.startWatching_cid)
        XCTAssertEqual(env.channelUpdater?.update_callCount, 1)
    }

    func test_watchActiveChannelWithCidAlreadyCreated() {
        let receivedError = watchActiveChannelAndWait(isChannelAlreadyCreated: true, requestBlock: { channelUpdater in
            channelUpdater?.startWatching_completion?(nil)
        })

        XCTAssertNil(receivedError)
        XCTAssertEqual(env.channelUpdater?.startWatching_cid, channelId)
        XCTAssertEqual(env.channelUpdater?.update_callCount, 0)
    }

    private func watchActiveChannelAndWait(
        channelQuery: ChannelQuery? = nil,
        isChannelAlreadyCreated: Bool,
        requestBlock: (ChannelUpdater_Mock?) -> Void
    ) -> Error? {
        controller = ChatChannelController(
            channelQuery: channelQuery ?? .init(cid: channelId),
            channelListQuery: nil,
            client: client,
            environment: env.environment,
            isChannelAlreadyCreated: isChannelAlreadyCreated
        )

        env.channelUpdater?.cleanUp()

        var receivedError: Error?
        let expectation = self.expectation(description: "watchActiveChannel completion")
        controller.recoverWatchedChannel { error in
            receivedError = error
            expectation.fulfill()
        }

        requestBlock(env.channelUpdater)

        waitForExpectations(timeout: defaultTimeout, handler: nil)
        return receivedError
    }

    // MARK: - Stop watching

    func test_stopWatching_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `stopWatching` call and assert error is returned
        var error: Error? = try waitFor { [callbackQueueID] completion in
            controller.stopWatching { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_onChannelCreated?(query.cid!)
        
        // Simulate `stopWatching` call and assert no error is returned
        error = try waitFor { [callbackQueueID] completion in
            controller.stopWatching { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
            env.channelUpdater!.stopWatching_completion?(nil)
        }

        XCTAssertNil(error)
    }

    func test_stopWatching_callsChannelUpdater() {
        // Simulate `stopWatching` call and catch the completion
        var completionCalled = false
        controller.stopWatching { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Assert cid is passed to `channelUpdater`, completion is not called yet
        XCTAssertEqual(env.channelUpdater!.stopWatching_cid, channelId)
        XCTAssertFalse(completionCalled)

        // Simulate successful update
        env.channelUpdater!.stopWatching_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.stopWatching_completion = nil

        AssertAsync {
            // Assert completion is called
            Assert.willBeTrue(completionCalled)
            // `weakController` should be deallocated too
            Assert.canBeReleased(&weakController)
        }
    }

    func test_stopWatching_propagatesErrorFromUpdater() {
        // Simulate `stopWatching` call and catch the completion
        var completionCalledError: Error?
        controller.stopWatching { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.stopWatching_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // MARK: - Freeze channel

    func test_freezeChannel_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `freezeChannel` call and assert error is returned
        var error: Error? = try waitFor { [callbackQueueID] completion in
            controller.freezeChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_onChannelCreated?(query.cid!)
        
        // Simulate `freezeChannel` call and assert no error is returned
        error = try waitFor { [callbackQueueID] completion in
            controller.freezeChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
            env.channelUpdater!.freezeChannel_completion?(nil)
        }

        XCTAssertNil(error)
    }

    func test_freezeChannel_callsChannelUpdater() {
        // Simulate `freezeChannel` call and catch the completion
        var completionCalled = false
        controller.freezeChannel { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Assert cid is passed to `channelUpdater`, completion is not called yet
        XCTAssertEqual(env.channelUpdater!.freezeChannel_cid, channelId)
        XCTAssertFalse(completionCalled)

        // Assert that `frozen: true` is passed as payload
        XCTAssertEqual(env.channelUpdater!.freezeChannel_freeze, true)

        // Simulate successful update
        env.channelUpdater!.freezeChannel_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.freezeChannel_completion = nil

        AssertAsync {
            // Assert completion is called
            Assert.willBeTrue(completionCalled)
            // `weakController` should be deallocated too
            Assert.canBeReleased(&weakController)
        }
    }

    func test_freezeChannel_propagatesErrorFromUpdater() {
        // Simulate `freezeChannel` call and catch the completion
        var completionCalledError: Error?
        controller.freezeChannel { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.freezeChannel_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // MARK: - Unfreeze channel

    func test_unfreezeChannel_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `unfreezeChannel` call and assert error is returned
        var error: Error? = try waitFor { [callbackQueueID] completion in
            controller.unfreezeChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_onChannelCreated?(query.cid!)
        
        // Simulate `unfreezeChannel` call and assert no error is returned
        error = try waitFor { [callbackQueueID] completion in
            controller.unfreezeChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
            env.channelUpdater!.freezeChannel_completion?(nil)
        }

        XCTAssertNil(error)
    }

    func test_unfreezeChannel_callsChannelUpdater() {
        // Simulate `unfreezeChannel` call and catch the completion
        var completionCalled = false
        controller.unfreezeChannel { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Assert cid is passed to `channelUpdater`, completion is not called yet
        XCTAssertEqual(env.channelUpdater!.freezeChannel_cid, channelId)
        XCTAssertFalse(completionCalled)

        // Assert that `frozen: false` is passed as payload
        XCTAssertEqual(env.channelUpdater!.freezeChannel_freeze, false)

        // Simulate successful update
        env.channelUpdater!.freezeChannel_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.freezeChannel_completion = nil

        AssertAsync {
            // Assert completion is called
            Assert.willBeTrue(completionCalled)
            // `weakController` should be deallocated too
            Assert.canBeReleased(&weakController)
        }
    }

    func test_unfreezeChannel_propagatesErrorFromUpdater() {
        // Simulate `freezeChannel` call and catch the completion
        var completionCalledError: Error?
        controller.unfreezeChannel { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.freezeChannel_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // MARK: - UploadAttachment

    func test_uploadAttachment_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `uploadFile` call and assert error is returned
        let error: Error? = try waitFor { [callbackQueueID] completion in
            controller.uploadAttachment(localFileURL: .localYodaImage, type: .image) { result in
                AssertTestQueue(withId: callbackQueueID)
                completion(result.error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)
    }

    func test_uploadAttachment_callsChannelUpdater() {
        // Simulate `uploadFile` call and catch the completion
        var completionCalled = false
        controller.uploadAttachment(localFileURL: .localYodaImage, type: .image) { [callbackQueueID] result in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(result.error)
            completionCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Assert cid is passed to `channelUpdater`, completion is not called yet
        XCTAssertEqual(env.channelUpdater!.uploadFile_cid, channelId)
        // Assert correct type is passed
        XCTAssertEqual(env.channelUpdater?.uploadFile_type, .image)
        XCTAssertFalse(completionCalled)

        // Simulate successful update
        env.channelUpdater!.uploadFile_completion?(.success(.dummy()))
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.uploadFile_completion = nil

        AssertAsync {
            // Assert completion is called
            Assert.willBeTrue(completionCalled)
            // `weakController` should be deallocated too
            Assert.canBeReleased(&weakController)
        }
    }

    func test_uploadAttachment_propagatesErrorFromUpdater() {
        // Simulate `uploadFile` call and catch the completion
        var completionCalledError: Error?
        controller.uploadAttachment(localFileURL: .localYodaImage, type: .image) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0.error
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.uploadFile_completion?(.failure(testError))

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // MARK: - Load pinned messages

    func test_loadPinnedMessages_failsForNewChannel() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `loadPinnedMessages` call and assert error is returned
        let error: Error? = try waitFor { [callbackQueueID] completion in
            controller.loadPinnedMessages { result in
                AssertTestQueue(withId: callbackQueueID)
                completion(result.error)
            }
        }

        // Assert `ClientError.ChannelNotCreatedYet` is propagated to completion
        XCTAssert(error is ClientError.ChannelNotCreatedYet)
    }

    func test_loadPinnedMessages_callsChannelUpdater() {
        let pageSize = 10
        let pagination = PinnedMessagesPagination.aroundMessage(.unique)

        // Simulate `loadPinnedMessages` call
        controller.loadPinnedMessages(pageSize: pageSize, pagination: pagination) { _ in }

        // Assert call is propagated to updater
        XCTAssertEqual(env.channelUpdater!.loadPinnedMessages_cid, controller.cid)
        XCTAssertEqual(env.channelUpdater!.loadPinnedMessages_query, .init(pageSize: pageSize, pagination: pagination))
    }

    func test_loadPinnedMessages_propagatesErrorFromUpdater() {
        // Simulate `loadPinnedMessages` call and catch the completion
        var completionError: Error?
        controller.loadPinnedMessages { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0.error
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.loadPinnedMessages_completion!(.failure(testError))

        // Error is propagated to completion
        AssertAsync.willBeEqual(completionError as? TestError, testError)
    }

    func test_loadPinnedMessages_keepsControllerAlive() {
        // Simulate `loadPinnedMessages` call
        controller.loadPinnedMessages { _ in }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Assert controller is kept alive
        AssertAsync.staysTrue(weakController != nil)
    }

    // MARK: Init registers active controller

    func test_initRegistersActiveController() {
        let client = ChatClient.mock
        let channelQuery = ChannelQuery(cid: channelId)
        let channelListQuery = ChannelListQuery(filter: .containMembers(userIds: [.unique]))

        let controller = ChatChannelController(
            channelQuery: channelQuery,
            channelListQuery: channelListQuery,
            client: client
        )

        XCTAssert(controller.client === client)
        XCTAssert(client.activeChannelControllers.count == 1)
        XCTAssert(client.activeChannelControllers.allObjects.first === controller)
    }

    // MARK: Test creation of a call

    func test_createCall_failsWhenChannelIsNotAlreadyCreated() {
        let controller = ChatChannelController(
            channelQuery: ChannelQuery(cid: channelId),
            channelListQuery: nil,
            client: ChatClient.mock,
            isChannelAlreadyCreated: false
        )

        let id: String = .unique
        let type: String = "video"
        var completionError: Error?
        controller.createCall(id: id, type: type) { result in
            completionError = result.error
        }

        AssertAsync.willBeTrue(completionError != nil)
    }

    func test_createCall_propagatesErrorFromUpdater() {
        let id: String = .unique
        let type: String = "video"
        var completionError: Error?

        // Set completion handler
        controller.createCall(id: id, type: type) { result in
            completionError = result.error
        }

        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.createCall_completion!(.failure(testError))

        // Error is propagated to completion
        AssertAsync.willBeEqual(completionError as? TestError, testError)
    }

    func test_createCall_propagatesResultFromUpdater() {
        let id: String = .unique
        let provider: String = "agora"
        let token: String = .unique
        let type: String = "video"

        var resultingCallWithToken: CallWithToken?
        let mockCallWithToken = CallWithToken(
            call: Call(
                id: id,
                provider: provider,
                agora: nil,
                hms: nil
            ),
            token: token
        )

        // Set completion handler
        controller.createCall(id: id, type: type) { result in
            resultingCallWithToken = result.value
        }

        // Simulate successful completion
        env.channelUpdater!.createCall_completion!(.success(mockCallWithToken))

        // Result is propagated to completion
        AssertAsync.willBeEqual(resultingCallWithToken, mockCallWithToken)
    }

    // MARK: deinit

    func test_deinit_whenIsJumpingToMessage_deletesAllMessages() throws {
        // GIVEN
        controller = ChatChannelController(
            channelQuery: .init(cid: channelId),
            channelListQuery: nil,
            client: client,
            environment: env.environment
        )
        let messages: [MessagePayload] = [.dummy(), .dummy(), .dummy(), .dummy()]
        try setupChannel(
            channelPayload: .dummy(
                channel: .dummy(cid: channelId),
                messages: messages
            )
        )

        var channel: ChannelDTO? {
            try? XCTUnwrap(client.databaseContainer.viewContext.channel(cid: channelId))
        }

        XCTAssertEqual(channel?.messages.count, messages.count)

        // WHEN
        env.channelUpdater?.mockPaginationState.hasLoadedAllNextMessages = false

        // THEN
        env.channelUpdater?.cleanUp()
        controller = nil
        AssertAsync.willBeEqual(channel?.messages.count, 0)
    }

    func test_deinit_whenIsNotJumpingToMessage_doesNotDeleteAnyMessage() throws {
        // GIVEN
        controller = ChatChannelController(
            channelQuery: .init(cid: channelId),
            channelListQuery: nil,
            client: client,
            environment: env.environment
        )
        let messages: [MessagePayload] = [.dummy(), .dummy(), .dummy(), .dummy()]
        try setupChannel(
            channelPayload: .dummy(
                channel: .dummy(cid: channelId),
                messages: messages
            )
        )

        var channel: ChannelDTO? {
            try? XCTUnwrap(client.databaseContainer.viewContext.channel(cid: channelId))
        }

        XCTAssertEqual(channel?.messages.count, messages.count)

        // WHEN
        XCTAssertEqual(controller.isJumpingToMessage, false)

        // THEN
        env.channelUpdater?.cleanUp()
        controller = nil
        AssertAsync.willBeEqual(channel?.messages.count, 4)
    }
}

// MARK: Test Helpers

extension ChannelController_Tests {
    // MARK: - Helpers

    func setupControllerForNewDirectMessageChannel(
        currentUserId: UserId,
        otherUserId: UserId,
        channelListQuery: ChannelListQuery? = nil
    ) {
        let payload = ChannelEditDetailPayload(
            type: .messaging,
            name: nil,
            imageURL: nil,
            team: nil,
            members: [currentUserId, otherUserId],
            invites: [],
            extraData: [:]
        )

        controller = ChatChannelController(
            channelQuery: .init(channelPayload: payload),
            channelListQuery: channelListQuery,
            client: client,
            environment: env.environment,
            isChannelAlreadyCreated: false
        )
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }

    func setupControllerForNewChannel(
        query: ChannelQuery,
        channelListQuery: ChannelListQuery? = nil
    ) {
        controller = ChatChannelController(
            channelQuery: query,
            channelListQuery: channelListQuery,
            client: client,
            environment: env.environment,
            isChannelAlreadyCreated: false
        )
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
        controller.synchronize()
    }

    func setupControllerForNewMessageChannel(
        cid: ChannelId,
        channelListQuery: ChannelListQuery? = nil
    ) {
        let payload = ChannelEditDetailPayload(
            cid: cid,
            name: nil,
            imageURL: nil,
            team: nil,
            members: [],
            invites: [],
            extraData: [:]
        )

        controller = ChatChannelController(
            channelQuery: .init(channelPayload: payload),
            channelListQuery: channelListQuery,
            client: client,
            environment: env.environment,
            isChannelAlreadyCreated: false
        )
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }

    @discardableResult
    func setupChannel(
        channelPayload: ChannelPayload? = nil,
        withAllNextMessagesLoaded: Bool = true
    ) throws -> ChannelPayload {
        let channelPayload = channelPayload ?? dummyPayload(with: channelId, numberOfMessages: 1)
        let error = try waitFor { done in
            var error: Error?
            waitForMessagesUpdate(shouldWait: !channelPayload.messages.isEmpty) {
                client.databaseContainer.write({ session in
                    // Create a channel with the provided payload
                    let dummyUserPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)
                    try session.saveCurrentUser(payload: dummyUserPayload)
                    try session.saveChannel(payload: channelPayload)
                    self.env?.channelUpdater?.mockPaginationState.hasLoadedAllNextMessages = withAllNextMessagesLoaded

                }, completion: { error = $0 })
            }
            done(error)
        }

        if let error = error {
            throw error
        }

        return channelPayload
    }

    private func createChannel(oldestMessageId: MessageId, newestMessageId: MessageId, channelReads: [ChannelReadPayload] = []) throws {
        let oldestMessage = MessagePayload.dummy(messageId: oldestMessageId, createdAt: Date().addingTimeInterval(-1000))
        let newestMessage = MessagePayload.dummy(messageId: newestMessageId, createdAt: Date().addingTimeInterval(1000))

        try createChannel(messages: [oldestMessage, newestMessage], channelReads: channelReads)
    }

    private func createChannel(messages: [MessagePayload], channelReads: [ChannelReadPayload] = []) throws {
        let payload = dummyPayload(with: channelId, messages: messages, channelReads: channelReads)
        try client.databaseContainer.writeSynchronously {
            try $0.saveChannel(payload: payload, query: nil, cache: nil)
        }
    }

    private func mockHasLoadedAllPreviousMessages(_ value: Bool) throws {
        var pagination = try XCTUnwrap(env.channelUpdater?.mockPaginationState)
        pagination.hasLoadedAllPreviousMessages = value
        env.channelUpdater?.mockPaginationState = pagination
    }

    private func AssertFirstUnreadMessageIsOldestRegularMessageId(
        oldestMessageType: MessageType,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let userId = UserId.unique
        let channelRead = ChannelReadPayload(
            user: .dummy(userId: userId),
            lastReadAt: .unique,
            lastReadMessageId: nil,
            unreadMessagesCount: 3
        )
        let token = Token(rawValue: "", userId: userId, expiration: nil)
        controller.client.authenticationRepository.setMockToken(token)

        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: .dummy(userId: userId, role: .user))
        }

        let oldestMessageId = MessageId.unique
        let newestMessageId = MessageId.unique
        let newestMessage = MessagePayload.dummy(
            messageId: newestMessageId,
            text: "new",
            createdAt: Date().addingTimeInterval(1000)
        )

        let oldestMessage = MessagePayload.dummy(
            type: oldestMessageType,
            messageId: oldestMessageId,
            text: "old",
            createdAt: Date().addingTimeInterval(-1000)
        )
        let oldestRegularMessage = MessagePayload.dummy(
            type: .regular,
            messageId: .unique,
            text: "old regular",
            createdAt: Date().addingTimeInterval(-500)
        )

        try createChannel(messages: [oldestMessage, oldestRegularMessage, newestMessage], channelReads: [channelRead])

        XCTAssertEqual(controller.firstUnreadMessageId, oldestRegularMessage.id, file: file, line: line)
    }

    private func waitForMessagesUpdate(shouldWait: Bool, block: () -> Void) {
        guard shouldWait else {
            block()
            return
        }

        let expectation = self.expectation(description: "Messages update")
        controller.delegate = MessagesUpdateWaiter(expectation: expectation)
        block()
        wait(for: [expectation], timeout: defaultTimeout)
    }
}

private class MessagesUpdateWaiter: ChatChannelControllerDelegate {
    weak var expectation: XCTestExpectation?

    init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }

    func channelController(_ channelController: ChatChannelController, didUpdateMessages changes: [ListChange<ChatMessage>]) {
        expectation?.fulfill()
    }
}

private class TestEnvironment {
    var channelUpdater: ChannelUpdater_Mock?
    var eventSender: TypingEventsSender_Mock?

    lazy var environment: ChatChannelController.Environment = .init(
        channelUpdaterBuilder: { [unowned self] in
            self.channelUpdater = ChannelUpdater_Mock(
                channelRepository: $0,
                callRepository: $1,
                paginationStateHandler: $2,
                database: $3,
                apiClient: $4
            )
            return self.channelUpdater!
        },
        eventSenderBuilder: { [unowned self] in
            self.eventSender = TypingEventsSender_Mock(database: $0, apiClient: $1)
            return self.eventSender!
        }
    )
}
