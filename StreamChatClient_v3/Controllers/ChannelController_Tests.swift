//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient_v3
import XCTest

class ChannelController_Tests: StressTestCase {
    fileprivate var env: TestEnvironment!
    
    var client: ChatClient!
    
    var channelId: ChannelId!
    
    var controller: ChannelController!
    
    override func setUp() {
        super.setUp()
        
        env = TestEnvironment()
        client = Client(config: ChatClientConfig(apiKey: .init(.unique)))
        channelId = ChannelId.unique
        controller = ChannelController(channelQuery: .init(channelId: channelId), client: client, environment: env.environment)
    }
    
    override func tearDown() {
        weak var weak_env = env
        weak var weak_client = client
        weak var weak_controller = controller
        
        env = nil
        client = nil
        controller = nil
        
        // We need to assert asynchronously, because there can be some delegate callbacks happening
        // on the background queue, that keeps the controller alive, until they have finished.
        AssertAsync {
            Assert.willBeNil(weak_env)
            Assert.willBeNil(weak_client)
            Assert.willBeNil(weak_controller)
        }
        
        super.tearDown()
    }
    
    func test_clientAndIdAreCorrect() {
        XCTAssert(controller.client === client)
        XCTAssertEqual(controller.channelQuery.cid, channelId)
    }
    
    // MARK: - Start updating tests
    
    func test_startUpdating_changesControllerState() {
        assert(controller.state == .idle)
        controller.startUpdating()
        XCTAssertEqual(controller.state, .active)
    }
    
    func test_noChangesAreReported_beforeCallingStartUpdating() throws {
        // Save a new channel to DB
        client.databaseContainer.write { session in
            try session.saveChannel(payload: self.dummyPayload(with: .unique), query: nil)
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
        let queueId = UUID()
        controller.callbackQueue = .testQueue(withId: queueId)
        
        // Simulate `startUpdating` calls and catch the completion
        var completionCalled = false
        controller.startUpdating { error in
            XCTAssertNil(error)
            AssertTestQueue(withId: queueId)
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
        let queueId = UUID()
        controller.callbackQueue = .testQueue(withId: queueId)
        
        // Simulate `startUpdating` call and catch the completion
        var completionCalledError: Error?
        controller.startUpdating {
            completionCalledError = $0
            AssertTestQueue(withId: queueId)
        }
        
        // Simulate failed udpate
        let testError = TestError()
        env.channelUpdater!.update_completion?(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
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
        let newMessagePayload = MessagePayload<DefaultDataTypes>.dummy(messageId: newMesageId, authorUserId: .unique)
        _ = try await {
            client.databaseContainer.write({ session in
                try session.saveMessage(payload: newMessagePayload, for: self.channelId)
            }, completion: $0)
        }
        
        // Assert the new message is presented
        AssertAsync.willBeTrue(controller.messages.contains { $0.id == newMesageId })
    }
    
    // MARK: - Delegate tests
    
    func test_delegateMethodsAreCalled() throws {
        let delegate = TestDelegate()
        controller.delegate = delegate
        
        // Assert the delegate is assigned correctly. We should test this because of the type-erasing we
        // do in the controller.
        XCTAssert(controller.delegate === delegate)
        
        // Set the queue for delegate calls
        let delegateQueueId = UUID()
        delegate.expectedQueueId = delegateQueueId
        controller.callbackQueue = DispatchQueue.testQueue(withId: delegateQueueId)
        
        // Simulate `startUpdating()` call
        controller.startUpdating()
        AssertAsync {
            Assert.willBeEqual(delegate.willStartFetchingRemoteDataCalledCounter, 1)
            Assert.staysEqual(delegate.didStopFetchingRemoteDataCalledCounter, 0)
        }
        
        // Simulate server response
        env.channelUpdater!.update_completion?(nil)
        AssertAsync {
            Assert.staysEqual(delegate.willStartFetchingRemoteDataCalledCounter, 1)
            Assert.willBeEqual(delegate.didStopFetchingRemoteDataCalledCounter, 1)
        }
        
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
        let delegateQueueId = UUID()
        delegate.expectedQueueId = delegateQueueId
        controller.callbackQueue = DispatchQueue.testQueue(withId: delegateQueueId)
        
        // Simulate `startUpdating()` call
        controller.startUpdating()
        AssertAsync {
            Assert.willBeEqual(delegate.willStartFetchingRemoteDataCalledCounter, 1)
            Assert.staysEqual(delegate.didStopFetchingRemoteDataCalledCounter, 0)
        }
        
        // Simulate server response
        env.channelUpdater!.update_completion?(nil)
        AssertAsync {
            Assert.staysEqual(delegate.willStartFetchingRemoteDataCalledCounter, 1)
            Assert.willBeEqual(delegate.didStopFetchingRemoteDataCalledCounter, 1)
        }
        
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

    func test_muteChannel_callsChannelUpdater() {
        // Simulate `muteChannel` call and catch the completion
        var completionCalled = false
        controller.muteChannel { error in
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
        controller.muteChannel {
            completionCalledError = $0
        }

        // Simulate failed udpate
        let testError = TestError()
        env.channelUpdater!.muteChannel_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    func test_unmuteChannel_callsChannelUpdater() {
        // Simulate `unmuteChannel` call and catch the completion
        var completionCalled = false
        controller.unmuteChannel { error in
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
        controller.unmuteChannel {
            completionCalledError = $0
        }

        // Simulate failed udpate
        let testError = TestError()
        env.channelUpdater!.muteChannel_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    func test_deleteChannel_callsChannelUpdater() {
        // Simulate `deleteChannel` calls and catch the completion
        var completionCalled = false
        controller.deleteChannel { error in
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
        controller.deleteChannel {
            completionCalledError = $0
        }

        // Simulate failed udpate
        let testError = TestError()
        env.channelUpdater!.deleteChannel_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    func test_hideChannel_callsChannelUpdater() {
        // Simulate `hideChannel` calls and catch the completion
        var completionCalled = false
        controller.hideChannel(clearHistory: false) { error in
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
        // Simulate `muteChannel` call and catch the completion
        var completionCalledError: Error?
        controller.hideChannel(clearHistory: false) {
            completionCalledError = $0
        }

        // Simulate failed udpate
        let testError = TestError()
        env.channelUpdater!.hideChannel_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    func test_showChannel_callsChannelUpdater() {
        // Simulate `showChannel` calls and catch the completion
        var completionCalled = false
        controller.showChannel { error in
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
        // Simulate `muteChannel` call and catch the completion
        var completionCalledError: Error?
        controller.showChannel {
            completionCalledError = $0
        }

        // Simulate failed udpate
        let testError = TestError()
        env.channelUpdater!.showChannel_completion?(testError)

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
}

private class TestEnvironment {
    var channelUpdater: ChannelUpdaterMock<DefaultDataTypes>?
    
    lazy var environment: ChannelController.Environment = .init(channelUpdaterBuilder: { [unowned self] in
        self.channelUpdater = ChannelUpdaterMock(database: $0, webSocketClient: $1, apiClient: $2)
        return self.channelUpdater!
    })
}

/// A concrete `ChanneControllerDelegate` implementation allowing capturing the delegate calls
private class TestDelegate: QueueAwareDelegate, ChannelControllerDelegate {
    var willStartFetchingRemoteDataCalledCounter = 0
    var didStopFetchingRemoteDataCalledCounter = 0
    var didUpdateChannel_channel: EntityChange<Channel>?
    var didUpdateMessages_messages: [ListChange<Message>]?
    
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
}

/// A concrete `ChannelControllerDelegateGeneric` implementation allowing capturing the delegate calls.
private class TestDelegateGeneric: QueueAwareDelegate, ChannelControllerDelegateGeneric {
    var willStartFetchingRemoteDataCalledCounter = 0
    var didStopFetchingRemoteDataCalledCounter = 0
    var didUpdateChannel_channel: EntityChange<Channel>?
    var didUpdateMessages_messages: [ListChange<Message>]?
    
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
}
