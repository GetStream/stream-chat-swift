//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient
import XCTest

class ChannelListController_Tests: StressTestCase {
    fileprivate var env: TestEnvironment!
    
    var client: ChatClient!
    
    var query: ChannelListQuery!
    
    var controller: ChannelListController!
    var controllerCallbackQueueID: UUID!
    /// Workaround for uwrapping **controllerCallbackQueueID!** in each closure that captures it
    private var callbackQueueID: UUID { controllerCallbackQueueID }
    
    override func setUp() {
        super.setUp()
        
        env = TestEnvironment()
        client = Client.mock
        query = .init(filter: .in("members", ["Luke"]))
        controller = ChannelListController(query: query, client: client, environment: env.environment)
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }
    
    override func tearDown() {
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
            Assert.canBeReleased(&env)
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
        // Check if controller is inactive initially.
        assert(controller.state == .inactive)
        
        // Simulate `startUpdating` call
        controller.startUpdating()
        
        // Check if state changed after `startUpdating` call
        XCTAssertEqual(controller.state, .localDataFetched)
        
        // Simulate successfull network call.
        env.channelListUpdater?.update_completion?(nil)
        
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
        env.channelListUpdater?.update_completion?(error)
        
        // Check if state changed after failed network call.
        XCTAssertEqual(controller.state, .remoteDataFetchFailed(ClientError(with: error)))
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
        // Save three channels to DB
        let cidMatchingQuery = ChannelId.unique
        let cidMatchingQueryDeleted = ChannelId.unique
        let cidNotMatchingQuery = ChannelId.unique
        
        try client.databaseContainer.writeSynchronously { session in
            // Insert a channel matching the query
            try session.saveChannel(payload: self.dummyPayload(with: cidMatchingQuery), query: self.query)
            
            // Insert a deleted channel matching the query
            let dto = try session.saveChannel(payload: self.dummyPayload(with: cidMatchingQueryDeleted), query: self.query)
            dto.deletedAt = .unique
            
            // Insert a channel not matching the query
            try session.saveChannel(payload: self.dummyPayload(with: cidNotMatchingQuery), query: nil)
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
        XCTAssertEqual(env.channelListUpdater!.update_query?.filter.filterHash, query.filter.filterHash)
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        
        // Simulate successfull udpate
        env.channelListUpdater!.update_completion?(nil)
        
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
        env.channelListUpdater!.update_completion?(testError)
        
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
    
    // MARK: - Channels pagination
    
    func test_loadNextChannels_callsChannelListUpdater() {
        var completionCalled = false
        let limit = 42
        controller.loadNextChannels(limit: limit) { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }
        
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        
        // Simulate successfull udpate
        env!.channelListUpdater?.update_completion?(nil)
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        
        // Assert correct `Pagination` is created
        XCTAssertEqual(env!.channelListUpdater?.update_query?.pagination, [.limit(limit), .offset(controller.channels.count)])
    }
    
    func test_loadNextChannels_callsChannelUpdaterWithError() {
        // Simulate `loadNextChannels` call and catch the completion
        var completionCalledError: Error?
        controller.loadNextChannels { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }
        
        // Simulate failed udpate
        let testError = TestError()
        env.channelListUpdater!.update_completion?(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    // MARK: - Mark all read
    
    func test_markAllRead_callsChannelListUpdater() {
        // Simulate `markRead` call and catch the completion
        var completionCalled = false
        controller.markAllRead { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }
        
        XCTAssertFalse(completionCalled)
        
        // Simulate successfull udpate
        env.channelListUpdater!.markAllRead_completion?(nil)
        
        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_markAllRead_propagesErrorFromUpdater() {
        // Simulate `markRead` call and catch the completion
        var completionCalledError: Error?
        controller.markAllRead { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }
        
        // Simulate failed udpate
        let testError = TestError()
        env.channelListUpdater!.markAllRead_completion?(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
}

private class TestEnvironment {
    @Atomic var channelListUpdater: ChannelListUpdaterMock<DefaultDataTypes>?
    
    lazy var environment: ChannelListController.Environment =
        .init(channelQueryUpdaterBuilder: { [unowned self] in
            self.channelListUpdater = ChannelListUpdaterMock(
                database: $0,
                webSocketClient: $1,
                apiClient: $2
            )
            return self.channelListUpdater!
        })
}

// A concrete `ChannelListControllerDelegate` implementation allowing capturing the delegate calls
private class TestDelegate: QueueAwareDelegate, ChannelListControllerDelegate {
    @Atomic var didChangeChannels_changes: [ListChange<Channel>]?
    
    func controller(
        _ controller: ChannelListControllerGeneric<DefaultDataTypes>,
        didChangeChannels changes: [ListChange<Channel>]
    ) {
        didChangeChannels_changes = changes
        validateQueue()
    }
}

// A concrete `ChannelListControllerDelegateGeneric` implementation allowing capturing the delegate calls.
private class TestDelegateGeneric: QueueAwareDelegate, ChannelListControllerDelegateGeneric {
    @Atomic var didChangeChannels_changes: [ListChange<Channel>]?
    
    func controller(
        _ controller: ChannelListControllerGeneric<DefaultDataTypes>,
        didChangeChannels changes: [ListChange<Channel>]
    ) {
        didChangeChannels_changes = changes
        validateQueue()
    }
}
