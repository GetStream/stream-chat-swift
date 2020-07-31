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
        
        channelId = ChannelId(type: .messaging, id: "test")
        
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
        let controller = client.channelController(for: channelId)
        XCTAssert(controller.client === client)
        XCTAssertEqual(controller.channelQuery.cid, channelId)
    }
    
    // MARK: - Start updating tests
    
    func test_noChangesAreReported_beforeCallingStartUpdating() throws {
        // Save a new channel to DB
        client.databaseContainer.write { session in
            try session.saveChannel(payload: self.dummyPayload(with: .unique), query: nil)
        }
        
        // Assert the channel is not loaded
        AssertAsync.staysTrue(controller.channel == nil)
    }
    
    func test_startUpdating_fetchesExistingChannel() throws {
        // Save two channels to DB (only one matching the query) and wait for completion
        _ = try await {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: self.channelId), query: nil)
                try session.saveChannel(payload: self.dummyPayload(with: .unique), query: nil)
            }, completion: $0)
        }
        
        // Start updating
        controller.startUpdating()
        
        // Assert the existing channel is loaded
        XCTAssertEqual(controller.channel?.cid, channelId)
    }
    
    func test_startUpdating_callsChannelUpdater() {
        // Simulate `startUpdating` calls and catch the completion
        var completionCalled = false
        controller.startUpdating { error in
            XCTAssertNil(error)
            completionCalled = true
        }
        
        // Assert the updater is called with the query
        XCTAssertEqual(env.channelUpdater!.update_channelQuery?.cid, channelId)
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        
        // Simulate successfull udpate
        env.channelUpdater!.update_completion?(nil)
        
        // Completion should be called
        XCTAssertTrue(completionCalled)
    }
    
    func test_startUpdating_propagesErrorFromUpdater() {
        // Simulate `startUpdating` call and catch the completion
        var completionCalledError: Error?
        controller.startUpdating { completionCalledError = $0 }
        
        // Simulate failed udpate
        let testError = TestError()
        env.channelUpdater!.update_completion?(testError)
        
        // Completion should be called with the error
        XCTAssertEqual(completionCalledError as? TestError, testError)
    }
    
    // MARK: - Change propagation tests
    
    func test_changeAggregator_isSetAsDelegateForFRC() {
        // Simulate `startUpdating` call
        controller.startUpdating()
        
        XCTAssert(controller.fetchResultsController.delegate === env.changeAggregator)
    }
    
    func test_changesFromChangeAggregatorArePropagated() throws {
        // Simulate `startUpdating` call
        controller.startUpdating()
        
        // Simulate changes in the DB:
        // 1. Add the channel to the DB
        _ = try await {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: self.channelId), query: nil)
            }, completion: $0)
        }
        // 2. Simulate callback from ChangeAggregator
        let channel: Channel = client.databaseContainer.viewContext.loadChannel(cid: channelId)!
        env.changeAggregator?.onChange?([.insert(channel, index: [0, 0])])
        
        // Assert the resulting value is updated
        XCTAssertEqual(controller.channel?.cid, channelId)
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
        
        AssertAsync.willBeEqual(delegate.didUpdateChannel_channel, channel)
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
        
        AssertAsync.willBeEqual(delegate.didUpdateChannel_channel, channel)
    }
}

private class TestEnvironment {
    var channelUpdater: ChannelUpdaterMock<DefaultDataTypes>?
    var changeAggregator: ChangeAggregator<ChannelDTO, Channel>?
    
    lazy var environment: ChannelController.Environment = .init(channelUpdaterBuilder: { [unowned self] in
        self.channelUpdater = ChannelUpdaterMock(database: $0, webSocketClient: $1, apiClient: $2)
        return self.channelUpdater!
    },
                                                                changeAggregatorBuilder: { [unowned self] in
        self.changeAggregator = ChangeAggregator(itemCreator: $0)
        return self.changeAggregator!
    })
}

private class ChannelUpdaterMock<ExtraData: ExtraDataTypes>: ChannelUpdater<ExtraData> {
    var update_channelQuery: ChannelQuery<ExtraData>?
    var update_completion: ((Error?) -> Void)?
    
    override func update(channelQuery: ChannelQuery<ExtraData>, completion: ((Error?) -> Void)? = nil) {
        update_channelQuery = channelQuery
        update_completion = completion
    }
}

/// `NSFetchedResultsController` subclass allowing injecting fetched objects
private class TestFetchedResultsController: NSFetchedResultsController<ChannelDTO> {
    var simulatedFetchedObjects: [ChannelDTO]?
    
    override var fetchedObjects: [ChannelDTO]? {
        simulatedFetchedObjects ?? super.fetchedObjects
    }
}

/// A concrete `ChanneControllerDelegate` implementation allowing capturing the delegate calls
private class TestDelegate: QueueAwareDelegate, ChannelControllerDelegate {
    var willStartFetchingRemoteDataCalledCounter = 0
    var didStopFetchingRemoteDataCalledCounter = 0
    var didUpdateChannel_channel: Channel?
    
    func controllerWillStartFetchingRemoteData(_ controller: Controller) {
        willStartFetchingRemoteDataCalledCounter += 1
        validateQueue()
    }
    
    func controllerDidStopFetchingRemoteData(_ controller: Controller, withError error: Error?) {
        didStopFetchingRemoteDataCalledCounter += 1
        validateQueue()
    }
    
    func channelController(_ channelController: ChannelController, didUpdateChannel channel: Channel) {
        didUpdateChannel_channel = channel
        validateQueue()
    }
}

/// A concrete `ChannelControllerDelegateGeneric` implementation allowing capturing the delegate calls.
private class TestDelegateGeneric: QueueAwareDelegate, ChannelControllerDelegateGeneric {
    var willStartFetchingRemoteDataCalledCounter = 0
    var didStopFetchingRemoteDataCalledCounter = 0
    var didUpdateChannel_channel: Channel?
    
    func controllerWillStartFetchingRemoteData(_ controller: Controller) {
        willStartFetchingRemoteDataCalledCounter += 1
        validateQueue()
    }
    
    func controllerDidStopFetchingRemoteData(_ controller: Controller, withError error: Error?) {
        didStopFetchingRemoteDataCalledCounter += 1
        validateQueue()
    }
    
    func channelController(_ channelController: ChannelControllerGeneric<DefaultDataTypes>, didUpdateChannel channel: Channel) {
        didUpdateChannel_channel = channel
        validateQueue()
    }
}
