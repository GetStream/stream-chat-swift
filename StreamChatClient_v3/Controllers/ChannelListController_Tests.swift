//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient_v3
import XCTest

class ChannelListController_Tests: StressTestCase {
    fileprivate var env: TestEnvironment!
    
    var client: ChatClient!
    
    var query: ChannelListQuery!
    
    var controller: ChannelListController!
    
    override func setUp() {
        super.setUp()
        
        env = TestEnvironment()
        client = Client(config: ChatClientConfig(apiKey: .init(.unique)))
        query = .init(filter: .in("members", ["Luke"]))
        controller = ChannelListController(query: query, client: client, environment: env.environment)
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
    
    func test_clientAndQueryAreCorrect() {
        let controller = client.channelListController(query: query)
        XCTAssert(controller.client === client)
        XCTAssertEqual(controller.query.filter.filterHash, query.filter.filterHash)
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
            try session.saveChannel(payload: self.dummyPayload(with: .unique), query: self.query)
        }
        
        // Assert the channel is not loaded
        AssertAsync.staysTrue(controller.channels.isEmpty)
    }
    
    func test_startUpdating_fetchesExistingChannels() throws {
        // Save two channels to DB (only one matching the query) and wait for completion
        let cidMatchingQuery = ChannelId.unique
        let cidNotMatchingQuery = ChannelId.unique
        
        _ = try await {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: cidMatchingQuery), query: self.query)
                try session.saveChannel(payload: self.dummyPayload(with: cidNotMatchingQuery), query: nil)
            }, completion: $0)
        }
        
        // Start updating
        controller.startUpdating()
        
        // Assert the existing channel is loaded
        XCTAssertEqual(controller.channels.map(\.cid), [cidMatchingQuery])
    }
    
    func test_startUpdating_callsChannelQueryUpdater() {
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
        XCTAssertEqual(env.channelQueryUpdater!.update_query?.filter.filterHash, query.filter.filterHash)
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        
        // Simulate successfull udpate
        env.channelQueryUpdater!.update_completion?(nil)
        
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
        env.channelQueryUpdater!.update_completion?(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // MARK: - Change propagation tests
    
    func test_changesInTheDatabase_arePropagated() throws {
        // Simulate `startUpdating` call
        controller.startUpdating()
        
        // Simulate changes in the DB:
        // 1. Add the channel to the DB
        let cid: ChannelId = .unique
        _ = try await {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: cid), query: self.query)
            }, completion: $0)
        }
        
        // Assert the resulting value is updated
        AssertAsync.willBeEqual(controller.channels.map(\.cid), [cid])
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
        env.channelQueryUpdater!.update_completion?(nil)
        AssertAsync {
            Assert.staysEqual(delegate.willStartFetchingRemoteDataCalledCounter, 1)
            Assert.willBeEqual(delegate.didStopFetchingRemoteDataCalledCounter, 1)
        }
        
        // Simulate DB update
        let cid: ChannelId = .unique
        let error = try await {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: cid), query: self.query)
            }, completion: $0)
        }
        XCTAssertNil(error)
        let channel: Channel = client.databaseContainer.viewContext.loadChannel(cid: cid)!
        
        AssertAsync.willBeEqual(delegate.didChangeChannels_changes, [.insert(channel, index: [0, 0])])
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
        env.channelQueryUpdater!.update_completion?(nil)
        AssertAsync {
            Assert.staysEqual(delegate.willStartFetchingRemoteDataCalledCounter, 1)
            Assert.willBeEqual(delegate.didStopFetchingRemoteDataCalledCounter, 1)
        }
        
        // Simulate DB update
        let cid: ChannelId = .unique
        _ = try await {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: cid), query: self.query)
            }, completion: $0)
        }
        let channel: Channel = client.databaseContainer.viewContext.loadChannel(cid: cid)!
        
        AssertAsync.willBeEqual(delegate.didChangeChannels_changes, [.insert(channel, index: [0, 0])])
    }
}

private class TestEnvironment {
    var channelQueryUpdater: ChannelQueryUpdaterMock<DefaultDataTypes>?
    
    lazy var environment: ChannelListController.Environment =
        .init(channelQueryUpdaterBuilder: { [unowned self] in
                self.channelQueryUpdater = ChannelQueryUpdaterMock(database: $0,
                                                               webSocketClient: $1,
                                                               apiClient: $2)
                return self.channelQueryUpdater!
        })
}

private class ChannelQueryUpdaterMock<ExtraData: ExtraDataTypes>: ChannelListQueryUpdater<ExtraData> {
    var update_query: ChannelListQuery?
    var update_completion: ((Error?) -> Void)?
    
    override func update(channelListQuery: ChannelListQuery, completion: ((Error?) -> Void)? = nil) {
        update_query = channelListQuery
        update_completion = completion
    }
}

// A concrete `ChannelListControllerDelegate` implementation allowing capturing the delegate calls
private class TestDelegate: QueueAwareDelegate, ChannelListControllerDelegate {
    var willStartFetchingRemoteDataCalledCounter = 0
    var didStopFetchingRemoteDataCalledCounter = 0
    var didChangeChannels_changes: [ListChange<Channel>]?
    
    func controllerWillStartFetchingRemoteData(_ controller: Controller) {
        willStartFetchingRemoteDataCalledCounter += 1
        validateQueue()
    }
    
    func controllerDidStopFetchingRemoteData(_ controller: Controller, withError error: Error?) {
        didStopFetchingRemoteDataCalledCounter += 1
        validateQueue()
    }
    
    func controller(_ controller: ChannelListControllerGeneric<DefaultDataTypes>,
                    didChangeChannels changes: [ListChange<Channel>]) {
        didChangeChannels_changes = changes
        validateQueue()
    }
}

// A concrete `ChannelListControllerDelegateGeneric` implementation allowing capturing the delegate calls.
private class TestDelegateGeneric: QueueAwareDelegate, ChannelListControllerDelegateGeneric {
    var willStartFetchingRemoteDataCalledCounter = 0
    var didStopFetchingRemoteDataCalledCounter = 0
    var didChangeChannels_changes: [ListChange<Channel>]?
    
    func controllerWillStartFetchingRemoteData(_ controller: Controller) {
        willStartFetchingRemoteDataCalledCounter += 1
        validateQueue()
    }
    
    func controllerDidStopFetchingRemoteData(_ controller: Controller, withError error: Error?) {
        didStopFetchingRemoteDataCalledCounter += 1
        validateQueue()
    }
    
    func controller(_ controller: ChannelListControllerGeneric<DefaultDataTypes>,
                    didChangeChannels changes: [ListChange<Channel>]) {
        didChangeChannels_changes = changes
        validateQueue()
    }
}
