//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelListController_Tests: XCTestCase {
    private lazy var env: TestEnvironment! = TestEnvironment()
    private lazy var memberId: UserId = .unique
    private lazy var query: ChannelListQuery! = .init(filter: .in(.members, values: [memberId]))
    private lazy var client: ChatClient! = ChatClient.mock()
    private lazy var controllerCallbackQueueID: UUID! = .init()
    private lazy var controller: ChatChannelListController! = {
        let controller = ChatChannelListController(query: query, client: client, environment: env.environment)
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
        return controller
    }()

    /// Workaround for unwrapping **controllerCallbackQueueID!** in each closure that captures it
    private var callbackQueueID: UUID { controllerCallbackQueueID }

    var database: DatabaseContainer_Spy { client.databaseContainer as! DatabaseContainer_Spy }

    override func tearDown() {
        query = nil
        controllerCallbackQueueID = nil

        database.shouldCleanUpTempDBFiles = true

        controller = nil
        client.mockAPIClient.cleanUp()
        client = nil
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
        env.channelListUpdater?.update_completion?(.success([]))

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
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: .unique, members: [.dummy(user: .dummy(userId: self.memberId))]), query: self.query, cache: nil)
        }

        // Assert the channel is loaded
        AssertAsync.willBeFalse(controller.channels.isEmpty)
    }

    func test_channelsAreFetched_beforeCallingSynchronize() throws {
        // Save three channels to DB
        let cidMatchingQuery = ChannelId.unique
        let cidMatchingQueryDeleted = ChannelId.unique
        let cidNotMatchingQuery = ChannelId.unique

        waitForInitialChannelsUpdate()
        writeAndWaitForChannelsUpdates { session in
            // Insert a channel matching the query
            try session.saveChannel(payload: self.dummyPayload(with: cidMatchingQuery, members: [.dummy(user: .dummy(userId: self.memberId))]), query: self.query, cache: nil)

            // Insert a deleted channel matching the query
            let dto = try session.saveChannel(
                payload: self.dummyPayload(with: cidMatchingQueryDeleted, members: [.dummy(user: .dummy(userId: self.memberId))]),
                query: self.query,
                cache: nil
            )
            dto.deletedAt = .unique

            // Insert a channel not matching the query
            try session.saveChannel(payload: self.dummyPayload(with: cidNotMatchingQuery), query: nil, cache: nil)
        }

        // Assert the existing channel is loaded
        XCTAssertEqual(controller.channels.map(\.cid), [cidMatchingQuery])
    }

    func test_synchronize_callsChannelQueryUpdater() {
        let queueId = UUID()
        controller.callbackQueue = .testQueue(withId: queueId)

        // Simulate `synchronize` calls and catch the completion
        let exp = expectation(description: "sync call should complete")
        controller.synchronize { error in
            XCTAssertNil(error)
            AssertTestQueue(withId: queueId)
            exp.fulfill()
        }

        // Simulate successful update
        env.channelListUpdater?.update_completion?(.success([]))

        waitForExpectations(timeout: defaultTimeout)

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Assert the updater is called with the query
        XCTAssertEqual(env.channelListUpdater!.update_queries.first?.filter.filterHash, query.filter.filterHash)

        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_synchronize_initialPageSize_isCorrect() {
        let pageSize = Int.random(in: 1...42)
        query = .init(filter: .in(.members, values: [.unique]), pageSize: pageSize)
        controller = ChatChannelListController(query: query, client: client, environment: env.environment)
        let queueId = UUID()
        controller.callbackQueue = .testQueue(withId: queueId)

        // Simulate `synchronize` calls and catch the completion
        let exp = expectation(description: "sync call should complete")
        controller.synchronize { error in
            XCTAssertNil(error)
            AssertTestQueue(withId: queueId)
            exp.fulfill()
        }

        // Simulate successful update
        env.channelListUpdater?.update_completion?(.success([]))

        waitForExpectations(timeout: defaultTimeout)

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_synchronize_callsChannelQueryUpdater_inOfflineMode() {
        let queueId = UUID()
        controller.callbackQueue = .testQueue(withId: queueId)

        // Simulate `synchronize` calls and catch the completion
        let exp = expectation(description: "sync call should complete")
        controller.synchronize { error in
            XCTAssertNil(error)
            AssertTestQueue(withId: queueId)
            exp.fulfill()
        }

        // Simulate successful update
        env.channelListUpdater?.update_completion?(.success([]))

        waitForExpectations(timeout: defaultTimeout)

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Assert the updater is called with the query
        XCTAssertEqual(env.channelListUpdater?.update_queries.first?.filter.filterHash, query.filter.filterHash)

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
        env.channelListUpdater?.update_completion?(.failure(testError))

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    /// This test simulates a bug where the `channels` field was not updated if it wasn't
    /// touched before calling synchronize.
    func test_channelsAreFetched_afterCallingSynchronize() throws {
        // Simulate `synchronize` call
        controller.synchronize()

        waitForInitialChannelsUpdate()

        // Create a channel in the DB matching the query
        let channelId = ChannelId.unique
        writeAndWaitForChannelsUpdates {
            try $0.saveChannel(payload: .dummy(cid: channelId, members: [.dummy(user: .dummy(userId: self.memberId))]), query: self.query, cache: nil)
        }

        // Simulate successful network call.
        env.channelListUpdater?.update_completion?(.success([]))

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
                try session.saveChannel(payload: self.dummyPayload(with: cid, members: [.dummy(user: .dummy(userId: self.memberId))]), query: self.query, cache: nil)
            }, completion: $0)
        }

        // Assert the resulting value is updated
        AssertAsync.willBeEqual(controller.channels.map(\.cid), [cid])
    }

    func test_hiddenChannel_isExcluded_whenFilterDoesntContainHiddenKey() throws {
        waitForInitialChannelsUpdate()

        // Add 2 channels to the DB
        let cid: ChannelId = .unique
        writeAndWaitForChannelsUpdates { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid, members: [.dummy(user: .dummy(userId: self.memberId))]), query: self.query, cache: nil)
            let dto = try session.saveChannel(payload: self.dummyPayload(with: .unique, members: [.dummy(user: .dummy(userId: self.memberId))]), query: self.query, cache: nil)
            dto.isHidden = true
        }

        // Simulate `synchronize` call
        controller.synchronize()

        // Assert only non-hidden one is tracked
        XCTAssertEqual(controller.channels.map(\.cid), [cid])
        // Assert tracked channels are not hidden
        XCTAssertEqual(controller.channels.first?.isHidden, false)
    }

    func test_hiddenChannel_isIncluded_whenFilterContainsHiddenKey() throws {
        // Create controller with hidden filter
        query = .init(filter: .equal(.hidden, to: true))
        controller = .init(query: query, client: client)

        waitForInitialChannelsUpdate()

        // Add 2 channels to the DB
        let cid: ChannelId = .unique
        writeAndWaitForChannelsUpdates { session in
            try session.saveChannel(payload: self.dummyPayload(with: .unique), query: self.query, cache: nil)
            let dto = try session.saveChannel(payload: self.dummyPayload(with: cid), query: self.query, cache: nil)
            dto.isHidden = true
        }

        // Simulate `synchronize` call
        controller.synchronize()

        // Assert only hidden channel is tracked
        XCTAssertEqual(controller.channels.map(\.cid), [cid])
        // Assert tracked channels are hidden
        XCTAssertEqual(controller.channels.first?.isHidden, true)
    }

    // MARK: - Linking and Unlinking Channels when channels are updated/inserted

    func test_didReceiveEvent_whenNotificationAddedToChannelEvent_shouldLinkChannelToQuery() {
        let event = makeAddedChannelEvent(with: .mock(cid: .unique))

        controller.eventsController(controller.eventsController, didReceiveEvent: event)

        env.channelListUpdater?.link_completion?(nil)

        XCTAssertEqual(env.channelListUpdater?.link_callCount, 1)
        XCTAssertEqual(env.channelListUpdater?.startWatchingChannels_callCount, 1)
    }

    func test_didReceiveEvent_whenMessageNewEvent_shouldLinkChannelToQuery() {
        let event = makeMessageNewEvent(with: .mock(cid: .unique))

        controller.eventsController(controller.eventsController, didReceiveEvent: event)

        env.channelListUpdater?.link_completion?(nil)

        XCTAssertEqual(env.channelListUpdater?.link_callCount, 1)
        XCTAssertEqual(env.channelListUpdater?.startWatchingChannels_callCount, 1)
    }
    
    func test_didReceiveEvent_whenChannelVisibleEvent_shouldLinkChannelToQuery() {
        let channel = ChatChannel.mock(cid: .unique)
        try? database.createChannel(cid: channel.cid, channelReads: [])
        let event = makeChannelVisibleEvent(with: channel)

        controller.eventsController(controller.eventsController, didReceiveEvent: event)

        env.channelListUpdater?.link_completion?(nil)

        XCTAssertEqual(env.channelListUpdater?.link_callCount, 1)
        XCTAssertEqual(env.channelListUpdater?.startWatchingChannels_callCount, 1)
    }

    func test_didReceiveEvent_whenNotificationMessageNewEvent_shouldLinkChannelToQuery() {
        let event = makeNotificationMessageNewEvent(with: .mock(cid: .unique))

        controller.eventsController(controller.eventsController, didReceiveEvent: event)

        env.channelListUpdater?.link_completion?(nil)

        XCTAssertEqual(env.channelListUpdater?.link_callCount, 1)
        XCTAssertEqual(env.channelListUpdater?.startWatchingChannels_callCount, 1)
    }

    func test_didReceiveEvent_whenNotificationAddedToChannelEvent_whenChannelAlreadyPresent_shouldNotLinkChannelToQuery() throws {
        controller.synchronize()
        waitForInitialChannelsUpdate()

        // Save channel to the current query
        let cid: ChannelId = .unique
        writeAndWaitForChannelsUpdates { session in
            try session.saveChannel(
                payload: self.dummyPayload(
                    with: cid,
                    members: [.dummy(user: .dummy(userId: self.memberId))]
                ),
                query: self.query,
                cache: nil
            )
        }

        let event = makeAddedChannelEvent(with: .mock(cid: cid))

        controller.eventsController(controller.eventsController, didReceiveEvent: event)

        env.channelListUpdater?.link_completion?(nil)

        XCTAssertEqual(env.channelListUpdater?.link_callCount, 0)
        XCTAssertEqual(env.channelListUpdater?.startWatchingChannels_callCount, 0)
    }

    func test_didReceiveEvent_whenMessageNewEvent_whenChannelAlreadyPresent_shouldNotLinkChannelToQuery() throws {
        controller.synchronize()
        waitForInitialChannelsUpdate()

        // Save channel to the current query
        let cid: ChannelId = .unique
        writeAndWaitForChannelsUpdates { session in
            try session.saveChannel(
                payload: self.dummyPayload(
                    with: cid,
                    members: [.dummy(user: .dummy(userId: self.memberId))]
                ),
                query: self.query,
                cache: nil
            )
        }

        let event = makeMessageNewEvent(with: .mock(cid: cid))

        controller.eventsController(controller.eventsController, didReceiveEvent: event)

        env.channelListUpdater?.link_completion?(nil)

        XCTAssertEqual(env.channelListUpdater?.link_callCount, 0)
        XCTAssertEqual(env.channelListUpdater?.startWatchingChannels_callCount, 0)
    }

    func test_didReceiveEvent_whenNotificationMessageNewEvent_whenChannelAlreadyPresent_shouldNotLinkChannelToQuery() throws {
        controller.synchronize()
        waitForInitialChannelsUpdate()

        // Save channel to the current query
        let cid: ChannelId = .unique
        writeAndWaitForChannelsUpdates { session in
            try session.saveChannel(
                payload: self.dummyPayload(
                    with: cid,
                    members: [.dummy(user: .dummy(userId: self.memberId))]
                ),
                query: self.query,
                cache: nil
            )
        }

        let event = makeNotificationMessageNewEvent(with: .mock(cid: cid))

        controller.eventsController(controller.eventsController, didReceiveEvent: event)

        env.channelListUpdater?.link_completion?(nil)

        XCTAssertEqual(env.channelListUpdater?.link_callCount, 0)
        XCTAssertEqual(env.channelListUpdater?.startWatchingChannels_callCount, 0)
    }

    func test_didReceiveEvent_whenFilterMatches_shouldLinkChannelToQuery() {
        let filter: (ChatChannel) -> Bool = { channel in
            channel.memberCount == 4
        }
        setupControllerWithFilter(filter)

        let event = makeAddedChannelEvent(with: .mock(cid: .unique, memberCount: 4))

        controller.eventsController(controller.eventsController, didReceiveEvent: event)

        env.channelListUpdater?.link_completion?(nil)

        XCTAssertEqual(env.channelListUpdater?.link_callCount, 1)
        XCTAssertEqual(env.channelListUpdater?.startWatchingChannels_callCount, 1)
    }

    func test_didReceiveEvent_whenFilterMatches_whenChannelAlreadyPresent_shouldNotLinkChannelToQuery() throws {
        let filter: (ChatChannel) -> Bool = { channel in
            channel.memberCount == 4
        }
        setupControllerWithFilter(filter)

        // Save channel to the current query
        let cid: ChannelId = .unique
        writeAndWaitForChannelsUpdates { session in
            try session.saveChannel(
                payload: self.dummyPayload(
                    with: cid,
                    members: [.dummy(user: .dummy(userId: self.memberId))]
                ),
                query: self.query,
                cache: nil
            )
        }

        let event = makeAddedChannelEvent(with: .mock(cid: cid, memberCount: 4))

        controller.eventsController(controller.eventsController, didReceiveEvent: event)

        env.channelListUpdater?.link_completion?(nil)

        XCTAssertEqual(env.channelListUpdater?.link_callCount, 0)
        XCTAssertEqual(env.channelListUpdater?.startWatchingChannels_callCount, 0)
    }

    func test_didReceiveEvent_whenFilterDoesNotMatch_shouldNotLinkChannelToQuery() {
        let filter: (ChatChannel) -> Bool = { channel in
            channel.memberCount == 1
        }
        setupControllerWithFilter(filter)

        let event = makeAddedChannelEvent(with: .mock(cid: .unique, memberCount: 4))

        controller.eventsController(controller.eventsController, didReceiveEvent: event)

        env.channelListUpdater?.link_completion?(nil)

        XCTAssertEqual(env.channelListUpdater?.link_callCount, 0)
        XCTAssertEqual(env.channelListUpdater?.startWatchingChannels_callCount, 0)
    }

    func test_didReceiveEvent_whenChannelUpdatedEvent_whenFilterDoesNotMatch_shouldUnlinkChannelFromQuery() throws {
        let filter: (ChatChannel) -> Bool = { channel in
            channel.memberCount == 1
        }
        setupControllerWithFilter(filter)

        // Save channel to the current query
        let cid: ChannelId = .unique
        writeAndWaitForChannelsUpdates { session in
            try session.saveChannel(
                payload: self.dummyPayload(
                    with: cid,
                    members: [.dummy(user: .dummy(userId: self.memberId))]
                ),
                query: self.query,
                cache: nil
            )
        }

        let event = makeChannelUpdatedEvent(with: .mock(cid: cid, memberCount: 4))

        controller.eventsController(controller.eventsController, didReceiveEvent: event)

        XCTAssertEqual(env.channelListUpdater?.unlink_callCount, 1)
    }

    func test_didReceiveEvent_whenChannelUpdatedEvent__whenFilterMatches_shouldNotUnlinkChannelFromQuery() throws {
        let filter: (ChatChannel) -> Bool = { channel in
            channel.memberCount == 4
        }
        setupControllerWithFilter(filter)

        let cid: ChannelId = .unique
        writeAndWaitForChannelsUpdates { session in
            try session.saveChannel(
                payload: self.dummyPayload(
                    with: cid,
                    members: [.dummy(user: .dummy(userId: self.memberId))]
                ),
                query: self.query,
                cache: nil
            )
        }

        let event = makeChannelUpdatedEvent(with: .mock(cid: cid, memberCount: 4))

        controller.eventsController(controller.eventsController, didReceiveEvent: event)

        XCTAssertEqual(env.channelListUpdater?.unlink_callCount, 0)
    }

    func test_didReceiveEvent_whenChannelUpdatedEvent__whenFilterDoesNotMatch_whenChannelNotPresent_shouldNotUnlinkChannelFromQuery() throws {
        let filter: (ChatChannel) -> Bool = { channel in
            channel.memberCount == 1
        }
        setupControllerWithFilter(filter)

        let event = makeChannelUpdatedEvent(with: .mock(cid: .unique, memberCount: 4))

        controller.eventsController(controller.eventsController, didReceiveEvent: event)

        XCTAssertEqual(env.channelListUpdater?.unlink_callCount, 0)
    }

    // MARK: - Change propagation tests with auto-filtering

    func test_linkChannel_whenAutoFilteringEnabled_doesNotTriggerLinkChannelOnDelegate() throws {
        let shouldListNewChannelWasNotCalledExpectation = expectation(description: "shouldListNewChannel won't be called")
        let shouldListUpdatedChannelWasNotCalledExpectation = expectation(description: "shouldListUpdatedChannel won't be called")
        [shouldListNewChannelWasNotCalledExpectation, shouldListUpdatedChannelWasNotCalledExpectation].forEach { $0.isInverted = true }

        let testLinkDelegate = TestLinkDelegate(
            shouldListNewChannel: { _ in
                shouldListNewChannelWasNotCalledExpectation.fulfill()
                return false
            },
            shouldListUpdatedChannel: { _ in
                shouldListUpdatedChannelWasNotCalledExpectation.fulfill()
                return false
            }
        )
        controller.delegate = testLinkDelegate

        // Save a channel linked to the current query
        let cid: ChannelId = .unique
        try database.writeSynchronously { session in
            try session.saveChannel(
                payload: self.dummyPayload(
                    with: cid,
                    members: [.dummy(user: .dummy(userId: self.memberId))]
                ),
                query: self.query,
                cache: nil
            )
        }

        // Assert channel is linked
        AssertAsync.willBeEqual(controller.channels.map(\.cid), [cid])

        // Update a channel linked to the current query
        try database.writeSynchronously { session in
            let dto = try XCTUnwrap(session.channel(cid: cid))
            dto.updatedAt = .unique
        }

        // Assert linked channel is unlisted
        AssertAsync.willBeEqual(controller.channels.map(\.cid), [cid])
        waitForExpectations(timeout: defaultTimeoutForInversedExpecations)
    }

    func test_unlinkChannel_whenAutoFilteringEnabled_doesNotTriggerUnLinkChannelOnDelegate() throws {
        let shouldListNewChannelWasNotCalledExpectation = expectation(description: "shouldListNewChannel won't be called")
        let shouldListUpdatedChannelWasNotCalledExpectation = expectation(description: "shouldListUpdatedChannel won't be called")
        [shouldListNewChannelWasNotCalledExpectation, shouldListUpdatedChannelWasNotCalledExpectation].forEach { $0.isInverted = true }

        let testLinkDelegate = TestLinkDelegate(
            shouldListNewChannel: { _ in
                shouldListNewChannelWasNotCalledExpectation.fulfill()
                return false
            },
            shouldListUpdatedChannel: { _ in
                shouldListUpdatedChannelWasNotCalledExpectation.fulfill()
                return false
            }
        )
        controller.delegate = testLinkDelegate

        // Save a channel linked to the current query
        let cid: ChannelId = .unique
        try database.writeSynchronously { session in
            try session.saveChannel(
                payload: self.dummyPayload(
                    with: cid,
                    members: [.dummy(user: .dummy(userId: self.memberId))]
                ),
                query: self.query,
                cache: nil
            )
        }

        // Assert channel is linked
        AssertAsync.willBeEqual(controller.channels.map(\.cid), [cid])

        // Update a channel linked to the current query
        try database.writeSynchronously { session in
            let dto = try XCTUnwrap(session.channel(cid: cid))
            dto.members = .init()
        }

        // Assert linked channel is unlisted
        AssertAsync.willBeEqual(controller.channels.map(\.cid), [])
        waitForExpectations(timeout: defaultTimeoutForInversedExpecations)
    }

    // MARK: - Delegate tests

    func test_settingDelegate_leadsToFetchingLocalData() {
        let delegate = ChannelListController_Delegate(expectedQueueId: controllerCallbackQueueID)

        // Check initial state
        XCTAssertEqual(controller.state, .initialized)

        controller.delegate = delegate

        // Assert state changed
        AssertAsync.willBeEqual(controller.state, .localDataFetched)
    }

    func test_delegate_isNotifiedAboutStateChanges() throws {
        // Set the delegate
        let delegate = ChannelListController_Delegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate

        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)

        // Synchronize
        controller.synchronize()

        // Simulate network call response
        env.channelListUpdater?.update_completion?(.success([]))

        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .remoteDataFetched)
    }

    func test_delegateMethodsAreCalled() throws {
        // Set the delegate
        let delegate = ChannelListController_Delegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate

        // Assert the delegate is assigned correctly. We should test this because of the type-erasing we
        // do in the controller.
        XCTAssert(controller.delegate === delegate)

        // Simulate DB update
        let cid: ChannelId = .unique
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid, members: [.dummy(user: .dummy(userId: self.memberId))]), query: self.query, cache: nil)
        }

        let channel = try XCTUnwrap(client.databaseContainer.viewContext.channel(cid: cid)).asModel()

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

            func controller(_ controller: ChatChannelListController, shouldListUpdatedChannel channel: ChatChannel) -> Bool {
                true
            }

            func controller(_ controller: ChatChannelListController, shouldAddNewChannelToList channel: ChatChannel) -> Bool {
                true
            }
        }

        waitForInitialChannelsUpdate()

        let cid: ChannelId = .unique
        let delegate = Delegate(cid: cid)

        controller.callbackQueue = .main
        controller.delegate = delegate

        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid, members: [.dummy(user: .dummy(userId: self.memberId))]), query: self.query, cache: nil)
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
        env!.channelListUpdater?.update_completion?(.success([]))
        // Release reference of completion so we can deallocate stuff
        env.channelListUpdater?.update_completion = nil

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

        // Simulate failed update
        let testError = TestError()
        env.channelListUpdater?.update_completion?(.failure(testError))

        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    func test_loadNextChannels_defaultPageSize_isCorrect() {
        var completionCalled = false

        let pageSize = Int.random(in: 1...42)
        query = .init(filter: .in(.members, values: [.unique]), pageSize: pageSize)
        controller = ChatChannelListController(query: query, client: client, environment: env.environment)

        controller.loadNextChannels { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)

        // Assert correct `Pagination` is created
        XCTAssertEqual(
            env!.channelListUpdater?.update_queries.first?.pagination,
            .init(pageSize: pageSize, offset: controller.channels.count)
        )

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate successful update
        env!.channelListUpdater?.update_completion?(.success([]))
        // Release reference of completion so we can deallocate stuff
        env.channelListUpdater!.update_completion = nil

        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    // MARK: - Reset query

    func test_resetQuery_whenSucceeds_updates_hasLoadedAllPreviousChannels_whenRecevingAFullPage() {
        XCTAssertFalse(controller.hasLoadedAllPreviousChannels)

        // Simulate synchronize to create all dependencies
        controller.synchronize()

        // Simulate a regular/full page
        let channels: [ChatChannel] = (0..<controller.query.pagination.pageSize).map { _ in
            ChatChannel.mock(cid: .unique)
        }
        env.channelListUpdater?.resetChannelsQueryResult = .success((synchedAndWatched: channels, unwanted: Set()))

        let expectation = self.expectation(description: "Reset Query completes")
        var receivedError: Error?
        controller.resetQuery(
            watchedAndSynchedChannelIds: Set(),
            synchedChannelIds: Set()
        ) { result in
            receivedError = result.error
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout)

        XCTAssertNil(receivedError)
        // When receiving a full page, we did not reach the end of the pagination
        XCTAssertFalse(controller.hasLoadedAllPreviousChannels)
    }

    func test_resetQuery_whenSucceeds_updates_hasLoadedAllPreviousChannels_whenRecevingALastPage() {
        XCTAssertFalse(controller.hasLoadedAllPreviousChannels)

        // Simulate synchronize to create all dependencies
        controller.synchronize()

        // Simulate the last page
        let channels = [ChatChannel.mock(cid: .unique)]
        env.channelListUpdater?.resetChannelsQueryResult = .success((synchedAndWatched: channels, unwanted: Set()))

        let expectation = self.expectation(description: "Reset Query completes")
        var receivedError: Error?
        controller.resetQuery(
            watchedAndSynchedChannelIds: Set(),
            synchedChannelIds: Set()
        ) { result in
            receivedError = result.error
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout)

        XCTAssertNil(receivedError)
        // When receiving an incomplete page, we did reach the end of the pagination
        XCTAssertTrue(controller.hasLoadedAllPreviousChannels)
    }

    func test_resetQuery_propagatesErrorFromUpdater() {
        XCTAssertFalse(controller.hasLoadedAllPreviousChannels)

        // Simulate synchronize to create all dependencies
        controller.synchronize()

        // Simulate a failure
        let error = ClientError("Something went wrong")
        env.channelListUpdater?.resetChannelsQueryResult = .failure(error)

        let expectation = self.expectation(description: "Reset Query completes")
        var receivedError: Error?
        controller.resetQuery(
            watchedAndSynchedChannelIds: Set(),
            synchedChannelIds: Set()
        ) { result in
            receivedError = result.error
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(receivedError, error)
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

        client.authenticationRepository.setMockToken()
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

    // MARK: Init registers active controller

    func test_initRegistersActiveController() {
        let client = ChatClient.mock
        let query = ChannelListQuery(filter: .in(.members, values: [.unique]))
        let controller = ChatChannelListController(query: query, client: client, environment: env.environment)

        XCTAssert(controller.client === client)
        XCTAssert(client.activeChannelListControllers.count == 1)
        XCTAssert(client.activeChannelListControllers.allObjects.first === controller)
    }

    // MARK: Predicates

    private func assertFilterPredicate(
        _ filter: @autoclosure () -> Filter<ChannelListFilterScope>,
        channelsInDB: @escaping @autoclosure () -> [ChannelPayload],
        expectedResult: @autoclosure () -> [ChannelId],
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        /// Ensure that isChannelAutomaticFilteringEnabled is enabled
        var config = ChatClientConfig(apiKeyString: .unique)
        config.isChannelAutomaticFilteringEnabled = true
        client = ChatClient.mock(config: config)

        let query = ChannelListQuery(
            filter: filter()
        )
        controller = ChatChannelListController(
            query: query,
            client: client,
            environment: env.environment
        )
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)

        // Simulate `synchronize` call
        controller.synchronize()
        waitForInitialChannelsUpdate()

        XCTAssertEqual(controller.channels.map(\.cid), [], file: file, line: line)

        // Simulate changes in the DB:
        _ = try waitFor {
            writeAndWaitForChannelsUpdates({ [query] session in
                try channelsInDB().forEach { payload in
                    try session.saveChannel(payload: payload, query: query, cache: nil)
                }
            }, completion: $0)
        }

        // Assert the resulting value is updated
        XCTAssertEqual(
            controller.channels.map(\.cid.rawValue).sorted(),
            expectedResult().map(\.rawValue).sorted(),
            file: file,
            line: line
        )
    }

    func test_filterPredicate_equal_containsExpectedItems() throws {
        let cid = ChannelId.unique

        try assertFilterPredicate(
            .equal(.name, to: "test"),
            channelsInDB: [
                .dummy(channel: .dummy(cid: cid, name: "test")),
                .dummy(channel: .dummy(name: "test2")),
                .dummy(channel: .dummy(name: "test3")),
                .dummy(channel: .dummy(name: "4test"))
            ],
            expectedResult: [cid]
        )
    }

    func test_filterPredicate_notEqual_containsExpectedItems() throws {
        let cid = ChannelId.unique

        try assertFilterPredicate(
            .notEqual(.name, to: "test"),
            channelsInDB: [
                .dummy(channel: .dummy(name: "test")),
                .dummy(channel: .dummy(cid: cid, name: "test2"))
            ],
            expectedResult: [cid]
        )
    }

    func test_filterPredicate_greater_containsExpectedItems() throws {
        let cid = ChannelId.unique

        try assertFilterPredicate(
            .greater(.memberCount, than: 1),
            channelsInDB: [
                .dummy(channel: .dummy(cid: cid, members: [.dummy(), .dummy()])),
                .dummy(channel: .dummy(members: [.dummy()])),
                .dummy(channel: .dummy(members: []))
            ],
            expectedResult: [cid]
        )
    }

    func test_filterPredicate_greaterOrEqual_containsExpectedItems() throws {
        let cid1 = ChannelId.unique
        let cid2 = ChannelId.unique

        try assertFilterPredicate(
            .greaterOrEqual(.memberCount, than: 1),
            channelsInDB: [
                .dummy(channel: .dummy(cid: cid1, members: [.dummy(), .dummy()])),
                .dummy(channel: .dummy(cid: cid2, members: [.dummy()])),
                .dummy(channel: .dummy(members: []))
            ],
            expectedResult: [cid1, cid2]
        )
    }

    func test_filterPredicate_less_containsExpectedItems() throws {
        let cid = ChannelId.unique

        try assertFilterPredicate(
            .less(.memberCount, than: 1),
            channelsInDB: [
                .dummy(channel: .dummy(members: [.dummy(), .dummy()])),
                .dummy(channel: .dummy(members: [.dummy()])),
                .dummy(channel: .dummy(cid: cid, members: []))
            ],
            expectedResult: [cid]
        )
    }

    func test_filterPredicate_lessOrEqual_containsExpectedItems() throws {
        let cid1 = ChannelId.unique
        let cid2 = ChannelId.unique

        try assertFilterPredicate(
            .lessOrEqual(.memberCount, than: 1),
            channelsInDB: [
                .dummy(channel: .dummy(members: [.dummy(), .dummy()])),
                .dummy(channel: .dummy(cid: cid1, members: [.dummy()])),
                .dummy(channel: .dummy(cid: cid2, members: []))
            ],
            expectedResult: [cid1, cid2]
        )
    }

    func test_filterPredicate_in_containsExpectedItems() throws {
        let cid1 = ChannelId.unique
        let cid2 = ChannelId.unique
        let cid3 = ChannelId.unique

        let expectedCids = [
            cid1,
            cid2,
            cid3
        ]
        let expectedChannels: [ChannelPayload] = expectedCids.map { .dummy(channel: .dummy(cid: $0)) }
        let unexpectedChannels: [ChannelPayload] = [
            .dummy(channel: .dummy(cid: .unique)),
            .dummy(channel: .dummy(cid: .unique))
        ]

        // When all the channel ids are in DB.
        try assertFilterPredicate(
            .in(.id, values: expectedCids.map(\.rawValue)),
            channelsInDB: expectedChannels + unexpectedChannels,
            expectedResult: expectedCids
        )

        // When not all the channel ids are in DB.
        try assertFilterPredicate(
            .in(.id, values: expectedCids.map(\.rawValue)),
            channelsInDB: expectedChannels.dropLast() + unexpectedChannels,
            expectedResult: [cid1, cid2]
        )
    }

    func test_filterPredicate_in_whenContainsMembers_containsExpectedItems() throws {
        let memberId1 = UserId.unique
        let memberId2 = UserId.unique
        let cid = ChannelId.unique

        // When all values are in DB.
        try assertFilterPredicate(
            .in(.members, values: [memberId1, memberId2]),
            channelsInDB: [
                .dummy(channel: .dummy(members: [.dummy(), .dummy()])),
                .dummy(channel: .dummy(members: [.dummy()])),
                .dummy(channel: .dummy(cid: cid, members: [
                    .dummy(user: .dummy(userId: memberId1)),
                    .dummy(user: .dummy(userId: memberId2)),
                    .dummy(user: .dummy(userId: .unique))
                ]))
            ],
            expectedResult: [cid]
        )

        // When not all of the values are in DB, it should also return the results.
        try assertFilterPredicate(
            .in(.members, values: [memberId1, memberId2]),
            channelsInDB: [
                .dummy(channel: .dummy(members: [.dummy(), .dummy()])),
                .dummy(channel: .dummy(members: [.dummy()])),
                .dummy(channel: .dummy(cid: cid, members: [
                    .dummy(user: .dummy(userId: memberId1)),
                    .dummy(user: .dummy(userId: .unique))
                ]))
            ],
            expectedResult: [cid]
        )
    }

    func test_filterPredicate_notIn_containsExpectedItems() throws {
        let memberId1 = UserId.unique
        let memberId2 = UserId.unique
        let cid1 = ChannelId.unique
        let cid2 = ChannelId.unique
        let cid3 = ChannelId.unique

        try assertFilterPredicate(
            .notIn(.members, values: [memberId1, memberId2]),
            channelsInDB: [
                .dummy(channel: .dummy(cid: cid1, members: [.dummy(user: .dummy(userId: memberId1))])),
                .dummy(channel: .dummy(cid: cid2, members: [.dummy(user: .dummy(userId: memberId2))])),
                .dummy(channel: .dummy(cid: cid3)),
                .dummy(channel: .dummy(members: [.dummy(user: .dummy(userId: memberId1)), .dummy(user: .dummy(userId: memberId2))]))
            ],
            expectedResult: [cid1, cid2, cid3]
        )
    }

    func test_filterPredicate_autocomplete_containsExpectedItems() throws {
        let cid1 = ChannelId.unique
        let cid2 = ChannelId.unique
        let cid3 = ChannelId.unique

        try assertFilterPredicate(
            .autocomplete(.name, text: "team"),
            channelsInDB: [
                .dummy(channel: .dummy(cid: cid1, name: "teamStream")),
                .dummy(channel: .dummy(cid: cid2, name: "TeAm_original")),
                .dummy(channel: .dummy(cid: cid3, name: "original_team")),
                .dummy(channel: .dummy(name: "random"))
            ],
            expectedResult: [cid1, cid2, cid3]
        )
    }

    func test_filterPredicate_contains_containsExpectedItems() throws {
        let cid1 = ChannelId.unique
        let cid2 = ChannelId.unique

        try assertFilterPredicate(
            .contains(.name, value: "te"),
            channelsInDB: [
                .dummy(channel: .dummy(name: "streamtEam")),
                .dummy(channel: .dummy(name: "originalTeam")),
                .dummy(channel: .dummy(cid: cid1, name: "basketball_team")),
                .dummy(channel: .dummy(cid: cid2, name: "teamDream")),
                .dummy(channel: .dummy(name: "TEAM"))
            ],
            expectedResult: [cid1, cid2]
        )
    }

    func test_filterPredicate_and_containsExpectedItems() throws {
        let memberId1 = UserId.unique
        let cid = ChannelId.unique

        try assertFilterPredicate(
            .and([
                .in(.members, values: [memberId1]),
                .contains(.name, value: "team")
            ]),
            channelsInDB: [
                .dummy(channel: .dummy(name: "streamtEam")),
                .dummy(channel: .dummy(name: "originalTeam")),
                .dummy(channel: .dummy(name: "basketball_team", members: [
                    .dummy(user: .dummy(userId: .unique))
                ])),
                .dummy(channel: .dummy(cid: cid, name: "teamDream", members: [
                    .dummy(user: .dummy(userId: memberId1)),
                    .dummy(user: .dummy(userId: .unique))
                ])),
                .dummy(channel: .dummy(name: "TEAM"))
            ],
            expectedResult: [cid]
        )
    }

    func test_filterPredicate_or_containsExpectedItems() throws {
        let memberId1 = UserId.unique
        let memberId2 = UserId.unique
        let cid1 = ChannelId.unique
        let cid2 = ChannelId.unique
        let cid3 = ChannelId.unique

        try assertFilterPredicate(
            .or([
                .in(.members, values: [memberId1, memberId2]),
                .contains(.name, value: "team")
            ]),
            channelsInDB: [
                .dummy(channel: .dummy(cid: cid1, name: "streamOriginal", members: [.dummy(user: .dummy(userId: memberId1)), .dummy(user: .dummy(userId: memberId2))])),
                .dummy(channel: .dummy(name: "originalTeam")),
                .dummy(channel: .dummy(cid: cid2, name: "teamDream", members: [.dummy(user: .dummy(userId: memberId1)), .dummy(user: .dummy(userId: memberId2))])),
                .dummy(channel: .dummy(cid: cid3, name: "team"))
            ],
            expectedResult: [cid1, cid2, cid3]
        )
    }

    func test_filterPredicate_whenHiddenTrueOrFalse_containsExpectedItems() throws {
        let cid1 = ChannelId(type: .messaging, id: "1")
        let cid2 = ChannelId(type: .messaging, id: "2")
        let cid3 = ChannelId(type: .messaging, id: "3")

        try assertFilterPredicate(
            .or([
                .equal(.hidden, to: true),
                .equal(.hidden, to: false)
            ]),
            channelsInDB: [
                .dummy(channel: .dummy(cid: cid1, name: "streamOriginal", isHidden: true)),
                .dummy(channel: .dummy(cid: cid2, name: "teamDream", isHidden: true)),
                .dummy(channel: .dummy(cid: cid3, name: "team", isHidden: false))
            ],
            expectedResult: [cid1, cid2, cid3]
        )
    }

    func test_filterPredicate_whenHiddenTrue_containsExpectedItems() throws {
        let cid1 = ChannelId(type: .messaging, id: "1")
        let cid2 = ChannelId(type: .messaging, id: "2")
        let cid3 = ChannelId(type: .messaging, id: "3")

        try assertFilterPredicate(
            .equal(.hidden, to: true),
            channelsInDB: [
                .dummy(channel: .dummy(cid: cid1, name: "streamOriginal", isHidden: true)),
                .dummy(channel: .dummy(cid: cid2, name: "teamDream", isHidden: true)),
                .dummy(channel: .dummy(cid: cid3, name: "team", isHidden: false))
            ],
            expectedResult: [cid1, cid2]
        )
    }

    func test_filterPredicate_whenHiddenFalse_containsExpectedItems() throws {
        let cid1 = ChannelId(type: .messaging, id: "1")
        let cid2 = ChannelId(type: .messaging, id: "2")
        let cid3 = ChannelId(type: .messaging, id: "3")

        try assertFilterPredicate(
            .equal(.hidden, to: false),
            channelsInDB: [
                .dummy(channel: .dummy(cid: cid1, name: "streamOriginal", isHidden: true)),
                .dummy(channel: .dummy(cid: cid2, name: "teamDream", isHidden: true)),
                .dummy(channel: .dummy(cid: cid3, name: "team", isHidden: false))
            ],
            expectedResult: [cid3]
        )
    }

    func test_filterPredicate_whenHiddenNotSpecified_containsExpectedItems() throws {
        let cid1 = ChannelId(type: .messaging, id: "1")
        let cid2 = ChannelId(type: .messaging, id: "2")
        let cid3 = ChannelId(type: .messaging, id: "3")

        try assertFilterPredicate(
            .noTeam,
            channelsInDB: [
                .dummy(channel: .dummy(cid: cid1, name: "streamOriginal", isHidden: true)),
                .dummy(channel: .dummy(cid: cid2, name: "teamDream", isHidden: true)),
                .dummy(channel: .dummy(cid: cid3, name: "team", isHidden: false))
            ],
            expectedResult: [cid3]
        )
    }

    func test_filterPredicate_nor_containsExpectedItems() throws {
        let memberId1 = UserId.unique
        let memberId2 = UserId.unique
        let cid = ChannelId.unique

        try assertFilterPredicate(
            .nor([
                .in(.members, values: [memberId1, memberId2]),
                .contains(.name, value: "team")
            ]),
            channelsInDB: [
                .dummy(channel: .dummy(name: "streamOriginal", members: [.dummy(user: .dummy(userId: memberId1)), .dummy(user: .dummy(userId: memberId2))])),
                .dummy(channel: .dummy(cid: cid, name: "originalTeam")),
                .dummy(channel: .dummy(name: "teamDream", members: [.dummy(user: .dummy(userId: memberId1)), .dummy(user: .dummy(userId: memberId2))])),
                .dummy(channel: .dummy(name: "team"))
            ],
            expectedResult: [cid]
        )
    }

    func test_filterPredicate_customFilterKey_cannotMatchTheCustomFilterKeySoItIgnoresIt() throws {
        let memberId1 = UserId.unique
        let memberId2 = UserId.unique
        let cid = ChannelId.unique

        try assertFilterPredicate(
            .and([
                .in(.members, values: [memberId1, memberId2]),
                .equal("myBooleanValue", to: true)
            ]),
            channelsInDB: [
                .dummy(
                    channel: .dummy(
                        cid: cid,
                        name: "streamOriginal",
                        extraData: ["myBooleanValue": false],
                        members: [.dummy(user: .dummy(userId: memberId1)), .dummy(user: .dummy(userId: memberId2))]
                    )
                )
            ],
            expectedResult: [cid]
        )
    }

    func test_filterPredicate_filterKeyContainsAValueMapper_containsExpectedItems() throws {
        let cid = ChannelId(type: .custom("test"), id: .unique)
        let memberId = UserId.unique

        try assertFilterPredicate(
            .and([
                /// Type's filter-key has value type of ChannelType. The stored value in DB though, is a String.
                /// The filter-key provides a value mapper that transforms the ChannelType into the DB Type (String)
                .equal(.type, to: .custom("test")),
                .containMembers(userIds: [memberId])
            ]),
            channelsInDB: [
                .dummy(channel: .dummy(cid: cid), members: [.dummy(user: .dummy(userId: memberId))]),
                .dummy(members: [.dummy(user: .dummy(userId: memberId))]),
                .dummy(members: [.dummy(), .dummy()])
            ],
            expectedResult: [cid]
        )
    }

    func test_filterPredicate_inWithArrayOfChannelTypes_returnsExpectedResults() throws {
        let streamChannelTypes: [ChannelType] = [
            .custom("private_messaging"),
            .custom("messaging"),
            .custom("location_group"),
            .custom("department_group"),
            .custom("role_group")
        ]

        let teamId = TeamId.unique
        let cid = ChannelId(type: .custom("private_messaging"), id: .unique)
        let memberId = UserId.unique

        try assertFilterPredicate(
            .and([
                .in(.type, values: streamChannelTypes),
                .equal(.team, to: teamId),
                .containMembers(userIds: [memberId])
            ]),
            channelsInDB: [
                .dummy(channel: .dummy(cid: cid, team: teamId), members: [.dummy(user: .dummy(userId: memberId))]),
                .dummy(channel: .dummy(cid: .init(type: .custom("private_messaging"), id: .unique)), members: [.dummy(user: .dummy(userId: memberId))]),
                .dummy(channel: .dummy(cid: .init(type: .custom("messaging"), id: .unique), team: teamId), members: [.dummy()]),
                .dummy(channel: .dummy(cid: .init(type: .custom("location_group"), id: .unique), team: teamId), members: []),
                .dummy(channel: .dummy(cid: .init(type: .custom("role_group"), id: .unique)), members: [.dummy()])
            ],
            expectedResult: [cid]
        )
    }

    func test_filterPredicate_inWithArrayOfChannelIds_returnsExpectedResults() throws {
        let chatIds: [String] = [
            "suggestions-63986de56549624f314b75cb",
            "suggestions-6ukh3986de56549624f314b75cjkhagfdkjhab",
            "suggestions-sdfdsfsad",
            "suggestions-234263986desadfsadf56549624f314b75cb"
        ]

        let channelIds = chatIds.map { ChannelId(type: .custom("daisy-dashboard"), id: $0) }

        try assertFilterPredicate(
            .in(.cid, values: channelIds),
            channelsInDB: [
                .dummy(channel: .dummy(cid: channelIds[0])),
                .dummy(channel: .dummy(cid: channelIds[1])),
                .dummy(),
                .dummy()
            ],
            expectedResult: [channelIds[0], channelIds[1]]
        )
    }

    func test_filterPredicate_inWithArrayOfIds_returnsExpectedResults() throws {
        let chatIds: [String] = [
            "suggestions-63986de56549624f314b75cb",
            "suggestions-6ukh3986de56549624f314b75cjkhagfdkjhab",
            "suggestions-sdfdsfsad",
            "suggestions-234263986desadfsadf56549624f314b75cb"
        ]

        let channelIds = chatIds.map { ChannelId(type: .custom("daisy-dashboard"), id: $0) }

        try assertFilterPredicate(
            .in(.id, values: channelIds.map(\.rawValue)),
            channelsInDB: [
                .dummy(channel: .dummy(cid: channelIds[0])),
                .dummy(channel: .dummy(cid: channelIds[1])),
                .dummy(),
                .dummy()
            ],
            expectedResult: [channelIds[0], channelIds[1]]
        )
    }

    func test_filterPredicate_autocompleteInCollection_returnsExpectedResults() throws {
        let cid = ChannelId.unique

        try assertFilterPredicate(
            .autocomplete(.memberName, text: "test"),
            channelsInDB: [
                .dummy(channel: .dummy(cid: .unique, members: [
                    .dummy(user: .dummy(userId: .unique, name: "userA")),
                    .dummy(user: .dummy(userId: .unique, name: "userC"))
                ])),
                .dummy(channel: .dummy(cid: .unique, members: [
                    .dummy(user: .dummy(userId: .unique, name: "userB"))
                ])),
                .dummy(channel: .dummy(cid: cid, members: [
                    .dummy(user: .dummy(userId: .unique, name: "testUser"))
                ]))
            ],
            expectedResult: [cid]
        )
    }

    func test_filterPredicate_autocompleteInNonCollection_returnsExpectedResults() throws {
        let cid = ChannelId.unique

        try assertFilterPredicate(
            .autocomplete(.name, text: "test"),
            channelsInDB: [
                .dummy(channel: .dummy(cid: .unique, name: "channelA")),
                .dummy(channel: .dummy(cid: .unique, name: "channelB")),
                .dummy(channel: .dummy(cid: cid, name: "testChannel"))
            ],
            expectedResult: [cid]
        )
    }

    func test_filterPredicate_containsInCollection_returnsExpectedResults() throws {
        let cid1 = ChannelId.unique
        let cid2 = ChannelId.unique

        try assertFilterPredicate(
            .contains(.memberName, value: "test"),
            channelsInDB: [
                .dummy(channel: .dummy(cid: cid1, members: [
                    .dummy(user: .dummy(userId: .unique, name: "userA")),
                    .dummy(user: .dummy(userId: .unique, name: "userCtest"))
                ])),
                .dummy(channel: .dummy(cid: .unique, members: [
                    .dummy(user: .dummy(userId: .unique, name: "userB"))
                ])),
                .dummy(channel: .dummy(cid: cid2, members: [
                    .dummy(user: .dummy(userId: .unique, name: "testUser"))
                ]))
            ],
            expectedResult: [cid1, cid2]
        )
    }

    func test_filterPredicate_joined_returnsExpectedResults() throws {
        let cid1 = ChannelId.unique
        let cid2 = ChannelId.unique

        try assertFilterPredicate(
            .equal(.joined, to: true),
            channelsInDB: [
                .dummy(channel: .dummy(cid: cid1), membership: .dummy()),
                .dummy(channel: .dummy(team: .unique)),
                .dummy(channel: .dummy(team: .unique)),
                .dummy(channel: .dummy(team: .unique)),
                .dummy(channel: .dummy(cid: cid2), membership: .dummy())
            ],
            expectedResult: [cid1, cid2]
        )
    }

    func test_filterPredicate_muted_returnsExpectedResults() throws {
        let cid1 = ChannelId.unique
        let userId = memberId

        // Create the Controller
        let query = ChannelListQuery(filter: .equal(.muted, to: true))
        controller = ChatChannelListController(
            query: query,
            client: client,
            environment: env.environment
        )
        controller.synchronize()

        // Save Mute
        let mutedChannel: ChannelDetailPayload = .dummy(
            cid: cid1,
            members: [.dummy(user: .dummy(userId: userId))]
        )
        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(channel: mutedChannel), query: query, cache: nil)
            try session.saveCurrentUser(payload: .dummy(
                userId: userId,
                role: .admin
            ))
            try session.saveChannelMute(payload: .init(
                mutedChannel: mutedChannel,
                user: .dummy(userId: userId),
                createdAt: .unique,
                updatedAt: .unique
            ))
        }

        // Save Channels
        let channelsInDB: [ChannelPayload] = [
            .dummy(channel: .dummy(cid: cid1), membership: .dummy()),
            .dummy(channel: .dummy(team: .unique)),
            .dummy(channel: .dummy(team: .unique)),
            .dummy(channel: .dummy(team: .unique))
        ]
        _ = try waitFor { [unowned client] in
            client?.databaseContainer.write({ [query] session in
                try channelsInDB.forEach { payload in
                    try session.saveChannel(payload: payload, query: query, cache: nil)
                }
            }, completion: $0)
        }

        // Assert
        let expectedResult = [cid1]
        XCTAssertEqual(
            controller.channels.map(\.cid.rawValue).sorted(),
            expectedResult.map(\.rawValue).sorted()
        )
    }
  
    func test_filterPredicate_noTeam_returnsExpectedResults() throws {
        let cid = ChannelId.unique

        try assertFilterPredicate(
            .noTeam,
            channelsInDB: [
                .dummy(channel: .dummy(cid: cid, team: nil)),
                .dummy(channel: .dummy(team: .unique)),
                .dummy(channel: .dummy(team: .unique)),
                .dummy(channel: .dummy(team: .unique)),
                .dummy(channel: .dummy(team: .unique))
            ],
            expectedResult: [cid]
        )
    }

    // MARK: - Private Helpers

    private func makeAddedChannelEvent(with channel: ChatChannel) -> NotificationAddedToChannelEvent {
        NotificationAddedToChannelEvent(
            channel: channel,
            unreadCount: nil,
            member: .mock(id: .unique),
            createdAt: .unique
        )
    }

    private func makeMessageNewEvent(with channel: ChatChannel) -> MessageNewEvent {
        MessageNewEvent(
            user: .unique,
            message: .unique,
            channel: channel,
            createdAt: .unique,
            watcherCount: nil,
            unreadCount: nil
        )
    }
    
    private func makeChannelVisibleEvent(with channel: ChatChannel) -> ChannelVisibleEvent {
        ChannelVisibleEvent(
            cid: channel.cid,
            user: .unique,
            createdAt: .unique
        )
    }

    private func makeNotificationMessageNewEvent(with channel: ChatChannel) -> NotificationMessageNewEvent {
        NotificationMessageNewEvent(
            channel: channel,
            message: .unique,
            createdAt: .unique,
            unreadCount: nil
        )
    }

    private func makeChannelUpdatedEvent(with channel: ChatChannel) -> ChannelUpdatedEvent {
        ChannelUpdatedEvent(
            channel: channel,
            user: .unique,
            message: .unique,
            createdAt: .unique
        )
    }

    private func setupControllerWithFilter(_ filter: @escaping (ChatChannel) -> Bool) {
        // Prepare controller
        controller = ChatChannelListController(
            query: query,
            client: client,
            filter: filter,
            environment: env.environment
        )
        controller.synchronize()
        waitForInitialChannelsUpdate()
    }

    private func setUpChatClientWithoutAutoFiltering() {
        var config = ChatClientConfig(apiKey: .init(.unique))
        config.isChannelAutomaticFilteringEnabled = false
        client = ChatClient.mock(config: config)
    }

    private func waitForInitialChannelsUpdate(file: StaticString = #file, line: UInt = #line) {
        guard StreamRuntimeCheck._isBackgroundMappingEnabled else { return }
        waitForChannelsUpdate {}
    }

    private func writeAndWaitForChannelsUpdates(_ actions: @escaping (DatabaseSession) throws -> Void, completion: ((Error?) -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        waitForChannelsUpdate(file: file, line: line) {
            if let completion = completion {
                client.databaseContainer.write(actions, completion: completion)
            } else {
                client.databaseContainer.write(actions)
            }
        }
    }

    private func waitForChannelsUpdate(file: StaticString = #file, line: UInt = #line, block: () -> Void) {
        let channelsExpectation = expectation(description: "Channels update")
        let delegate = ChannelsUpdateWaiter(channelsExpectation: channelsExpectation)
        controller.delegate = delegate
        block()
        wait(for: [channelsExpectation], timeout: defaultTimeout)
    }
}

private class ChannelsUpdateWaiter: ChatChannelListControllerDelegate {
    weak var channelsExpectation: XCTestExpectation?

    var didChangeChannelsCount: Int?

    init(channelsExpectation: XCTestExpectation?) {
        self.channelsExpectation = channelsExpectation
    }

    func controller(_ controller: ChatChannelListController, didChangeChannels changes: [ListChange<ChatChannel>]) {
        DispatchQueue.main.async {
            self.didChangeChannelsCount = controller.channels.count
            self.channelsExpectation?.fulfill()
        }
    }
}

private class TestEnvironment {
    @Atomic var channelListUpdater: ChannelListUpdater_Spy?

    lazy var environment: ChatChannelListController.Environment =
        .init(channelQueryUpdaterBuilder: { [unowned self] in
            self.channelListUpdater = ChannelListUpdater_Spy(
                database: $0,
                apiClient: $1
            )
            return self.channelListUpdater!
        })
}
