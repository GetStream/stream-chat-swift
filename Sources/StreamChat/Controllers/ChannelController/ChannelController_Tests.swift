//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
import XCTest

class ChannelController_Tests: StressTestCase {
    fileprivate var env: TestEnvironment!
    
    var client: ChatClient!
    
    var channelId: ChannelId!
    
    var controller: ChatChannelController!
    var controllerCallbackQueueID: UUID!
    /// Workaround for unwrapping **controllerCallbackQueueID!** in each closure that captures it
    private var callbackQueueID: UUID { controllerCallbackQueueID }
    
    override func setUp() {
        super.setUp()
        
        env = TestEnvironment()
        client = _ChatClient.mock
        channelId = ChannelId.unique
        controller = ChatChannelController(channelQuery: .init(cid: channelId), client: client, environment: env.environment)
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }
    
    override func tearDown() {
        channelId = nil
        controllerCallbackQueueID = nil
        
        env.channelUpdater?.cleanUp()
        
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
            Assert.canBeReleased(&env)
        }

        super.tearDown()
    }
    
    func test_clientAndIdAreCorrect() {
        XCTAssert(controller.client === client)
        XCTAssertEqual(controller.channelQuery.cid, channelId)
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

    // MARK: - Synchronize tests
    
    func test_synchronize_changesControllerState() {
        // Check if controller has initialized state initially.
        XCTAssertEqual(controller.state, .initialized)
        
        // Simulate `synchronize` call.
        controller.synchronize()
        
        // Simulate successful network call.
        env.channelUpdater?.update_completion?(nil)
        
        // Check if state changed after successful network call.
        XCTAssertEqual(controller.state, .remoteDataFetched)
    }
    
    func test_synchronize_changesControllerStateOnError() {
        // Check if controller has `initialized` state initially.
        assert(controller.state == .initialized)
        
        // Simulate `synchronize` call
        controller.synchronize()

        // Simulate failed network call.
        let error = TestError()
        env.channelUpdater?.update_completion?(error)
        
        // Check if state changed after failed network call.
        XCTAssertEqual(controller.state, .remoteDataFetchFailed(ClientError(with: error)))
    }
    
    func test_synchronize_callsChannelUpdater() {
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
        
        // Simulate successful update
        env.channelUpdater!.update_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.update_completion = nil
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
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
        env.channelUpdater!.update_completion?(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // MARK: - Creating `ChannelController` tests

    func test_channelControllerForNewChannel_createdCorrectly() throws {
        // Simulate currently logged-in user
        let currentUserId: UserId = .unique
        client.currentUserId = currentUserId

        let cid: ChannelId = .unique
        let team: String = .unique
        let members: Set<UserId> = [.unique]
        let invites: Set<UserId> = [.unique]
        let extraData: NoExtraData = .defaultValue

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
                extraData: extraData
            )

            // Assert `ChannelQuery` created correctly
            XCTAssertEqual(cid, controller.channelQuery.cid)
            XCTAssertEqual(team, controller.channelQuery.channelPayload?.team)
            XCTAssertEqual(
                members.union(isCurrentUserMember ? [currentUserId] : []),
                controller.channelQuery.channelPayload?.members
            )
            XCTAssertEqual(invites, controller.channelQuery.channelPayload?.invites)
            XCTAssertEqual(extraData, controller.channelQuery.channelPayload?.extraData)
        }
    }

    func test_channelControllerForNewChannel_throwsError_ifCurrentUserDoesNotExist() throws {
        let clientWithoutCurrentUser = ChatClient(
            config: .init(apiKeyString: .unique),
            tokenProvider: .invalid()
        )

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
                    extraData: .defaultValue
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
        client.currentUserId = currentUserId

        // Create DM channel members.
        let members: Set<UserId> = [.unique, .unique, .unique]

        // Try to create `ChannelController` with non-empty members while current user is missing
        let controller = try client.channelController(
            createChannelWithId: .unique,
            name: .unique,
            imageURL: .unique(),
            team: .unique,
            members: members,
            extraData: .defaultValue
        )

        XCTAssertEqual(controller.channelQuery.channelPayload?.members, members.union([currentUserId]))
    }

    func test_channelControllerForNew1on1Channel_createdCorrectly() throws {
        // Simulate currently logged-in user
        let currentUserId: UserId = .unique
        client.currentUserId = currentUserId

        for isCurrentUserMember in [true, false] {
            let team: String = .unique
            let members: Set<UserId> = [.unique]
            let extraData: NoExtraData = .defaultValue

            // Create a new `ChannelController`
            let controller = try client.channelController(
                createDirectMessageChannelWith: members,
                isCurrentUserMember: isCurrentUserMember,
                name: .unique,
                imageURL: .unique(),
                team: team,
                extraData: extraData
            )

            // Assert `ChannelQuery` created correctly
            XCTAssertEqual(team, controller.channelQuery.channelPayload?.team)
            XCTAssertEqual(
                members.union(isCurrentUserMember ? [currentUserId] : []),
                controller.channelQuery.channelPayload?.members
            )
            XCTAssertEqual(extraData, controller.channelQuery.channelPayload?.extraData)
        }
    }

    func test_channelControllerForNew1on1Channel_throwsError_OnEmptyMembers() {
        // Simulate currently logged-in user
        let currentUserId: UserId = .unique
        client.currentUserId = currentUserId

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

    func test_channelControllerForNewDirectMessagesChannel_throwsError_ifCurrentUserDoesNotExist() {
        let client = ChatClient(
            config: .init(apiKeyString: .unique),
            tokenProvider: .invalid()
        )

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
        client.currentUserId = currentUserId

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
        client.currentUserId = currentUserId

        // Create ChatChannelController for new channel
        controller = try client.channelController(
            createDirectMessageChannelWith: [.unique],
            name: .unique,
            imageURL: .unique(),
            extraData: .defaultValue
        )
        
        // Assert cid is nil
        XCTAssertNil(controller.cid)
    }
    
    // MARK: - Channel change propagation tests
    
    func test_channelChanges_arePropagated() throws {
        // Simulate changes in the DB:
        _ = try await {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: self.channelId), query: nil)
            }, completion: $0)
        }
        
        // Assert the resulting value is updated
        AssertAsync.willBeEqual(controller.channel?.cid, channelId)
        AssertAsync.willBeTrue(controller.channel?.isFrozen)
        
        // Simulate channel changes
        _ = try await {
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
        _ = try await {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: payload)
            }, completion: $0)
        }
        
        // Simulate `synchronize` call
        controller.synchronize()
        
        // Simulate an incoming message
        let newMessageId: MessageId = .unique
        let newMessagePayload: MessagePayload<NoExtraData> = .dummy(messageId: newMessageId, authorUserId: .unique)
        _ = try await {
            client.databaseContainer.write({ session in
                try session.saveMessage(payload: newMessagePayload, for: self.channelId)
            }, completion: $0)
        }
        
        // Assert the new message is presented
        AssertAsync.willBeTrue(controller.messages.contains { $0.id == newMessageId })
    }

    func test_messagesHaveCorrectOrder() throws {
        // Create a channel
        try client.databaseContainer.createChannel(cid: channelId, withMessages: false)
        
        // Insert two messages
        let message1: MessagePayload<NoExtraData> = .dummy(messageId: .unique, authorUserId: .unique)
        let message2: MessagePayload<NoExtraData> = .dummy(messageId: .unique, authorUserId: .unique)
        
        try client.databaseContainer.writeSynchronously {
            try $0.saveMessage(payload: message1, for: self.channelId)
            try $0.saveMessage(payload: message2, for: self.channelId)
        }
        
        // Set top-to-bottom ordering
        controller.listOrdering = .topToBottom
        
        // Check the order of messages is correct
        let topToBottomIds = [message1, message2].sorted { $0.createdAt > $1.createdAt }.map(\.id)
        XCTAssertEqual(controller.messages.map(\.id), topToBottomIds)
        
        // Set bottom-to-top ordering
        controller.listOrdering = .bottomToTop
        
        // Check the order of messages is correct
        let bottomToTopIds = [message1, message2].sorted { $0.createdAt < $1.createdAt }.map(\.id)
        XCTAssertEqual(controller.messages.map(\.id), bottomToTopIds)
    }
    
    func test_threadReplies_areNotShownInChannel() throws {
        // Create a channel
        try client.databaseContainer.createChannel(cid: channelId, withMessages: false)
        
        // Insert two messages
        let message1: MessagePayload<NoExtraData> = .dummy(messageId: .unique, authorUserId: .unique)
        let message2: MessagePayload<NoExtraData> = .dummy(messageId: .unique, authorUserId: .unique)
        
        // Insert reply that should be shown in channel.
        let reply1: MessagePayload<NoExtraData> = .dummy(
            messageId: .unique,
            parentId: message2.id,
            showReplyInChannel: true,
            authorUserId: .unique
        )
        
        // Insert reply that should be visible only in thread.
        let reply2: MessagePayload<NoExtraData> = .dummy(
            messageId: .unique,
            parentId: message2.id,
            showReplyInChannel: false,
            authorUserId: .unique
        )
        
        try client.databaseContainer.writeSynchronously {
            try $0.saveMessage(payload: message1, for: self.channelId)
            try $0.saveMessage(payload: message2, for: self.channelId)
            try $0.saveMessage(payload: reply1, for: self.channelId)
            try $0.saveMessage(payload: reply2, for: self.channelId)
        }
        
        // Set top-to-bottom ordering
        controller.listOrdering = .topToBottom
        
        // Check the relevant reply is shown in channel
        let messagesWithReply = [message1, message2, reply1].sorted { $0.createdAt > $1.createdAt }.map(\.id)
        XCTAssertEqual(controller.messages.map(\.id), messagesWithReply)
    }

    func test_deletedMessages_areShownCorrectly() throws {
        let currentUserID: UserId = .unique

        // Create current user
        try client.databaseContainer.createCurrentUser(id: currentUserID)

        // Create a channel
        try client.databaseContainer.createChannel(cid: channelId, withMessages: false)

        // Create incoming deleted message
        let incomingDeletedMessage: MessagePayload<NoExtraData> = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            deletedAt: .unique
        )

        // Create outgoing deleted message
        let outgoingDeletedMessage: MessagePayload<NoExtraData> = .dummy(
            messageId: .unique,
            authorUserId: currentUserID,
            deletedAt: .unique
        )

        try client.databaseContainer.writeSynchronously {
            try $0.saveMessage(payload: incomingDeletedMessage, for: self.channelId)
            try $0.saveMessage(payload: outgoingDeletedMessage, for: self.channelId)
        }

        // Only outgoing deleted messages are returned by controller
        XCTAssertEqual(controller.messages.map(\.id), [outgoingDeletedMessage.id])
    }

    func test_truncatedMessages_areNotVisible() throws {
        // Prepare channel with 10 messages
        try client.databaseContainer.writeSynchronously {
            try $0.saveChannel(payload: self.dummyPayload(with: self.channelId, numberOfMessages: 10))
        }

        // Simulate `synchronize` call and check all messages are fetched
        controller.synchronize()
        XCTAssertEqual(controller.messages.count, 10)

        // Set channel `truncatedAt` date before the 5th message
        let truncatedAtDate = self.controller.messages[4].createdAt.addingTimeInterval(-0.1)
        try client.databaseContainer.writeSynchronously {
            $0.channel(cid: self.channelId)?.truncatedAt = truncatedAtDate
        }

        // Check only the 5 messages after the truncatedAt date are visible
        XCTAssertEqual(controller.messages.count, 5)
        XCTAssert(controller.messages.allSatisfy { $0.createdAt > truncatedAtDate })
    }

    // MARK: - Delegate tests
    
    func test_settingDelegate_leadsToFetchingLocalData() {
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
           
        // Check initial state
        XCTAssertEqual(controller.state, .initialized)
           
        controller.delegate = delegate
           
        // Assert state changed
        AssertAsync.willBeEqual(controller.state, .localDataFetched)
    }
    
    func test_delegate_isNotifiedAboutStateChanges() throws {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)

        // Synchronize
        controller.synchronize()
            
        // Simulate network call response
        env.channelUpdater?.update_completion?(nil)
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .remoteDataFetched)
    }

    func test_genericDelegate_isNotifiedAboutStateChanges() throws {
        // Set the generic delegate
        let delegate = TestDelegateGeneric(expectedQueueId: controllerCallbackQueueID)
        controller.setDelegate(delegate)
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)

        // Synchronize
        controller.synchronize()
        
        // Simulate network call response
        env.channelUpdater?.update_completion?(nil)
        //   env.messageUpdater.getMessage_completion?(nil)
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .remoteDataFetched)
    }

    func test_delegateContinueToReceiveEvents_afterObserversReset() throws {
        // Assign `ChannelController` that creates new channel
        controller = ChatChannelController(
            channelQuery: _ChannelQuery(cid: channelId),
            client: client,
            environment: env.environment,
            isChannelAlreadyCreated: false
        )
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)

        // Setup delegate
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate

        // Simulate `synchronize` call
        controller.synchronize()
        
        // Simulate updater's channelCreatedCallback call
        env.channelUpdater!.update_channelCreatedCallback!(channelId)

        // Simulate DB update
        var error = try await {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: self.channelId), query: nil)
            }, completion: $0)
        }
        XCTAssertNil(error)
        let channel: ChatChannel = client.databaseContainer.viewContext.channel(cid: channelId)!.asModel()
        assert(channel.latestMessages.count == 1)
        let message: ChatMessage = channel.latestMessages.first!

        // Assert DB observers call delegate updates
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateChannel_channel, .create(channel))
            Assert.willBeEqual(delegate.didUpdateMessages_messages, [.insert(message, index: [0, 0])])
        }

        let newCid: ChannelId = .unique

        // Simulate `channelCreatedCallback` call that will reset DB observers to observing data with new `cid`
        env.channelUpdater!.update_channelCreatedCallback?(newCid)

        // Simulate DB update
        error = try await {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: newCid), query: nil)
            }, completion: $0)
        }
        XCTAssertNil(error)
        let newChannel: ChatChannel = client.databaseContainer.viewContext.channel(cid: newCid)!.asModel()
        assert(channel.latestMessages.count == 1)
        let newMessage: ChatMessage = newChannel.latestMessages.first!

        // Assert DB observers call delegate updates for new `cid`
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateChannel_channel, .create(newChannel))
            Assert.willBeEqual(delegate.didUpdateMessages_messages, [.insert(newMessage, index: [0, 0])])
        }
    }
    
    func test_channelMemberEvents_areForwardedToDelegate() throws {
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Simulate `synchronize()` call
        controller.synchronize()
        
        // Send notification with event happened in the observed channel
        let event = TestMemberEvent(cid: controller.channelQuery.cid!, userId: .unique)
        let notification = Notification(newEventReceived: event, sender: self)
        client.webSocketClient!.eventNotificationCenter.post(notification)
        
        // Assert the event is received
        AssertAsync.willBeEqual(delegate.didReceiveMemberEvent_event as? TestMemberEvent, event)
    }
    
    func test_channelMemberEvents_areForwardedToGenericDelegate() throws {
        let delegate = TestDelegateGeneric(expectedQueueId: controllerCallbackQueueID)
        controller.setDelegate(delegate)
        
        // Simulate `synchronize()` call
        controller.synchronize()
        
        // Send notification with event happened in the observed channel
        let event = TestMemberEvent(cid: controller.cid!, userId: .unique)
        let notification = Notification(newEventReceived: event, sender: self)
        client.webSocketClient!.eventNotificationCenter.post(notification)
        
        // Assert the event is received
        AssertAsync.willBeEqual(delegate.didReceiveMemberEvent_event as? TestMemberEvent, event)
    }
    
    func test_channelTypingEvents_areForwardedToDelegate() throws {
        let memberId: UserId = .unique
        // Create channel in the database
        try client.databaseContainer.createChannel(cid: channelId)
        // Create member in the database
        try client.databaseContainer.createMember(userId: memberId, cid: channelId)
        
        // Set the queue for delegate calls
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Simulate `synchronize()` call
        controller.synchronize()

        // Save member as a typing member
        try client.databaseContainer.writeSynchronously { session in
            let channel = try XCTUnwrap(session.channel(cid: self.channelId))
            let member = try XCTUnwrap(session.member(userId: memberId, cid: self.channelId))
            channel.currentlyTypingMembers.insert(member)
        }
        
        // Load the channel member
        var typingMember: ChatChannelMember {
            client.databaseContainer.viewContext.member(userId: memberId, cid: channelId)!.asModel()
        }
        
        // Assert the delegate receives typing memeber
        AssertAsync.willBeEqual(delegate.didChangeTypingMembers_typingMembers, [typingMember])
    }
    
    func test_channelTypingEvents_areForwardedToGenericDelegate() throws {
        let memberId: UserId = .unique
        // Create channel in the database
        try client.databaseContainer.createChannel(cid: channelId)
        // Create member in the database
        try client.databaseContainer.createMember(userId: memberId, cid: channelId)
        
        // Set the queue for delegate calls
        let delegate = TestDelegateGeneric(expectedQueueId: controllerCallbackQueueID)
        controller.setDelegate(delegate)
        
        // Simulate `synchronize()` call
        controller.synchronize()

        // Set created member as a typing member
        try client.databaseContainer.writeSynchronously { session in
            let channel = try XCTUnwrap(session.channel(cid: self.channelId))
            let member = try XCTUnwrap(session.member(userId: memberId, cid: self.channelId))
            channel.currentlyTypingMembers.insert(member)
        }
        
        // Load the channel member
        var typingMember: ChatChannelMember {
            client.databaseContainer.viewContext.member(userId: memberId, cid: channelId)!.asModel()
        }
        
        // Assert the delegate receives typing member
        AssertAsync.willBeEqual(delegate.didChangeTypingMembers_typingMembers, [typingMember])
    }
    
    func test_delegateMethodsAreCalled() throws {
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Assert the delegate is assigned correctly. We should test this because of the type-erasing we
        // do in the controller.
        XCTAssert(controller.delegate === delegate)
        
        // Simulate `synchronize()` call
        controller.synchronize()
        
        // Simulate DB update
        let error = try await {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: self.channelId), query: nil)
            }, completion: $0)
        }
        XCTAssertNil(error)
        let channel: ChatChannel = client.databaseContainer.viewContext.channel(cid: channelId)!.asModel()
        assert(channel.latestMessages.count == 1)
        let message: ChatMessage = channel.latestMessages.first!
        
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateChannel_channel, .create(channel))
            Assert.willBeEqual(delegate.didUpdateMessages_messages, [.insert(message, index: [0, 0])])
        }
    }
    
    func test_genericDelegateMethodsAreCalled() throws {
        let delegate = TestDelegateGeneric(expectedQueueId: controllerCallbackQueueID)
        controller.setDelegate(delegate)
        
        // Simulate `synchronize()` call
        controller.synchronize()
        
        // Simulate DB update
        _ = try await {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: self.channelId), query: nil)
            }, completion: $0)
        }
        let channel: ChatChannel = client.databaseContainer.viewContext.channel(cid: channelId)!.asModel()
        assert(channel.latestMessages.count == 1)
        let message: ChatMessage = channel.latestMessages.first!
        
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateChannel_channel, .create(channel))
            Assert.willBeEqual(delegate.didUpdateMessages_messages, [.insert(message, index: [0, 0])])
        }
    }
    
    // MARK: - Channel actions propagation tests

    func setupControllerForNewChannel(query: ChannelQuery) {
        controller = ChatChannelController(
            channelQuery: query,
            client: client,
            environment: env.environment,
            isChannelAlreadyCreated: false
        )
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
        controller.synchronize()
    }
    
    // MARK: - Updating channel
    
    func test_updateChannel_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = _ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `updateChannel` call and assert the error is returned
        var error: Error? = try await { [callbackQueueID] completion in
            controller.updateChannel(name: .unique, imageURL: .unique(), team: nil, extraData: .init()) { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate succsesfull backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid!)

        // Simulate `updateChannel` call and assert no error is returned
        error = try await { [callbackQueueID] completion in
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

    // MARK: - Muting channel
    
    func test_muteChannel_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = _ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `muteChannel` call and assert error is returned
        var error: Error? = try await { [callbackQueueID] completion in
            controller.muteChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid!)

        // Simulate `muteChannel` call and assert no error is returned
        error = try await { [callbackQueueID] completion in
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
        let query = _ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `unmuteChannel` call and assert error is returned
        var error: Error? = try await { [callbackQueueID] completion in
            controller.muteChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid!)

        // Simulate `unmuteChannel` call and assert no error is returned
        error = try await { [callbackQueueID] completion in
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
        let query = _ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `deleteChannel` call and assert error is returned
        var error: Error? = try await { [callbackQueueID] completion in
            controller.deleteChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid!)

        // Simulate `deleteChannel` call and assert no error is returned
        error = try await { [callbackQueueID] completion in
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
    
    // MARK: - Hiding channel

    func test_hideChannel_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = _ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `hideChannel` call and assert error is returned
        var error: Error? = try await { [callbackQueueID] completion in
            controller.hideChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid!)

        // Simulate `hideChannel` call and assert no error is returned
        error = try await { [callbackQueueID] completion in
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
        let query = _ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `showChannel` call and assert error is returned
        var error: Error? = try await { [callbackQueueID] completion in
            controller.showChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid!)

        // Simulate `showChannel` call and assert no error is returned
        error = try await { [callbackQueueID] completion in
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
    
    // MARK: - Message loading
    
    // Helper function that creates channel with message
    func setupChannelWithMessage(_ session: DatabaseSession) throws -> MessageId {
        let dummyUserPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user)
        try session.saveCurrentUser(payload: dummyUserPayload)
        try session.saveChannel(payload: dummyPayload(with: channelId))
        let message = try session.createNewMessage(
            in: channelId,
            text: "Message",
            quotedMessageId: nil,
            attachmentSeeds: [
                ChatMessageAttachmentSeed.dummy(),
                ChatMessageAttachmentSeed.dummy(),
                ChatMessageAttachmentSeed.dummy()
            ],
            extraData: NoExtraData.defaultValue
        )
        return message.id
    }
    
    // MARK: - `loadPreviousMessages`
    
    func test_loadPreviousMessages_callsChannelUpdater() throws {
        var error: Error?
        var messageId: MessageId?
        
        // Create new channel with message in DB
        error = try await {
            client.databaseContainer.write({ session in
                messageId = try self.setupChannelWithMessage(session)
            }, completion: $0)
        }
        
        XCTAssertNil(error)
        
        var completionCalled = false
        controller.loadPreviousMessages(before: messageId, limit: 25) { [callbackQueueID] error in
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
        // Assert correct `MessagesPagination` is created
        XCTAssertEqual(
            env!.channelUpdater?.update_channelQuery?.pagination,
            MessagesPagination(pageSize: 25, parameter: .lessThan(messageId!))
        )
        
        // Simulate successful update
        env.channelUpdater?.update_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.update_completion = nil
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_loadPreviousMessages_throwsError_on_emptyMessages() throws {
        // Simulate `loadPreviousMessages` call and assert error is returned
        let error: Error? = try await { [callbackQueueID] completion in
            controller.loadPreviousMessages { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelEmptyMessages)
    }
    
    func test_loadPreviousMessages_callsChannelUpdaterWithError() throws {
        var error: Error?
        var messageId: MessageId?
        
        // Create new channel with message in DB
        error = try await {
            client.databaseContainer.write({ session in
                messageId = try self.setupChannelWithMessage(session)
            }, completion: $0)
        }
        
        XCTAssertNil(error)
        
        // Simulate `loadPreviousMessages` call and catch the completion
        var completionCalledError: Error?
        controller.loadPreviousMessages(before: messageId) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }
        
        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.update_completion?(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    // MARK: - `loadNextMessages`
    
    func test_loadNextMessages_callsChannelUpdate() throws {
        var error: Error?
        var messageId: MessageId?
        
        // Create new channel with message in DB
        error = try await {
            client.databaseContainer.write({ session in
                messageId = try self.setupChannelWithMessage(session)
            }, completion: $0)
        }
        
        XCTAssertNil(error)
        
        var completionCalled = false
        controller.loadNextMessages(after: messageId, limit: 25) { [callbackQueueID] error in
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
        // Assert correct `MessagesPagination` is created
        XCTAssertEqual(
            env!.channelUpdater?.update_channelQuery?.pagination,
            MessagesPagination(pageSize: 25, parameter: .greaterThan(messageId!))
        )
        
        // Simulate successful update
        env.channelUpdater?.update_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.update_completion = nil
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_loadNextMessages_throwsError_on_emptyMessages() throws {
        // Simulate `loadNextMessages` call and assert error is returned
        let error: Error? = try await { [callbackQueueID] completion in
            controller.loadNextMessages { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelEmptyMessages)
    }
    
    func test_loadNextMessages_callsChannelUpdaterWithError() throws {
        var error: Error?
        var messageId: MessageId?
        
        // Create new channel with message in DB
        error = try await {
            client.databaseContainer.write({ session in
                messageId = try self.setupChannelWithMessage(session)
            }, completion: $0)
        }
        
        XCTAssertNil(error)
        
        // Simulate `loadPreviousMessages` call and catch the completion
        var completionCalledError: Error?
        controller.loadNextMessages(after: messageId) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }
        
        // Simulate failed update
        let testError = TestError()
        env.channelUpdater!.update_completion?(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    // MARK: - Keystroke
    
    func test_keystroke() {
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
    
    func test_startTyping() {
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
    
    func test_stopTyping() {
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
    
    // MARK: - Message sending
    
    func test_createNewMessage_callsChannelUpdater() {
        let newMessageId: MessageId = .unique
        
        // New message values
        let text: String = .unique
//        let command: String = .unique
//        let arguments: String = .unique
        let extraData: NoExtraData = .defaultValue
        let attachments: [TestAttachmentEnvelope] = [.init(), .init(), .init()]
        let attachmentSeeds: [ChatMessageAttachmentSeed] = [
            .dummy(),
            .dummy(),
            .dummy()
        ]
        let quotedMessageId: MessageId = .unique
        
        // Simulate `createNewMessage` calls and catch the completion
        var completionCalled = false
        controller.createNewMessage(
            text: text,
//            command: command,
//            arguments: arguments,
            attachments: attachments + attachmentSeeds,
            quotedMessageId: quotedMessageId,
            extraData: extraData
        ) { [callbackQueueID] result in
            AssertTestQueue(withId: callbackQueueID)
            AssertResultSuccess(result, newMessageId)
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
        XCTAssertEqual(
            env.channelUpdater?.createNewMessage_attachments?.compactMap { $0 as? TestAttachmentEnvelope },
            attachments
        )
        XCTAssertEqual(
            env.channelUpdater?.createNewMessage_attachments?.compactMap { $0 as? ChatMessageAttachmentSeed },
            attachmentSeeds
        )
        XCTAssertEqual(env.channelUpdater?.createNewMessage_quotedMessageId, quotedMessageId)
        
        // Simulate successful update
        env.channelUpdater?.createNewMessage_completion?(.success(newMessageId))
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.createNewMessage_completion = nil
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_createNewMessage_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = _ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)
        
        // Simulate `createNewMessage` call and assert error is returned
        let result: Result<MessageId, Error> = try await { [callbackQueueID] completion in
            controller.createNewMessage(
                text: .unique,
//                command: .unique,
//                arguments: .unique,
                extraData: .defaultValue
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
    
    // MARK: - Adding members
    
    func test_addMembers_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = _ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)
        let members: Set<UserId> = [.unique]

        // Simulate `addMembers` call and assert error is returned
        var error: Error? = try await { [callbackQueueID] completion in
            controller.addMembers(userIds: members) { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid!)

        // Simulate `addMembers` call and assert no error is returned
        error = try await { [callbackQueueID] completion in
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
    
    // MARK: - Removing members
    
    func test_removeMembers_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = _ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)
        let members: Set<UserId> = [.unique]

        // Simulate `removeMembers` call and assert error is returned
        var error: Error? = try await { [callbackQueueID] completion in
            controller.removeMembers(userIds: members) { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate successful backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid!)

        // Simulate `removeMembers` call and assert no error is returned
        error = try await { [callbackQueueID] completion in
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
    
    func test_markRead_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = _ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)
        
        // Simulate `markRead` call and assert error is returned
        var error: Error? = try await { [callbackQueueID] completion in
            controller.markRead { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)
        
        // Simulate successful backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid!)
        
        // Simulate `markRead` call and assert no error is returned
        error = try await { [callbackQueueID] completion in
            controller.markRead { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
            env.channelUpdater!.markRead_completion?(nil)
        }
        
        XCTAssertNil(error)
    }
    
    func test_markRead_callsChannelUpdater() {
        // Simulate `markRead` call and catch the completion
        var completionCalled = false
        controller.markRead { [callbackQueueID] error in
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
        XCTAssertEqual(env.channelUpdater!.markRead_cid, channelId)
        XCTAssertFalse(completionCalled)
        
        // Simulate successful update
        env.channelUpdater!.markRead_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelUpdater!.markRead_completion = nil
        
        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_markRead_propagatesErrorFromUpdater() {
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
    
    // MARK: - Enable slow mode (cooldown)
    
    func test_enableSlowMode_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = _ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)
        
        // Simulate `enableSlowMode` call and assert error is returned
        var error: Error? = try await { [callbackQueueID] completion in
            controller.enableSlowMode(cooldownDuration: .random(in: 1...120)) { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)
        
        // Simulate successful backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid!)
        
        // Simulate `enableSlowMode` call and assert no error is returned
        error = try await { [callbackQueueID] completion in
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
        let query = _ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)
        
        // Simulate successful backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid!)
        
        // Simulate `enableSlowMode` call with invalid cooldown and assert error is returned
        var error: Error? = try await { [callbackQueueID] completion in
            controller.enableSlowMode(cooldownDuration: .random(in: 130...250)) { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.InvalidCooldownDuration)
        
        // Simulate `enableSlowMode` call with another invalid cooldown and assert error is returned
        error = try await { [callbackQueueID] completion in
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
        let query = _ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)
        
        // Simulate `disableSlowMode` call and assert error is returned
        var error: Error? = try await { [callbackQueueID] completion in
            controller.disableSlowMode { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)
        
        // Simulate successful backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid!)
        
        // Simulate `markRead` call and assert no error is returned
        error = try await { [callbackQueueID] completion in
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
}

private class TestEnvironment {
    var channelUpdater: ChannelUpdaterMock<NoExtraData>?
    var eventSender: EventSenderMock<NoExtraData>?
    
    lazy var environment: ChatChannelController.Environment = .init(
        channelUpdaterBuilder: { [unowned self] in
            self.channelUpdater = ChannelUpdaterMock(database: $0, apiClient: $1)
            return self.channelUpdater!
        },
        eventSenderBuilder: { [unowned self] in
            self.eventSender = EventSenderMock(database: $0, apiClient: $1)
            return self.eventSender!
        }
    )
}

/// A concrete `ChannelControllerDelegate` implementation allowing capturing the delegate calls
private class TestDelegate: QueueAwareDelegate, ChatChannelControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var willStartFetchingRemoteDataCalledCounter = 0
    @Atomic var didStopFetchingRemoteDataCalledCounter = 0
    @Atomic var didUpdateChannel_channel: EntityChange<ChatChannel>?
    @Atomic var didUpdateMessages_messages: [ListChange<ChatMessage>]?
    @Atomic var didReceiveMemberEvent_event: MemberEvent?
    @Atomic var didChangeTypingMembers_typingMembers: Set<ChatChannelMember>?
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }
    
    func controllerWillStartFetchingRemoteData(_ controller: Controller) {
        willStartFetchingRemoteDataCalledCounter += 1
        validateQueue()
    }
    
    func controllerDidStopFetchingRemoteData(_ controller: Controller, withError error: Error?) {
        didStopFetchingRemoteDataCalledCounter += 1
        validateQueue()
    }
    
    func channelController(_ channelController: ChatChannelController, didUpdateMessages changes: [ListChange<ChatMessage>]) {
        didUpdateMessages_messages = changes
        validateQueue()
    }
    
    func channelController(_ channelController: ChatChannelController, didUpdateChannel channel: EntityChange<ChatChannel>) {
        didUpdateChannel_channel = channel
        validateQueue()
    }
    
    func channelController(_ channelController: ChatChannelController, didReceiveMemberEvent event: MemberEvent) {
        didReceiveMemberEvent_event = event
        validateQueue()
    }
    
    func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingMembers typingMembers: Set<ChatChannelMember>
    ) {
        didChangeTypingMembers_typingMembers = typingMembers
        validateQueue()
    }
}

/// A concrete `ChannelControllerDelegateGeneric` implementation allowing capturing the delegate calls.
private class TestDelegateGeneric: QueueAwareDelegate, _ChatChannelControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didUpdateChannel_channel: EntityChange<ChatChannel>?
    @Atomic var didUpdateMessages_messages: [ListChange<ChatMessage>]?
    @Atomic var didReceiveMemberEvent_event: MemberEvent?
    @Atomic var didChangeTypingMembers_typingMembers: Set<ChatChannelMember>?
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }
    
    func channelController(_ channelController: ChatChannelController, didUpdateMessages changes: [ListChange<ChatMessage>]) {
        didUpdateMessages_messages = changes
        validateQueue()
    }
    
    func channelController(_ channelController: ChatChannelController, didUpdateChannel channel: EntityChange<ChatChannel>) {
        didUpdateChannel_channel = channel
        validateQueue()
    }
    
    func channelController(_ channelController: ChatChannelController, didReceiveMemberEvent event: MemberEvent) {
        didReceiveMemberEvent_event = event
        validateQueue()
    }
    
    func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingMembers typingMembers: Set<ChatChannelMember>
    ) {
        didChangeTypingMembers_typingMembers = typingMembers
        validateQueue()
    }
}

extension _TokenProvider {
    static func invalid(_ error: Error = TestError()) -> Self {
        .closure {
            $1(.failure(error))
        }
    }
}
