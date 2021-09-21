//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class ChannelListController_Tests: StressTestCase {
    fileprivate var env: TestEnvironment!
    
    var client: ChatClient!
    
    var query: ChannelListQuery!
    
    var controller: ChatChannelListController!
    var controllerCallbackQueueID: UUID!
    /// Workaround for unwrapping **controllerCallbackQueueID!** in each closure that captures it
    private var callbackQueueID: UUID { controllerCallbackQueueID }
    
    var database: DatabaseContainerMock { client.databaseContainer as! DatabaseContainerMock }
    
    override func setUp() {
        super.setUp()
        
        env = TestEnvironment()
        client = ChatClient.mock(isLocalStorageEnabled: false)
        query = .init(filter: .in(.members, values: [.unique]))
        controller = ChatChannelListController(query: query, client: client, environment: env.environment)
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }
    
    override func tearDown() {
        query = nil
        controllerCallbackQueueID = nil
        
        database.shouldCleanUpTempDBFiles = true
        
        env.channelListUpdater?.cleanUp()
        
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
    
    // MARK: - Synchronize tests
    
    func test_synchronize_changesControllerState() {
        // Check if controller is inactive initially.
        assert(controller.state == .initialized)
        
        // Simulate `synchronize` call
        controller.synchronize()
        
        // Simulate successful network call.
        env.channelListUpdater?.update_completion?(.success(ChannelListPayload(channels: [])))
        
        // Check if state changed after successful network call.
        XCTAssertEqual(controller.state, .remoteDataFetched)
    }
    
    func test_channelsAccess_changesControllerState() {
        // Check if controller is inactive initially.
        assert(controller.state == .initialized)
        
        // Start DB observing
        _ = controller.channels
        
        // Check if state changed after channels access
        XCTAssertEqual(controller.state, .localDataFetched)
    }
    
    func test_synchronize_changesControllerStateOnError() {
        // Check if controller is inactive initially.
        assert(controller.state == .initialized)
        
        // Simulate `synchronize` call
        controller.synchronize()
        
        // Simulate failed network call.
        let error = TestError()
        env.channelListUpdater?.update_completion?(.failure(error))
        
        // Check if state changed after failed network call.
        XCTAssertEqual(controller.state, .remoteDataFetchFailed(ClientError(with: error)))
    }
    
    func test_changesAreReported_beforeCallingSynchronize() throws {
        // Save a new channel to DB
        client.databaseContainer.write { session in
            try session.saveChannel(payload: self.dummyPayload(with: .unique), query: self.query)
        }
        
        // Assert the channel is loaded
        AssertAsync.willBeFalse(controller.channels.isEmpty)
    }
    
    func test_channelsAreFetched_beforeCallingSynchronize() throws {
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
        
        // Assert the existing channel is loaded
        XCTAssertEqual(controller.channels.map(\.cid), [cidMatchingQuery])
    }
    
    func test_synchronize_callsChannelQueryUpdater() {
        let queueId = UUID()
        controller.callbackQueue = .testQueue(withId: queueId)
        
        // Simulate `synchronize` calls and catch the completion
        var completionCalled = false
        controller.synchronize { error in
            XCTAssertNil(error)
            AssertTestQueue(withId: queueId)
            completionCalled = true
        }
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil
        
        // Assert the updater is called with the query
        XCTAssertEqual(env.channelListUpdater!.update_queries.first?.filter.filterHash, query.filter.filterHash)
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        
        // Simulate successful update
        env.channelListUpdater!.update_completion?(.success(ChannelListPayload(channels: [])))
        // Release reference of completion so we can deallocate stuff
        env.channelListUpdater!.update_completion = nil
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_synchronize_callsChannelQueryUpdater_inOfflineMode() {
        let queueId = UUID()
        controller.callbackQueue = .testQueue(withId: queueId)
        
        // Simulate `synchronize` calls and catch the completion
        var completionCalled = false
        controller.synchronize { error in
            XCTAssertNil(error)
            AssertTestQueue(withId: queueId)
            completionCalled = true
        }
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil
        
        // Assert the updater is called with the query
        XCTAssertEqual(env.channelListUpdater?.update_queries.first?.filter.filterHash, query.filter.filterHash)
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        
        // Simulate successful update
        env.channelListUpdater!.update_completion?(.success(ChannelListPayload(channels: [])))
        // Release reference of completion so we can deallocate stuff
        env.channelListUpdater!.update_completion = nil
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_synchronize_propagatesErrorFromUpdater() {
        let queueId = UUID()
        controller.callbackQueue = .testQueue(withId: queueId)
        // Simulate `synchronize` call and catch the completion
        var completionCalledError: Error?
        controller.synchronize {
            completionCalledError = $0
            AssertTestQueue(withId: queueId)
        }
        
        // Simulate failed udpate
        let testError = TestError()
        env.channelListUpdater!.update_completion?(.failure(testError))
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    /// This test simulates a bug where the `channels` field was not updated if it wasn't
    /// touched before calling synchronize.
    func test_channelsAreFetched_afterCallingSynchronize() throws {
        // Simulate `synchronize` call
        controller.synchronize()
        
        // Create a channel in the DB matching the query
        let channelId = ChannelId.unique
        try client.databaseContainer.writeSynchronously {
            try $0.saveChannel(payload: .dummy(cid: channelId), query: self.query)
        }
        
        // Simulate successful network call.
        env.channelListUpdater?.update_completion?(.success(ChannelListPayload(channels: [])))

        // Assert the channels are loaded
        XCTAssertEqual(controller.channels.map(\.cid), [channelId])
    }

    // MARK: - Change propagation tests
    
    func test_changesInTheDatabase_arePropagated() throws {
        // Simulate `synchronize` call
        controller.synchronize()
        
        // Simulate changes in the DB:
        // 1. Add the channel to the DB
        let cid: ChannelId = .unique
        _ = try waitFor {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: cid), query: self.query)
            }, completion: $0)
        }
        
        // Assert the resulting value is updated
        AssertAsync.willBeEqual(controller.channels.map(\.cid), [cid])
    }
    
    func test_newChannel_callsListHook() throws {
        // Create wrapper test delegate
        class TestLinkDelegate: ChatChannelListControllerDelegate {
            let shouldListNewChannel: (ChatChannel) -> Bool
            let shouldListUpdatedChannel: (ChatChannel) -> Bool
            init(
                shouldListNewChannel: @escaping (ChatChannel) -> Bool,
                shouldListUpdatedChannel: @escaping (ChatChannel) -> Bool
            ) {
                self.shouldListNewChannel = shouldListNewChannel
                self.shouldListUpdatedChannel = shouldListUpdatedChannel
            }
            
            func controller(_ controller: ChatChannelListController, shouldAddNewChannelToList channel: ChatChannel) -> Bool {
                shouldListNewChannel(channel)
            }
            
            func controller(_ controller: ChatChannelListController, shouldListUpdatedChannel channel: ChatChannel) -> Bool {
                shouldListUpdatedChannel(channel)
            }
        }
        
        // Simulate `synchronize` call
        controller.synchronize()
        
        // Simulate changes in the DB:
        // Add the channel to the DB
        let cid: ChannelId = .unique
        _ = try waitFor {
            client.databaseContainer.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: cid), query: self.query)
            }, completion: $0)
        }
        
        // Assert the resulting value is updated
        AssertAsync.willBeEqual(controller.channels.map(\.cid), [cid])
        
        let newCid: ChannelId = .unique
        
        // Create and assign delegate
        let delegate = TestLinkDelegate(shouldListNewChannel: { channel in
            channel.cid != newCid
        }, shouldListUpdatedChannel: { _ in
            false
        })
        controller.delegate = delegate
        
        // Insert a new channel to DB
        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: newCid), query: nil)
        }
        
        // Assert the resulting value is not inserted
        AssertAsync.willBeEqual(controller.channels.map(\.cid), [cid])
        
        // Insert a new channel to DB
        let insertedCid = ChannelId.unique
        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: insertedCid), query: nil)
        }
        
        // Assert the resulting value is inserted
        AssertAsync.willBeEqual(controller.channels.map(\.cid.rawValue).sorted(), [cid.rawValue, insertedCid.rawValue].sorted())
    }
    
    func test_updatedChannel_callsLinkHook() throws {
        // Create wrapper test delegate
        class TestLinkDelegate: ChatChannelListControllerDelegate {
            let shouldListNewChannel: (ChatChannel) -> Bool
            let shouldListUpdatedChannel: (ChatChannel) -> Bool
            init(
                shouldListNewChannel: @escaping (ChatChannel) -> Bool,
                shouldListUpdatedChannel: @escaping (ChatChannel) -> Bool
            ) {
                self.shouldListNewChannel = shouldListNewChannel
                self.shouldListUpdatedChannel = shouldListUpdatedChannel
            }
            
            func controller(_ controller: ChatChannelListController, shouldAddNewChannelToList channel: ChatChannel) -> Bool {
                shouldListNewChannel(channel)
            }
            
            func controller(_ controller: ChatChannelListController, shouldListUpdatedChannel channel: ChatChannel) -> Bool {
                shouldListUpdatedChannel(channel)
            }
        }
        
        // Simulate `synchronize` call
        controller.synchronize()
        
        // Add the channel to the DB
        let cid: ChannelId = .unique
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid), query: self.query)
        }
        
        // Assert the resulting value is updated
        AssertAsync.willBeEqual(controller.channels.map(\.cid), [cid])
        
        let shouldBeInsertedCid: ChannelId = .unique
        let shouldBeExcludedCid: ChannelId = .unique
        
        // Create and assign delegate
        let delegate = TestLinkDelegate(shouldListNewChannel: { _ in
            false
        }, shouldListUpdatedChannel: { channel in
            channel.cid == shouldBeInsertedCid
        })
        controller.delegate = delegate
        
        // Insert 2 channels to cid
        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: shouldBeInsertedCid), query: nil)
            try session.saveChannel(payload: .dummy(cid: shouldBeExcludedCid), query: nil)
        }
        
        // Assert that 2 new channels are not linked
        AssertAsync.willBeEqual(controller.channels.map(\.cid), [cid])
        
        // Update `shouldBeExcludedCid`
        try database.writeSynchronously { session in
            let dto = try XCTUnwrap(session.channel(cid: shouldBeExcludedCid))
            dto.updatedAt = .unique
        }
        
        // Assert that updated channel is not linked
        AssertAsync.willBeEqual(controller.channels.map(\.cid), [cid])
        
        // Update `shouldBeInsertedCid`
        try database.writeSynchronously { session in
            let dto = try XCTUnwrap(session.channel(cid: shouldBeInsertedCid))
            dto.updatedAt = .unique
        }

        // Assert that updated channel is linked
        AssertAsync.willBeEqual(
            controller.channels.map(\.cid.rawValue).sorted(),
            [cid.rawValue, shouldBeInsertedCid.rawValue].sorted()
        )
    }
    
    func test_updatedChannel_callsUnlinkHook() throws {
        // Create wrapper test delegate
        class TestLinkDelegate: ChatChannelListControllerDelegate {
            let shouldListUpdatedChannel: (ChatChannel) -> Bool
            init(
                shouldListUpdatedChannel: @escaping (ChatChannel) -> Bool
            ) {
                self.shouldListUpdatedChannel = shouldListUpdatedChannel
            }
            
            func controller(_ controller: ChatChannelListController, shouldListUpdatedChannel channel: ChatChannel) -> Bool {
                shouldListUpdatedChannel(channel)
            }
        }
        
        // Simulate `synchronize` call
        controller.synchronize()
        
        // Add the channel to the DB
        let cid: ChannelId = .unique
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid), query: self.query)
        }
        
        // Assert the resulting value is updated
        AssertAsync.willBeEqual(controller.channels.map(\.cid), [cid])
        
        // Create and assign delegate
        let delegate = TestLinkDelegate(shouldListUpdatedChannel: { channel in
            channel.cid != cid
        })
        controller.delegate = delegate
        
        // Update linked channel
        try database.writeSynchronously { session in
            let channelDTO = session.channel(cid: cid)
            channelDTO?.updatedAt = .unique
        }
        
        // Assert that new channel is unlinked
        AssertAsync.willBeEqual(controller.channels.map(\.cid), [])
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
        env.channelListUpdater?.update_completion?(.success(ChannelListPayload(channels: [])))
        
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
        env.channelListUpdater?.update_completion?(.success(ChannelListPayload(channels: [])))
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .remoteDataFetched)
    }
    
    func test_delegateMethodsAreCalled() throws {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Assert the delegate is assigned correctly. We should test this because of the type-erasing we
        // do in the controller.
        XCTAssert(controller.delegate === delegate)
  
        // Simulate DB update
        let cid: ChannelId = .unique
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid), query: self.query)
        }

        let channel: ChatChannel = client.databaseContainer.viewContext.channel(cid: cid)!.asModel()
        
        AssertAsync {
            Assert.willBeTrue(delegate.willChangeChannels_called)
            Assert.willBeEqual(delegate.didChangeChannels_changes, [.insert(channel, index: [0, 0])])
        }
    }
    
    func test_genericDelegateMethodsAreCalled() throws {
        // Set delegate
        let delegate = TestDelegateGeneric(expectedQueueId: controllerCallbackQueueID)
        controller.setDelegate(delegate)
        
        // Simulate DB update
        let cid: ChannelId = .unique
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid), query: self.query)
        }
        
        let channel: ChatChannel = client.databaseContainer.viewContext.channel(cid: cid)!.asModel()

        AssertAsync {
            Assert.willBeTrue(delegate.willChangeChannels_called)
            Assert.willBeEqual(delegate.didChangeChannels_changes, [.insert(channel, index: [0, 0])])
        }
    }

    func test_willAndDidCallbacks_areCalledInCorrectOrder() throws {
        class Delegate: ChatChannelListControllerDelegate {
            let cid: ChannelId

            var willChangeCallbackCalled = false
            var didChangeCallbackCalled = false

            init(cid: ChannelId) {
                self.cid = cid
            }

            func controllerWillChangeChannels(_ controller: ChatChannelListController) {
                // Check the new channel is NOT in reported channels yet
                XCTAssertFalse(controller.channels.contains { $0.cid == cid })
                // Assert the "did" callback hasn't been called yet
                XCTAssertFalse(didChangeCallbackCalled)
                willChangeCallbackCalled = true
            }

            func controller(
                _ controller: ChatChannelListController,
                didChangeChannels changes: [ListChange<ChatChannel>]
            ) {
                // Check the new channel is in reported channels
                XCTAssertTrue(controller.channels.contains { $0.cid == cid })
                // Assert the "will" callback has been called
                XCTAssertTrue(willChangeCallbackCalled)
                didChangeCallbackCalled = true
            }
        }

        let cid: ChannelId = .unique
        let delegate = Delegate(cid: cid)

        controller.callbackQueue = .main
        controller.delegate = delegate

        client.databaseContainer.write { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid), query: self.query)
        }

        AssertAsync {
            Assert.willBeTrue(delegate.willChangeCallbackCalled)
            Assert.willBeTrue(delegate.didChangeCallbackCalled)
        }
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
        
        // Assert correct `Pagination` is created
        XCTAssertEqual(
            env!.channelListUpdater?.update_queries.first?.pagination,
            .init(pageSize: limit, offset: controller.channels.count)
        )
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil
        
        // Simulate successful update
        env!.channelListUpdater?.update_completion?(.success(ChannelListPayload(channels: [])))
        // Release reference of completion so we can deallocate stuff
        env.channelListUpdater!.update_completion = nil
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
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
        env.channelListUpdater!.update_completion?(.failure(testError))
        
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
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil
        
        XCTAssertFalse(completionCalled)
        
        // Simulate successfull udpate
        env.channelListUpdater!.markAllRead_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.channelListUpdater!.markAllRead_completion = nil
        
        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_markAllRead_propagatesErrorFromUpdater() {
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
    
    // MARK: - List Ordering initial value
    
    func test_inits_propagate_desiredMessageOrdering() {
        XCTAssertEqual(
            client.channelController(for: .unique).messageOrdering,
            .topToBottom
        )
        XCTAssertEqual(
            client.channelController(for: .unique, messageOrdering: .bottomToTop).messageOrdering,
            .bottomToTop
        )
        
        XCTAssertEqual(
            client.channelController(for: ChannelQuery(cid: .unique)).messageOrdering,
            .topToBottom
        )
        XCTAssertEqual(
            client.channelController(
                for: ChannelQuery(cid: .unique),
                messageOrdering: .bottomToTop
            ).messageOrdering,
            .bottomToTop
        )
        
        client.currentUserId = .unique
        XCTAssertEqual(
            (try! client.channelController(createChannelWithId: .unique)).messageOrdering,
            .topToBottom
        )
        XCTAssertEqual(
            (
                try! client.channelController(
                    createChannelWithId: .unique,
                    messageOrdering: .bottomToTop
                )
            ).messageOrdering,
            .bottomToTop
        )
        
        XCTAssertEqual(
            (
                try! client.channelController(
                    createDirectMessageChannelWith: [.unique],
                    extraData: [:]
                )
            ).messageOrdering,
            .topToBottom
        )
        XCTAssertEqual(
            (
                try! client.channelController(
                    createDirectMessageChannelWith: [.unique],
                    messageOrdering: .bottomToTop,
                    extraData: [:]
                )
            ).messageOrdering,
            .bottomToTop
        )
    }
}

private class TestEnvironment {
    @Atomic var channelListUpdater: ChannelListUpdaterMock?
    
    lazy var environment: ChatChannelListController.Environment =
        .init(channelQueryUpdaterBuilder: { [unowned self] in
            self.channelListUpdater = ChannelListUpdaterMock(
                database: $0,
                apiClient: $1
            )
            return self.channelListUpdater!
        })
}

// A concrete `ChannelListControllerDelegate` implementation allowing capturing the delegate calls
private class TestDelegate: QueueAwareDelegate, ChatChannelListControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var willChangeChannels_called = false
    @Atomic var didChangeChannels_changes: [ListChange<ChatChannel>]?

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }

    func controllerWillChangeChannels(_ controller: ChatChannelListController) {
        willChangeChannels_called = true
        validateQueue()
    }

    func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    ) {
        didChangeChannels_changes = changes
        validateQueue()
    }
}

// A concrete `_ChatChannelListControllerDelegate` implementation allowing capturing the delegate calls.
private class TestDelegateGeneric: QueueAwareDelegate, ChatChannelListControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var willChangeChannels_called = false
    @Atomic var didChangeChannels_changes: [ListChange<ChatChannel>]?

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }

    func controllerWillChangeChannels(_ controller: ChatChannelListController) {
        willChangeChannels_called = true
        validateQueue()
    }

    func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    ) {
        didChangeChannels_changes = changes
        validateQueue()
    }
}
