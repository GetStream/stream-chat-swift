//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChatChannelWatcherListController_Tests: XCTestCase {
    private var env: TestEnvironment!

    var query: ChannelWatcherListQuery!
    var client: ChatClient!
    var controller: ChatChannelWatcherListController!
    var controllerCallbackQueueID: UUID!
    var callbackQueueID: UUID { controllerCallbackQueueID }

    override func setUp() {
        super.setUp()

        env = TestEnvironment()
        client = ChatClient.mock
        query = .init(cid: .unique)
        controller = .init(query: query, client: client, environment: env.environment)
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }

    override func tearDown() {
        query = nil
        client.mockAPIClient.cleanUp()
        env.watcherListUpdater?.cleanUp()
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
            Assert.canBeReleased(&env)
        }

        controllerCallbackQueueID = nil

        super.tearDown()
    }

    // MARK: - Controller setup

    func test_client_createsWatcherListControllerCorrectly() throws {
        let controller = client.watcherListController(query: query)

        // Assert `state` is correct.
        XCTAssertEqual(controller.state, .initialized)

        // Assert `client` is assigned correctly.
        XCTAssertTrue(controller.client === client)

        // Assert `query` is correct.
        XCTAssertEqual(controller.query.cid, query.cid)
        XCTAssertEqual(controller.query.pagination, query.pagination)
    }

    func test_initialState() throws {
        // Assert `state` is correct.
        XCTAssertEqual(controller.state, .initialized)

        // Assert `client` is assigned correctly.
        XCTAssertTrue(controller.client === client)

        // Assert `query` is correct.
        XCTAssertEqual(controller.query.cid, query.cid)
        XCTAssertEqual(controller.query.pagination, query.pagination)
    }

    // MARK: - Synchronize tests

    func test_synchronize_changesState_and_callsCompletionOnCallbackQueue() {
        // Simulate `synchronize` call.
        var completionIsCalled = false
        controller.synchronize { [callbackQueueID] error in
            // Assert callback queue is correct.
            AssertTestQueue(withId: callbackQueueID)
            // Assert there is no error.
            XCTAssertNil(error)
            completionIsCalled = true
        }

        // Assert controller is in `localDataFetched` state.
        XCTAssertEqual(controller.state, .localDataFetched)

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate successful network call.
        env.watcherListUpdater!.channelWatchers_completion!(nil)
        // Release reference of completion so we can deallocate stuff
        env.watcherListUpdater!.channelWatchers_completion = nil

        // Assert completion is called
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_synchronize_changesState_and_propagatesObserverErrorOnCallbackQueue() {
        // Update observer to throw the error.
        let observerError = TestError()
        env.watcherListObserverSynchronizeError = observerError

        // Simulate `synchronize` call.
        var synchronizeError: Error?
        controller.synchronize { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            synchronizeError = error
        }

        // Assert controller is in `localDataFetchFailed` state.
        XCTAssertEqual(controller.state, .localDataFetchFailed(ClientError(with: observerError)))

        // Assert error from observer is forwarded.
        AssertAsync.willBeEqual(synchronizeError as? ClientError, ClientError(with: observerError))
    }

    func test_synchronize_changesState_and_propagatesListUpdaterErrorOnCallbackQueue() {
        // Simulate `synchronize` call.
        var synchronizeError: Error?
        controller.synchronize { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            synchronizeError = error
        }

        // Simulate failed network call.
        let updaterError = TestError()
        env.watcherListUpdater!.channelWatchers_completion?(updaterError)

        AssertAsync {
            // Assert controller is in `remoteDataFetchFailed` state.
            Assert.willBeEqual(self.controller.state, .remoteDataFetchFailed(ClientError(with: updaterError)))
            // Assert error from updater is forwarded.
            Assert.willBeEqual(synchronizeError as? TestError, updaterError)
        }
    }

    func test_synchronize_doesNotInvokeUpdater_ifObserverFails() {
        // Update observer to throw the error.
        env.watcherListObserverSynchronizeError = TestError()

        // Simulate `synchronize` call.
        controller.synchronize()

        // Assert updater in not called.
        XCTAssertNil(env.watcherListUpdater?.channelWatchers_query)
    }

    func test_synchronize_callsUpdater_ifObserverSucceeds() {
        // Simulate `synchronize` call.
        controller.synchronize()

        // Assert updater in called.
        XCTAssertEqual(env.watcherListUpdater!.channelWatchers_query?.cid, controller.query.cid)
        XCTAssertEqual(env.watcherListUpdater!.channelWatchers_query?.pagination, controller.query.pagination)
        XCTAssertNotNil(env.watcherListUpdater!.channelWatchers_completion)
    }

    /// This test simulates a bug where the `watchers` field was not updated if it wasn't
    /// touched before calling synchronize.
    func test_watchersFetched_evenAfterCallingSynchronize() throws {
        // Simulate `synchronize` call.
        controller.synchronize()

        let watcherId: UserId = .unique

        // Create a channel and a watcher in the database.
        try client.databaseContainer.createChannel(cid: query.cid)
        try client.databaseContainer.writeSynchronously { session in
            let channel = try XCTUnwrap(session.channel(cid: self.query.cid))
            channel.watchers.removeAll() // Make sure we remove all existing data
            channel.watchers.insert(try session.saveUser(payload: .dummy(userId: watcherId)))
        }

        // Simulate the updater callback
        env.watcherListUpdater?.channelWatchers_completion?(nil)
        
        XCTAssertEqual(controller.watchers.map(\.id), [watcherId])
    }

    // MARK: - Local data fetching triggers

    func test_observerIsTriggeredOnlyOnce() {
        // Check initial state
        XCTAssertEqual(controller.state, .initialized)

        // Set the delegate
        controller.delegate = ChannelWatcherListController_Delegate(expectedQueueId: callbackQueueID)

        // Assert state changed
        AssertAsync.willBeEqual(controller.state, .localDataFetched)

        // Update observer to throw the error
        env.watcherListObserver?.synchronizeError = TestError()

        // Set `delegate` / call `synchronize` / access `watchers` again
        _ = controller.watchers

        // Assert controllers stays in `localDataFetched`
        AssertAsync.staysEqual(controller.state, .localDataFetched)
    }

    func test_localDataIsFetched_whenDelegateIsSet() {
        // Check initial state
        XCTAssertEqual(controller.state, .initialized)

        // Set the delegate
        controller.delegate = ChannelWatcherListController_Delegate(expectedQueueId: callbackQueueID)

        // Assert state changed
        AssertAsync.willBeEqual(controller.state, .localDataFetched)
    }

    func test_localDataIsFetched_whenUserIsAccessed() {
        // Check initial state
        XCTAssertEqual(controller.state, .initialized)

        // Access the watchers
        _ = controller.watchers

        // Assert state changed
        AssertAsync.willBeEqual(controller.state, .localDataFetched)
    }

    func test_localDataIsFetched_whenSynchronizedIsCalled() {
        // Check initial state
        XCTAssertEqual(controller.state, .initialized)

        // Set the delegate
        controller.synchronize()

        // Assert state changed
        AssertAsync.willBeEqual(controller.state, .localDataFetched)
    }

    // MARK: - Delegate

    func test_delegate_isAssignedCorrectly() {
        let delegate = ChannelWatcherListController_Delegate(expectedQueueId: callbackQueueID)

        // Set the delegate
        controller.delegate = delegate

        // Assert the delegate is assigned correctly
        XCTAssert(controller.delegate === delegate)
    }

    func test_delegate_isNotifiedAboutStateChanges() throws {
        // Set the delegate
        let delegate = ChannelWatcherListController_Delegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        // Synchronize
        controller.synchronize()

        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)

        // Simulate network call response
        env.watcherListUpdater!.channelWatchers_completion!(nil)

        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .remoteDataFetched)
    }

    func test_delegate_isNotifiedAboutWatcherUpdates() throws {
        let watcher1ID: UserId = .unique
        let watcher2ID: UserId = .unique

        // Set the delegate
        let delegate = ChannelWatcherListController_Delegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        // Create channel in the database.
        try client.databaseContainer.createChannel(cid: query.cid)

        // Create 2 watchers
        var watcher1: UserPayload = .dummy(
            userId: watcher1ID
        )
        var watcher2: UserPayload = .dummy(
            userId: watcher2ID
        )

        // Save both watchers to the database and link to the channel.
        try client.databaseContainer.writeSynchronously { session in
            let channel = session.channel(cid: self.query.cid)
            for watcher in [watcher1, watcher2] {
                channel?.watchers.insert(try session.saveUser(payload: watcher))
            }
        }

        // Assert `insert` changes are received by the delegate.
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateWatchers_changes?.count, 2)
            Assert
                .willBeTrue(
                    (delegate.didUpdateWatchers_changes ?? []).map { $0.fieldChange(\.id) }
                        .contains(where: {
                            if case .insert(watcher1ID, index: _) = $0 {
                                return true
                            } else {
                                return false
                            }
                        })
                )
            Assert
                .willBeTrue(
                    (delegate.didUpdateWatchers_changes ?? []).map { $0.fieldChange(\.id) }
                        .contains(where: {
                            if case .insert(watcher2ID, index: _) = $0 {
                                return true
                            } else {
                                return false
                            }
                        })
                )
        }

        // Simulate `synchronize` call to fetch user from remote
        controller.synchronize()

        // Update 2 watchers
        watcher1 = .dummy(
            userId: watcher1ID
        )
        watcher2 = .dummy(
            userId: watcher2ID
        )

        // Save both watchers to the database and link to the query.
        try client.databaseContainer.writeSynchronously { session in
            let channel = session.channel(cid: self.query.cid)
            for watcher in [watcher1, watcher2] {
                channel?.watchers.insert(try session.saveUser(payload: watcher))
            }
        }
        env.watcherListUpdater!.channelWatchers_completion!(nil)

        // Assert `update` changes are received by the delegate.
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateWatchers_changes?.count, 2)
            Assert
                .willBeTrue(
                    (delegate.didUpdateWatchers_changes ?? []).map { $0.fieldChange(\.id) }
                        .contains(where: {
                            if case .update(watcher1ID, index: _) = $0 {
                                return true
                            } else {
                                return false
                            }
                        })
                )
            Assert
                .willBeTrue(
                    (delegate.didUpdateWatchers_changes ?? []).map { $0.fieldChange(\.id) }
                        .contains(where: {
                            if case .update(watcher2ID, index: _) = $0 {
                                return true
                            } else {
                                return false
                            }
                        })
                )
        }

        // Update second watcher to be created earlier than the first one.
        try client.databaseContainer.writeSynchronously { session in
            session.user(id: watcher2ID)?.userCreatedAt = Date()
        }

        // Assert `update` change is received for the second watcher.
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateWatchers_changes?.count, 1)
            Assert
                .willBeTrue(
                    (delegate.didUpdateWatchers_changes ?? []).map { $0.fieldChange(\.id) }
                        .contains(where: {
                            if case .update(watcher2ID, index: _) = $0 {
                                return true
                            } else {
                                return false
                            }
                        })
                )
        }

        // Simulate database flush
        try client.databaseContainer.removeAllData()

        // Assert `remove` entity changes are received by the delegate.
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateWatchers_changes?.count, 3)
            Assert
                .willBeTrue(
                    (delegate.didUpdateWatchers_changes ?? []).map { $0.fieldChange(\.id) }
                        .contains(where: {
                            if case .remove(watcher1ID, index: _) = $0 {
                                return true
                            } else {
                                return false
                            }
                        })
                )
            Assert
                .willBeTrue(
                    (delegate.didUpdateWatchers_changes ?? []).map { $0.fieldChange(\.id) }
                        .contains(where: {
                            if case .remove(watcher2ID, index: _) = $0 {
                                return true
                            } else {
                                return false
                            }
                        })
                )
            Assert.willBeEqual(Array(self.controller.watchers), [])
        }
    }

    // MARK: - Load next watchers

    func test_loadNextWatchers_propagatesError() {
        // Simulate `loadNextWatchers` call and catch the completion.
        var completionError: Error?
        controller.loadNextWatchers { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate network response with the error.
        let networkError = TestError()
        env.watcherListUpdater!.channelWatchers_completion!(networkError)

        // Assert error is propagated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }

    func test_loadNextWatchers_propagatesNilError() {
        // Simulate `loadNextWatchers` call and catch the completion.
        var completionIsCalled = false
        controller.loadNextWatchers { [callbackQueueID] error in
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
        env.watcherListUpdater!.channelWatchers_completion!(nil)
        // Release reference of completion so we can deallocate stuff
        env.watcherListUpdater!.channelWatchers_completion = nil

        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_loadNextWatchers_callsUserUpdaterWithCorrectValues_and_updatesQuery() {
        let limit = 10
        let oldPagination = controller.query.pagination
        let newPagination: Pagination = .init(pageSize: limit, offset: controller.watchers.count)

        // Simulate `loadNextWatchers` call.
        controller.loadNextWatchers(limit: limit)

        // Assert update is called with updated pagination.
        XCTAssertEqual(env.watcherListUpdater!.channelWatchers_query!.pagination, newPagination)
        // Assert controller still has old pagination.
        XCTAssertEqual(controller.query.pagination, oldPagination)

        // Simulate successful network response.
        env.watcherListUpdater!.channelWatchers_completion!(nil)

        // Assert controller's query is updated with the new pagination.
        AssertAsync.willBeEqual(controller.query.pagination, newPagination)
    }
}

private class TestEnvironment {
    @Atomic var watcherListUpdater: ChannelUpdater_Mock?
    @Atomic var watcherListObserver: ListDatabaseObserver_Mock<ChatUser, UserDTO>?
    @Atomic var watcherListObserverSynchronizeError: Error?

    lazy var environment: ChatChannelWatcherListController.Environment = .init(
        channelUpdaterBuilder: { [unowned self] in
            self.watcherListUpdater = .init(
                database: $0,
                apiClient: $1
            )
            return self.watcherListUpdater!
        },
        watcherListObserverBuilder: { [unowned self] in
            self.watcherListObserver = .init(
                context: $0,
                fetchRequest: $1,
                itemCreator: $2,
                fetchedResultsControllerType: $3
            )
            self.watcherListObserver?.synchronizeError = self.watcherListObserverSynchronizeError
            return self.watcherListObserver!
        }
    )
}
