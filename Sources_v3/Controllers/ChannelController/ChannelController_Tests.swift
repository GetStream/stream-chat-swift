//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient
import XCTest

class ChannelController_Tests: StressTestCase {
    fileprivate var env: TestEnvironment!
    
    var client: ChatClient!
    
    var channelId: ChannelId!
    
    var controller: ChannelController!
    var controllerCallbackQueueID: UUID!
    /// Workaround for uwrapping **controllerCallbackQueueID!** in each closure that captures it
    private var callbackQueueID: UUID { controllerCallbackQueueID }
    
    override func setUp() {
        super.setUp()
        
        env = TestEnvironment()
        client = Client.mock
        channelId = ChannelId.unique
        controller = ChannelController(channelQuery: .init(cid: channelId), client: client, environment: env.environment)
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }
    
    override func tearDown() {
        controllerCallbackQueueID = nil
        
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
    
    // MARK: - Start updating tests
    
    func test_startUpdating_changesControllerState() {
        // Check if controller is inactive initially.
        assert(controller.state == .inactive)
        
        // Simulate `startUpdating` call
        controller.startUpdating()
        
        // Check if state changed after `startUpdating` call
        XCTAssertEqual(controller.state, .localDataFetched)
        
        // Simulate successfull network call.
        env.channelUpdater?.update_completion?(nil)
        
        // Check if state changed after successful network call.
        XCTAssertEqual(controller.state, .remoteDataFetched)
    }
    
    func test_startUpdating_changesControllerStateOnError() {
        // Check if controller is inactive initially.
        assert(controller.state == .inactive)
        
        // Simulate `startUpdating` call
        controller.startUpdating()
        
        // Check if state changed after `startUpdating` call
        XCTAssertEqual(controller.state, .localDataFetched)
        
        // Simulate failed network call.
        let error = TestError()
        env.channelUpdater?.update_completion?(error)
        
        // Check if state changed after failed network call.
        XCTAssertEqual(controller.state, .remoteDataFetchFailed(ClientError(with: error)))
    }
    
    func test_noChangesAreReported_beforeCallingStartUpdating() throws {
        // Save a new channel to DB
        client.databaseContainer.write { session in
            try session.saveChannel(payload: self.dummyPayload(with: self.channelId), query: nil)
        }
        
        // Assert the channel is not loaded
        AssertAsync.staysTrue(controller.channel == nil)
        AssertAsync.staysTrue(controller.messages.isEmpty)
    }
    
    func test_startUpdating_fetchesExistingChannel() throws {
        let payload = dummyPayload(with: channelId)
        // Save two channels to DB (only one matching the query) and wait for completion
        _ = try await {
            client.databaseContainer.write({ session in
                // Channel with the id matching the query
                try session.saveChannel(payload: payload)
                // Other channel
                try session.saveChannel(payload: self.dummyPayload(with: .unique))
            }, completion: $0)
        }
        
        // Start updating
        controller.startUpdating()
        
        // Assert the channel and messages are loaded
        XCTAssertEqual(controller.channel?.cid, channelId)
        XCTAssertEqual(Set(controller.messages.map(\.id)), Set(payload.messages.map(\.id)))
    }
    
    func test_startUpdating_callsChannelUpdater() {
        // Simulate `startUpdating` calls and catch the completion
        var completionCalled = false
        controller.startUpdating { [callbackQueueID] error in
            XCTAssertNil(error)
            AssertTestQueue(withId: callbackQueueID)
            completionCalled = true
        }
        
        // Assert the updater is called with the query
        XCTAssertEqual(env.channelUpdater!.update_channelQuery?.cid, channelId)
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        
        // Simulate successfull udpate
        env.channelUpdater!.update_completion?(nil)
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_startUpdating_propagesErrorFromUpdater() {
        // Simulate `startUpdating` call and catch the completion
        var completionCalledError: Error?
        controller.startUpdating { [callbackQueueID] in
            completionCalledError = $0
            AssertTestQueue(withId: callbackQueueID)
        }
        
        // Simulate failed udpate
        let testError = TestError()
        env.channelUpdater!.update_completion?(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // MARK: - Creating `ChannelController` tests

    func test_channelControllerForNewChannel_createdCorreclty() {
        let cid: ChannelId = .unique
        let team: String = .unique
        let members: Set<UserId> = [.unique]
        let invites: Set<UserId> = [.unique]
        let extraData: NameAndImageExtraData = .init(name: .unique, imageURL: .unique())

        // Create a new `ChannelController`
        let controller = client.channelController(
            createChannelWithId: cid,
            team: team,
            members: members,
            invites: invites,
            extraData: extraData
        )

        // Assert `ChannelQuery` created correctly
        XCTAssertEqual(cid, controller.channelQuery.cid)
        XCTAssertEqual(team, controller.channelQuery.channelPayload?.team)
        XCTAssertEqual(members, controller.channelQuery.channelPayload?.members)
        XCTAssertEqual(invites, controller.channelQuery.channelPayload?.invites)
        XCTAssertEqual(extraData, controller.channelQuery.channelPayload?.extraData)
    }

    func test_channelControllerForNew1on1Channel_createdCorreclty() throws {
        let team: String = .unique
        let members: Set<UserId> = [.unique]
        let extraData: NameAndImageExtraData = .init(name: .unique, imageURL: .unique())

        // Create a new `ChannelController`
        let controller = try client.channelController(createDirectMessageChannelWith: members, team: team, extraData: extraData)

        // Assert `ChannelQuery` created correctly
        XCTAssertEqual(team, controller.channelQuery.channelPayload?.team)
        XCTAssertEqual(members, controller.channelQuery.channelPayload?.members)
        XCTAssertEqual(extraData, controller.channelQuery.channelPayload?.extraData)
    }

    func test_channelControllerForNew1on1Channel_throwsError_OnEmptyMembers() {
        let members: Set<UserId> = []

        // Create a new `ChannelController`
        do {
            _ = try client.channelController(createDirectMessageChannelWith: members, team: .unique, extraData: .init())
        } catch {
            XCTAssert(error is ClientError.ChannelEmptyMembers)
        }
    }
    
    // MARK: - Channel change propagation tests
    
    func test_channelChanges_arePropagated() throws {
        // Simulate `startUpdating` call
        controller.startUpdating()
        
        // Simulate changes in the DB:
        _ = try await {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: self.channelId), query: nil)
            }, completion: $0)
        }
        
        // Assert the resulting value is updated
        AssertAsync.willBeEqual(controller.channel?.cid, channelId)
        
        assert(controller.channel?.isFrozen == true)
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
        
        // Simulate `startUpdating` call
        controller.startUpdating()
        
        // Simulate an incoming message
        let newMesageId: MessageId = .unique
        let newMessagePayload: MessagePayload<DefaultDataTypes> = .dummy(messageId: newMesageId, authorUserId: .unique)
        _ = try await {
            client.databaseContainer.write({ session in
                try session.saveMessage(payload: newMessagePayload, for: self.channelId)
            }, completion: $0)
        }
        
        // Assert the new message is presented
        AssertAsync.willBeTrue(controller.messages.contains { $0.id == newMesageId })
    }

    func test_messagesHaveCorrectOrder() throws {
        // Create a channel
        try client.databaseContainer.createChannel(cid: channelId, withMessages: false)
        
        // Insert two messages
        let message1: MessagePayload<DefaultDataTypes> = .dummy(messageId: .unique, authorUserId: .unique)
        let message2: MessagePayload<DefaultDataTypes> = .dummy(messageId: .unique, authorUserId: .unique)
        
        try client.databaseContainer.writeSynchronously {
            try $0.saveMessage(payload: message1, for: self.channelId)
            try $0.saveMessage(payload: message2, for: self.channelId)
        }
        
        // Set top-to-bottom ordering
        controller.listOrdering = .topToBottom
        
        // Simulate `startUpdating` call
        controller.startUpdating()
        
        // Check the order of messages is correct
        let topToBotttomIds = [message1, message2].sorted { $0.createdAt > $1.createdAt }.map(\.id)
        XCTAssertEqual(controller.messages.map(\.id), topToBotttomIds)
        
        // Set bottom-to-top ordering
        controller.listOrdering = .bottomToTop
        
        // Simulate `startUpdating` call to apply changes
        controller.startUpdating()
        
        // Check the order of messages is correct
        let bottomToTopIds = [message1, message2].sorted { $0.createdAt < $1.createdAt }.map(\.id)
        XCTAssertEqual(controller.messages.map(\.id), bottomToTopIds)
    }

    // MARK: - Delegate tests

    func test_delegateContinueToReceiveEvents_afterObserversReset() throws {
        // Assign `ChannelController` that creates new channel
        controller = ChannelController(
            channelQuery: ChannelQuery(cid: channelId),
            client: client,
            environment: env.environment,
            isChannelAlreadyCreated: false
        )
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)

        // Setup delegate
        let delegate = TestDelegate()
        delegate.expectedQueueId = controllerCallbackQueueID
        controller.delegate = delegate

        // Simulate `startUpdating` call
        controller.startUpdating()
        
        // Simulate updater's channelCreatedCallback call
        env.channelUpdater!.update_channelCreatedCallback!(channelId)

        // Simulate DB update
        var error = try await {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: self.channelId), query: nil)
            }, completion: $0)
        }
        XCTAssertNil(error)
        let channel: Channel = client.databaseContainer.viewContext.loadChannel(cid: channelId)!
        assert(channel.latestMessages.count == 1)
        let message: Message = channel.latestMessages.first!

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
        let newChannel: Channel = client.databaseContainer.viewContext.loadChannel(cid: newCid)!
        assert(channel.latestMessages.count == 1)
        let newMessage: Message = newChannel.latestMessages.first!

        // Assert DB observers call delegate updates for new `cid`
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateChannel_channel, .create(newChannel))
            Assert.willBeEqual(delegate.didUpdateMessages_messages, [.insert(newMessage, index: [0, 0])])
        }
    }
    
    func test_channelMemberEvents_areForwaredToDelegate() throws {
        let delegate = TestDelegate()
        controller.delegate = delegate
        
        // Set the queue for delegate calls
        delegate.expectedQueueId = controllerCallbackQueueID
        
        // Simulate `startUpdating()` call
        controller.startUpdating()
        
        // Send notification with event happened in the observed channel
        let event = TestMemberEvent(cid: controller.channelQuery.cid, userId: .unique)
        let notification = Notification(newEventReceived: event, sender: self)
        client.webSocketClient.eventNotificationCenter.post(notification)
        
        // Assert the event is received
        AssertAsync.willBeEqual(delegate.didReceiveMemberEvent_event as? TestMemberEvent, event)
    }
    
    func test_channelMemberEvents_areForwaredToGenericDelegate() throws {
        let delegate = TestDelegateGeneric()
        controller.setDelegate(delegate)
        
        // Set the queue for delegate calls
        delegate.expectedQueueId = controllerCallbackQueueID
        
        // Simulate `startUpdating()` call
        controller.startUpdating()
        
        // Send notification with event happened in the observed channel
        let event = TestMemberEvent(cid: controller.channelQuery.cid, userId: .unique)
        let notification = Notification(newEventReceived: event, sender: self)
        client.webSocketClient.eventNotificationCenter.post(notification)
        
        // Assert the event is received
        AssertAsync.willBeEqual(delegate.didReceiveMemberEvent_event as? TestMemberEvent, event)
    }
    
    func test_channelTypingEvents_areForwaredToDelegate() throws {
        let delegate = TestDelegate()
        controller.delegate = delegate
        
        // Set the queue for delegate calls
        delegate.expectedQueueId = controllerCallbackQueueID
        
        // Simulate `startUpdating()` call
        controller.startUpdating()
        
        // Send notification with event happened in the observed channel
        let event = TypingEvent(isTyping: true, cid: channelId, userId: .unique)
        let notification = Notification(newEventReceived: event, sender: self)
        client.webSocketClient.eventNotificationCenter.post(notification)
        
        // Assert the event is received
        AssertAsync.willBeEqual(delegate.didReceiveTypingEvent_event, event)
    }
    
    func test_channelTypingEvents_areForwaredToGenericDelegate() throws {
        let delegate = TestDelegateGeneric()
        controller.setDelegate(delegate)
        
        // Set the queue for delegate calls
        delegate.expectedQueueId = controllerCallbackQueueID
        
        // Simulate `startUpdating()` call
        controller.startUpdating()
        
        // Send notification with event happened in the observed channel
        let event = TypingEvent(isTyping: true, cid: channelId, userId: .unique)
        let notification = Notification(newEventReceived: event, sender: self)
        client.webSocketClient.eventNotificationCenter.post(notification)
        
        // Assert the event is received
        AssertAsync.willBeEqual(delegate.didReceiveTypingEvent_event, event)
    }
    
    func test_delegateMethodsAreCalled() throws {
        let delegate = TestDelegate()
        controller.delegate = delegate
        
        // Assert the delegate is assigned correctly. We should test this because of the type-erasing we
        // do in the controller.
        XCTAssert(controller.delegate === delegate)
        
        // Set the queue for delegate calls
        delegate.expectedQueueId = controllerCallbackQueueID
        
        // Simulate `startUpdating()` call
        controller.startUpdating()
        
        // Simulate DB update
        let error = try await {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: self.channelId), query: nil)
            }, completion: $0)
        }
        XCTAssertNil(error)
        let channel: Channel = client.databaseContainer.viewContext.loadChannel(cid: channelId)!
        assert(channel.latestMessages.count == 1)
        let message: Message = channel.latestMessages.first!
        
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateChannel_channel, .create(channel))
            Assert.willBeEqual(delegate.didUpdateMessages_messages, [.insert(message, index: [0, 0])])
        }
    }
    
    func test_genericDelegate() throws {
        let delegate = TestDelegateGeneric()
        controller.setDelegate(delegate)
        
        // Set the queue for delegate calls
        delegate.expectedQueueId = controllerCallbackQueueID
        
        // Simulate `startUpdating()` call
        controller.startUpdating()
        
        // Simulate DB update
        _ = try await {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: self.channelId), query: nil)
            }, completion: $0)
        }
        let channel: Channel = client.databaseContainer.viewContext.loadChannel(cid: channelId)!
        assert(channel.latestMessages.count == 1)
        let message: Message = channel.latestMessages.first!
        
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateChannel_channel, .create(channel))
            Assert.willBeEqual(delegate.didUpdateMessages_messages, [.insert(message, index: [0, 0])])
        }
    }
    
    // MARK: - Channel actions propagation tests

    func setupControllerForNewChannel(query: ChannelQuery<DefaultDataTypes>) {
        controller = ChannelController(
            channelQuery: query,
            client: client,
            environment: env.environment,
            isChannelAlreadyCreated: false
        )
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
        controller.startUpdating()
    }
    
    // MARK: - Updating channel
    
    func test_updateChannel_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `updateChannel` call and assert the error is returned
        var error: Error? = try await { [callbackQueueID] completion in
            controller.updateChannel(team: nil, extraData: .init()) { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate succsesfull backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid)

        // Simulate `updateChannel` call and assert no error is returned
        error = try await { [callbackQueueID] completion in
            controller.updateChannel(team: nil, extraData: .init()) { error in
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
        controller.updateChannel(team: .unique, extraData: .init()) { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }
        
        // Assert payload is passed to `channelUpdater`, completion is not called yet
        XCTAssertNotNil(env.channelUpdater!.updateChannel_payload)
        
        // Simulate successfull udpate
        env.channelUpdater!.updateChannel_completion?(nil)
        
        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_updateChannel_propagesErrorFromUpdater() {
        // Simulate `updateChannel` call and catch the completion
        var completionCalledError: Error?
        controller.updateChannel(team: .unique, extraData: .init()) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }
        
        // Simulate failed udpate
        let testError = TestError()
        env.channelUpdater!.updateChannel_completion?(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // MARK: - Muting channel
    
    func test_muteChannel_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `muteChannel` call and assert error is returned
        var error: Error? = try await { [callbackQueueID] completion in
            controller.muteChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate succsesfull backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid)

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
        
        // Assert cid and muted state are passed to `channelUpdater`, completion is not called yet
        XCTAssertEqual(env.channelUpdater!.muteChannel_cid, channelId)
        XCTAssertEqual(env.channelUpdater!.muteChannel_mute, true)
        XCTAssertFalse(completionCalled)
        
        // Simulate successfull udpate
        env.channelUpdater!.muteChannel_completion?(nil)
        
        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_muteChannel_propagesErrorFromUpdater() {
        // Simulate `muteChannel` call and catch the completion
        var completionCalledError: Error?
        controller.muteChannel { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }
        
        // Simulate failed udpate
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
        var error: Error? = try await { [callbackQueueID] completion in
            controller.muteChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate succsesfull backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid)

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
        
        // Assert cid and muted state are passed to `channelUpdater`, completion is not called yet
        XCTAssertEqual(env.channelUpdater!.muteChannel_cid, channelId)
        XCTAssertEqual(env.channelUpdater!.muteChannel_mute, false)
        XCTAssertFalse(completionCalled)
        
        // Simulate successfull udpate
        env.channelUpdater!.muteChannel_completion?(nil)
        
        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_unmuteChannel_propagesErrorFromUpdater() {
        // Simulate `unmuteChannel` call and catch the completion
        var completionCalledError: Error?
        controller.unmuteChannel { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }
        
        // Simulate failed udpate
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
        var error: Error? = try await { [callbackQueueID] completion in
            controller.deleteChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate succsesfull backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid)

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
        
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        
        // Simulate successfull udpate
        env.channelUpdater?.deleteChannel_completion?(nil)
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        
        XCTAssertEqual(env.channelUpdater?.deleteChannel_cid, channelId)
    }
    
    func test_deleteChannel_callsChannelUpdaterWithError() {
        // Simulate `muteChannel` call and catch the completion
        var completionCalledError: Error?
        controller.deleteChannel { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }
        
        // Simulate failed udpate
        let testError = TestError()
        env.channelUpdater!.deleteChannel_completion?(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    // MARK: - Hiding channel

    func test_hideChannel_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)

        // Simulate `hideChannel` call and assert error is returned
        var error: Error? = try await { [callbackQueueID] completion in
            controller.hideChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate succsesfull backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid)

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
        
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        
        // Simulate successfull udpate
        env.channelUpdater?.hideChannel_completion?(nil)
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        
        XCTAssertEqual(env.channelUpdater?.hideChannel_userId, client.currentUserId)
        XCTAssertEqual(env.channelUpdater?.hideChannel_cid, channelId)
        XCTAssertEqual(env.channelUpdater?.hideChannel_clearHistory, false)
    }
    
    func test_hideChannel_callsChannelUpdaterWithError() {
        // Simulate `hideChannel` call and catch the completion
        var completionCalledError: Error?
        controller.hideChannel(clearHistory: false) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }
        
        // Simulate failed udpate
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
        var error: Error? = try await { [callbackQueueID] completion in
            controller.showChannel { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)

        // Simulate succsesfull backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid)

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
        
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        
        // Simulate successfull udpate
        env.channelUpdater?.showChannel_completion?(nil)
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        
        XCTAssertEqual(env.channelUpdater?.showChannel_cid, channelId)
        XCTAssertNotNil(env.channelUpdater?.showChannel_userId)
    }
    
    func test_showChannel_callsChannelUpdaterWithError() {
        // Simulate `showChannel` call and catch the completion
        var completionCalledError: Error?
        controller.showChannel { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }
        
        // Simulate failed udpate
        let testError = TestError()
        env.channelUpdater!.showChannel_completion?(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    // MARK: - Message loading
    
    // Helper function that creates channel with message
    func setupChannelWithMessage(_ session: DatabaseSession) throws -> MessageId {
        let dummyUserPayload: CurrentUserPayload<DefaultDataTypes.User> = .dummy(userId: .unique, role: .user)
        try session.saveCurrentUser(payload: dummyUserPayload)
        try session.saveChannel(payload: dummyPayload(with: channelId))
        let message = try session.createNewMessage(
            in: channelId,
            text: "Message",
            extraData: DefaultDataTypes.Message.defaultValue
        )
        return message.id
    }
    
    func test_loadNextMessages_callsChannelUpdater() throws {
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
        
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        
        // Simulate successfull udpate
        env.channelUpdater?.update_completion?(nil)
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        
        // Assert correct `Pagination` is created
        XCTAssertEqual(env!.channelUpdater?.update_channelQuery?.messagesPagination, [.limit(25), .lessThan(messageId!)])
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
        
        // Simulate `loadNextMessages` call and catch the completion
        var completionCalledError: Error?
        controller.loadNextMessages(after: messageId) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }
        
        // Simulate failed udpate
        let testError = TestError()
        env.channelUpdater!.update_completion?(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    func test_loadPreviousMessages_callsChannelUdpdate() throws {
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
        
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        
        // Simulate successfull udpate
        env.channelUpdater?.update_completion?(nil)
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        
        // Assert correct `Pagination` is created
        XCTAssertEqual(env!.channelUpdater?.update_channelQuery?.messagesPagination, [.limit(25), .greaterThan(messageId!)])
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
        
        // Simulate failed udpate
        let testError = TestError()
        env.channelUpdater!.update_completion?(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    // MARK: - Keystroke
    
    func test_keystroke() {
        controller.keystroke {
            XCTAssertNil($0)
        }
        
        // Simulate `keystroke` call and catch the completion
        var completionCalledError: Error?
        controller.keystroke { completionCalledError = $0 }
        
        // Check keystroke cid.
        XCTAssertEqual(env.eventSender!.keystroke_cid, channelId)
        
        // Simulate failed udpate
        let testError = TestError()
        env.eventSender!.keystroke_completion!(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    func test_startTyping() {
        controller.startTyping {
            XCTAssertNil($0)
        }
        
        // Simulate `startTyping` call and catch the completion
        var completionCalledError: Error?
        controller.startTyping { completionCalledError = $0 }
        
        // Check `startTyping` cid.
        XCTAssertEqual(env.eventSender!.startTyping_cid, channelId)
        
        // Simulate failed udpate
        let testError = TestError()
        env.eventSender!.startTyping_completion!(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    func test_stopTyping() {
        controller.stopTyping {
            XCTAssertNil($0)
        }
        
        // Simulate `stopTyping` call and catch the completion
        var completionCalledError: Error?
        controller.stopTyping { completionCalledError = $0 }
        
        // Check `stopTyping` cid.
        XCTAssertEqual(env.eventSender!.stopTyping_cid, channelId)
        
        // Simulate failed udpate
        let testError = TestError()
        env.eventSender!.stopTyping_completion!(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    // MARK: - Message sending
    
    func test_createNewMessage_callsChannelUpdater() {
        let newMessageId: MessageId = .unique
        
        // New message values
        let text: String = .unique
        let command: String = .unique
        let arguments: String = .unique
        let parentMessageId: MessageId = .unique
        let showReplyInChannel = true
        let extraData: DefaultDataTypes.Message = .defaultValue
        
        // Simulate `createNewMessage` calls and catch the completion
        var completionCalled = false
        controller.createNewMessage(
            text: text,
            command: command,
            arguments: arguments,
            parentMessageId: parentMessageId,
            showReplyInChannel: showReplyInChannel,
            extraData: extraData
        ) { [callbackQueueID] result in
            AssertTestQueue(withId: callbackQueueID)
            AssertResultSuccess(result, newMessageId)
            completionCalled = true
        }
        
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        
        // Simulate successfull udpate
        env.channelUpdater?.createNewMessage_completion?(.success(newMessageId))
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        
        XCTAssertEqual(env.channelUpdater?.createNewMessage_cid, channelId)
        XCTAssertEqual(env.channelUpdater?.createNewMessage_text, text)
        XCTAssertEqual(env.channelUpdater?.createNewMessage_command, command)
        XCTAssertEqual(env.channelUpdater?.createNewMessage_arguments, arguments)
        XCTAssertEqual(env.channelUpdater?.createNewMessage_parentMessageId, parentMessageId)
        XCTAssertEqual(env.channelUpdater?.createNewMessage_showReplyInChannel, showReplyInChannel)
        XCTAssertEqual(env.channelUpdater?.createNewMessage_extraData, extraData)
    }
    
    func test_createNewMessage_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)
        
        // Simulate `createNewMessage` call and assert error is returned
        let result: Result<MessageId, Error> = try await { [callbackQueueID] completion in
            controller.createNewMessage(
                text: .unique,
                command: .unique,
                arguments: .unique,
                parentMessageId: .unique,
                showReplyInChannel: true,
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
        let query = ChannelQuery(channelPayload: .unique)
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

        // Simulate succsesfull backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid)

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
        
        // Assert cid and members state are passed to `channelUpdater`, completion is not called yet
        XCTAssertEqual(env.channelUpdater!.addMembers_cid, channelId)
        XCTAssertEqual(env.channelUpdater!.addMembers_userIds, members)
        XCTAssertFalse(completionCalled)
        
        // Simulate successfull udpate
        env.channelUpdater!.addMembers_completion?(nil)
        
        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_addMembers_propagesErrorFromUpdater() {
        let members: Set<UserId> = [.unique]
        
        // Simulate `addMembers` call and catch the completion
        var completionCalledError: Error?
        controller.addMembers(userIds: members) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }
        
        // Simulate failed udpate
        let testError = TestError()
        env.channelUpdater!.addMembers_completion?(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    // MARK: - Removing members
    
    func test_removeMembers_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
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

        // Simulate succsesfull backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid)

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
        
        // Assert cid and members state are passed to `channelUpdater`, completion is not called yet
        XCTAssertEqual(env.channelUpdater!.removeMembers_cid, channelId)
        XCTAssertEqual(env.channelUpdater!.removeMembers_userIds, members)
        XCTAssertFalse(completionCalled)
        
        // Simulate successfull udpate
        env.channelUpdater!.removeMembers_completion?(nil)
        
        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_removeMembers_propagesErrorFromUpdater() {
        let members: Set<UserId> = [.unique]
        
        // Simulate `removeMembers` call and catch the completion
        var completionCalledError: Error?
        controller.removeMembers(userIds: members) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }
        
        // Simulate failed udpate
        let testError = TestError()
        env.channelUpdater!.removeMembers_completion?(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    // MARK: - Mark read
    
    func test_markRead_failsForNewChannels() throws {
        //  Create `ChannelController` for new channel
        let query = ChannelQuery(channelPayload: .unique)
        setupControllerForNewChannel(query: query)
        
        // Simulate `markRead` call and assert error is returned
        var error: Error? = try await { [callbackQueueID] completion in
            controller.markRead { error in
                AssertTestQueue(withId: callbackQueueID)
                completion(error)
            }
        }
        XCTAssert(error is ClientError.ChannelNotCreatedYet)
        
        // Simulate succsesfull backend channel creation
        env.channelUpdater!.update_channelCreatedCallback?(query.cid)
        
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
        
        // Assert cid is passed to `channelUpdater`, completion is not called yet
        XCTAssertEqual(env.channelUpdater!.markRead_cid, channelId)
        XCTAssertFalse(completionCalled)
        
        // Simulate successfull udpate
        env.channelUpdater!.markRead_completion?(nil)
        
        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_markRead_propagesErrorFromUpdater() {
        // Simulate `markRead` call and catch the completion
        var completionCalledError: Error?
        controller.markRead { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }
        
        // Simulate failed udpate
        let testError = TestError()
        env.channelUpdater!.markRead_completion?(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
}

private class TestEnvironment {
    var channelUpdater: ChannelUpdaterMock<DefaultDataTypes>?
    var eventSender: EventSenderMock<DefaultDataTypes>?
    
    lazy var environment: ChannelController.Environment = .init(
        channelUpdaterBuilder: { [unowned self] in
            self.channelUpdater = ChannelUpdaterMock(database: $0, webSocketClient: $1, apiClient: $2)
            return self.channelUpdater!
        },
        eventSenderBuilder: { [unowned self] in
            self.eventSender = EventSenderMock(database: $0, webSocketClient: $1, apiClient: $2)
            return self.eventSender!
        }
    )
}

/// A concrete `ChanneControllerDelegate` implementation allowing capturing the delegate calls
private class TestDelegate: QueueAwareDelegate, ChannelControllerDelegate {
    @Atomic var willStartFetchingRemoteDataCalledCounter = 0
    @Atomic var didStopFetchingRemoteDataCalledCounter = 0
    @Atomic var didUpdateChannel_channel: EntityChange<Channel>?
    @Atomic var didUpdateMessages_messages: [ListChange<Message>]?
    @Atomic var didReceiveMemberEvent_event: MemberEvent?
    @Atomic var didReceiveTypingEvent_event: TypingEvent?
    
    func controllerWillStartFetchingRemoteData(_ controller: Controller) {
        willStartFetchingRemoteDataCalledCounter += 1
        validateQueue()
    }
    
    func controllerDidStopFetchingRemoteData(_ controller: Controller, withError error: Error?) {
        didStopFetchingRemoteDataCalledCounter += 1
        validateQueue()
    }
    
    func channelController(_ channelController: ChannelController, didUpdateMessages changes: [ListChange<Message>]) {
        didUpdateMessages_messages = changes
        validateQueue()
    }
    
    func channelController(_ channelController: ChannelController, didUpdateChannel channel: EntityChange<Channel>) {
        didUpdateChannel_channel = channel
        validateQueue()
    }
    
    func channelController(_ channelController: ChannelController, didReceiveMemberEvent event: MemberEvent) {
        didReceiveMemberEvent_event = event
        validateQueue()
    }
    
    func channelController(_ channelController: ChannelController, didReceiveTypingEvent event: TypingEvent) {
        didReceiveTypingEvent_event = event
        validateQueue()
    }
}

/// A concrete `ChannelControllerDelegateGeneric` implementation allowing capturing the delegate calls.
private class TestDelegateGeneric: QueueAwareDelegate, ChannelControllerDelegateGeneric {
    @Atomic var didUpdateChannel_channel: EntityChange<Channel>?
    @Atomic var didUpdateMessages_messages: [ListChange<Message>]?
    @Atomic var didReceiveMemberEvent_event: MemberEvent?
    @Atomic var didReceiveTypingEvent_event: TypingEvent?
    
    func channelController(_ channelController: ChannelController, didUpdateMessages changes: [ListChange<Message>]) {
        didUpdateMessages_messages = changes
        validateQueue()
    }
    
    func channelController(_ channelController: ChannelController, didUpdateChannel channel: EntityChange<Channel>) {
        didUpdateChannel_channel = channel
        validateQueue()
    }
    
    func channelController(_ channelController: ChannelController, didReceiveMemberEvent event: MemberEvent) {
        didReceiveMemberEvent_event = event
        validateQueue()
    }
    
    func channelController(_ channelController: ChannelController, didReceiveTypingEvent event: TypingEvent) {
        didReceiveTypingEvent_event = event
        validateQueue()
    }
}
