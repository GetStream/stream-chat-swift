//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelListController_Tests: XCTestCase {
    fileprivate var env: TestEnvironment!

    var client: ChatClient!
    var memberId: UserId = .unique
    var query: ChannelListQuery!

    var controller: ChatChannelListController!
    var controllerCallbackQueueID: UUID!
    /// Workaround for unwrapping **controllerCallbackQueueID!** in each closure that captures it
    private var callbackQueueID: UUID { controllerCallbackQueueID }

    var database: DatabaseContainer_Spy { client.databaseContainer as! DatabaseContainer_Spy }

    override func setUp() {
        super.setUp()

        env = TestEnvironment()
        client = ChatClient.mock()
        query = .init(filter: .in(.members, values: [memberId]))
        controller = ChatChannelListController(query: query, client: client, environment: env.environment)
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }

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
        client.databaseContainer.write { session in
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

        try client.databaseContainer.writeSynchronously { session in
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
        env.channelListUpdater?.update_completion?(.success([]))
        // Release reference of completion so we can deallocate stuff
        env.channelListUpdater?.update_completion = nil

        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
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

        // Assert the updater is called with the correct pageSize
        XCTAssertEqual(env.channelListUpdater!.update_queries.first?.pagination.pageSize, pageSize)
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)

        // Simulate successful update
        env.channelListUpdater!.update_completion?(.success([]))
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
        env.channelListUpdater?.update_completion?(.success([]))
        // Release reference of completion so we can deallocate stuff
        env.channelListUpdater?.update_completion = nil

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
        env.channelListUpdater?.update_completion?(.failure(testError))

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

    func test_newChannel_callsListHook_whenSynchronized() throws {
        // Simulate `synchronize` call and catch the completion
        var synchronized = false
        controller.synchronize { _ in synchronized = true }

        // Add the channel to the DB
        let cid: ChannelId = .unique
        let channelPayload = dummyPayload(with: cid, members: [.dummy(user: .dummy(userId: memberId))])
        var channel: ChatChannel!
        try database.writeSynchronously { session in
            let dto = try session.saveChannel(payload: channelPayload, query: self.query, cache: nil)
            channel = try dto.asModel()
        }

        // Simulate successful response from backend
        env.channelListUpdater?.update_completion?(.success([channel]))

        AssertAsync {
            // Assert synchronized completion is invoked
            Assert.willBeTrue(synchronized)
            // Assert the resulting value is updated
            Assert.willBeEqual(self.controller.channels.map(\.cid), [cid])
        }

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
            try session.saveChannel(payload: .dummy(cid: newCid, members: [.dummy(user: .dummy(userId: self.memberId))]), query: nil, cache: nil)
        }

        // Assert the resulting value is not inserted
        AssertAsync.willBeEqual(controller.channels.map(\.cid), [cid])

        // Insert a new channel to DB
        let insertedCid = ChannelId.unique
        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: insertedCid, members: [.dummy(user: .dummy(userId: self.memberId))]), query: nil, cache: nil)
        }

        // Assert the resulting value is inserted
        AssertAsync.willBeEqual(controller.channels.map(\.cid.rawValue).sorted(), [cid.rawValue, insertedCid.rawValue].sorted())
    }

    func test_updatedChannel_callsLinkHook_whenSynchronized() throws {
        // Simulate `synchronize` call and catch the completion
        var synchronized = false
        controller.synchronize { _ in synchronized = true }

        // Add the channel to the DB
        let cid: ChannelId = .unique
        let channelPayload = dummyPayload(with: cid, members: [.dummy(user: .dummy(userId: memberId))])
        var channel: ChatChannel!
        try database.writeSynchronously { session in
            let dto = try session.saveChannel(payload: channelPayload, query: self.query, cache: nil)
            channel = try dto.asModel()
        }

        // Simulate successful response from backend
        env.channelListUpdater?.update_completion?(.success([channel]))

        AssertAsync {
            // Assert synchronized completion is invoked
            Assert.willBeTrue(synchronized)
            // Assert the resulting value is updated
            Assert.willBeEqual(self.controller.channels.map(\.cid), [cid])
        }

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
            try session.saveChannel(payload: .dummy(cid: shouldBeInsertedCid, members: [.dummy(user: .dummy(userId: self.memberId))]), query: nil, cache: nil)
            try session.saveChannel(payload: .dummy(cid: shouldBeExcludedCid, members: [.dummy(user: .dummy(userId: self.memberId))]), query: nil, cache: nil)
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

    func test_updatedChannel_callsUnlinkHook_whenSynchronized() throws {
        // Simulate `synchronize` call and catch the completion
        var synchronized = false
        controller.synchronize { _ in synchronized = true }

        // Add the channel to the DB
        let cid: ChannelId = .unique
        let channelPayload = dummyPayload(with: cid, members: [.dummy(user: .dummy(userId: memberId))])
        var channel: ChatChannel!
        try database.writeSynchronously { session in
            let dto = try session.saveChannel(payload: channelPayload, query: self.query, cache: nil)
            channel = try dto.asModel()
        }

        // Simulate successful response from backend
        env.channelListUpdater?.update_completion?(.success([channel]))

        AssertAsync {
            // Assert synchronized completion is invoked
            Assert.willBeTrue(synchronized)
            // Assert the resulting value is updated
            Assert.willBeEqual(self.controller.channels.map(\.cid), [cid])
        }

        // Create and assign delegate
        let delegate = TestLinkDelegate(
            shouldListNewChannel: { _ in false },
            shouldListUpdatedChannel: { channel in
                channel.cid != cid
            }
        )
        controller.delegate = delegate

        // Update linked channel
        try database.writeSynchronously { session in
            let channelDTO = session.channel(cid: cid)
            channelDTO?.updatedAt = .unique
        }

        // Assert that new channel is unlinked
        AssertAsync.willBeEqual(controller.channels.map(\.cid), [])
    }

    func test_unlinkedChannels_doNotTriggerHooks_whenNotSynchronized() throws {
        // Create and assign delegate, catch
        var delegateCalled = false
        let delegate = TestLinkDelegate(shouldListNewChannel: { _ in
            delegateCalled = true
            return false
        }, shouldListUpdatedChannel: { _ in
            delegateCalled = true
            return false
        })
        controller.delegate = delegate

        // Save a channel not-linked to the current query
        let cid: ChannelId = .unique
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid), query: nil, cache: nil)
        }

        AssertAsync {
            // Assert hooks are not called
            Assert.staysFalse(delegateCalled)
            // Assert channels stay empty
            Assert.willBeEqual(self.controller.channels.map(\.cid), [])
        }

        // Update a channel not linked to the current query
        try database.writeSynchronously { session in
            let dto = try XCTUnwrap(session.channel(cid: cid))
            dto.updatedAt = .unique
        }

        AssertAsync {
            // Assert hooks are not called
            Assert.staysFalse(delegateCalled)
            // Assert channels stay empty
            Assert.willBeEqual(self.controller.channels.map(\.cid), [])
        }
    }

    func test_linkedChannels_doesTriggerUnlinkHook_whenNotSynchronized() throws {
        // Save a channel linked to the current query
        let cid: ChannelId = .unique
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid, members: [.dummy(user: .dummy(userId: self.memberId))]), query: self.query, cache: nil)
        }

        // Assert channel is linked
        AssertAsync.willBeEqual(controller.channels.map(\.cid), [cid])

        // Create and assign delegate excluding a channel from a query
        let delegate = TestLinkDelegate(shouldListNewChannel: { _ in
            true
        }, shouldListUpdatedChannel: { channel in
            channel.cid != cid
        })
        controller.delegate = delegate

        // Update a channel linked to the current query
        try database.writeSynchronously { session in
            let dto = try XCTUnwrap(session.channel(cid: cid))
            dto.updatedAt = .unique
        }

        // Assert linked channel is unlisted
        AssertAsync.willBeEqual(controller.channels.map(\.cid), [])
    }

    func test_hiddenChannel_isExcluded_whenFilterDoesntContainHiddenKey() throws {
        // Add 2 channels to the DB
        let cid: ChannelId = .unique
        try database.writeSynchronously { session in
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

        // Add 2 channels to the DB
        let cid: ChannelId = .unique
        try database.writeSynchronously { session in
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

    // MARK: - Change propagation tests with filter block

    func test_addingANewChannelThatMatchesFilter_shouldLinkItToQuery_shouldWatchIt() throws {
        var filterCalls = 0
        prepareControllerWithOwnerFilter(userId: memberId, onFilterCall: { filterCalls += 1 })

        // Simulate `synchronize` call
        let expectation = self.expectation(description: "Synchronize completion")
        controller.synchronize { _ in expectation.fulfill() }
        let originalCid: ChannelId = .unique
        try addOrUpdateChannel(cid: originalCid, ownerId: memberId, query: query)

        // Simulate successful response from backend
        env.channelListUpdater?.update_completion?(.success([]))
        waitForExpectations(timeout: defaultTimeout, handler: nil)
        XCTAssertEqual(controller.channels.count, 1)
        XCTAssertEqual(filterCalls, 0)

        let ownedCid: ChannelId = .unique
        let unownedCid: ChannelId = .unique
        try [ownedCid, unownedCid].forEach { cid in
            try addOrUpdateChannel(cid: cid, ownerId: cid == ownedCid ? memberId : "other", query: nil)
        }

        // The original channel + the owned that was just added
        AssertAsync.willBeEqual(controller.channels.count, 2)
        XCTAssertTrue(controller.channels.contains { $0.cid == originalCid })
        XCTAssertTrue(controller.channels.contains { $0.cid == ownedCid })
        XCTAssertFalse(controller.channels.contains { $0.cid == unownedCid })

        // Two channels were added to the DB, both were evaluated, only one was added to the list
        XCTAssertEqual(filterCalls, 2)
        // Watches channel that was added to the list
        XCTAssertEqual(env.channelListUpdater?.startWatchingChannels_cids, [ownedCid])
    }

    func test_updatingAChannelThatIsLinkedToTheQuery_shouldUnlinkIt() throws {
        var filterCalls = 0
        prepareControllerWithOwnerFilter(userId: memberId, onFilterCall: { filterCalls += 1 })

        // Simulate `synchronize` call
        let expectation = self.expectation(description: "Synchronize completion")
        controller.synchronize { _ in expectation.fulfill() }
        let originalCid: ChannelId = .unique
        try addOrUpdateChannel(cid: originalCid, ownerId: memberId, query: query)

        // Simulate successful response from backend
        env.channelListUpdater?.update_completion?(.success([]))
        waitForExpectations(timeout: defaultTimeout, handler: nil)
        XCTAssertEqual(controller.channels.count, 1)
        XCTAssertEqual(filterCalls, 0)

        // Simulate update of the channel linked to query
        try addOrUpdateChannel(cid: originalCid, ownerId: "something else", query: nil)

        // The original channel + the owned that was just added
        AssertAsync.willBeEqual(controller.channels.count, 0)
        XCTAssertFalse(controller.channels.contains { $0.cid == originalCid })

        // The updated channel was evaluated once to be unlinked, and then by the unlinked query listener
        XCTAssertEqual(filterCalls, 2)
    }

    func test_updatingAChannelThatIsNotLinkedToTheQuery_shouldLinkIt() throws {
        var filterCalls = 0
        prepareControllerWithOwnerFilter(userId: memberId, onFilterCall: { filterCalls += 1 })

        // Simulate `synchronize` call
        let expectation = self.expectation(description: "Synchronize completion")
        controller.synchronize { _ in expectation.fulfill() }
        let originalCid: ChannelId = .unique
        try addOrUpdateChannel(cid: originalCid, ownerId: memberId, query: query)

        // Simulate successful response from backend
        env.channelListUpdater?.update_completion?(.success([]))
        waitForExpectations(timeout: defaultTimeout, handler: nil)
        XCTAssertEqual(controller.channels.count, 1)
        XCTAssertEqual(filterCalls, 0)

        let originallyUnownedCid: ChannelId = .unique
        try addOrUpdateChannel(cid: originallyUnownedCid, ownerId: "other", query: nil)

        // The added channel should be evaluated, but not added
        AssertAsync.willBeEqual(filterCalls, 1)
        XCTAssertTrue(controller.channels.contains { $0.cid == originalCid })
        XCTAssertFalse(controller.channels.contains { $0.cid == originallyUnownedCid })

        // Simulate update on the channel not matching the query, to make it match it
        try addOrUpdateChannel(cid: originallyUnownedCid, ownerId: memberId, query: nil)

        // The updated channel should be evaluated, and added
        AssertAsync.willBeEqual(controller.channels.count, 2)
        XCTAssertEqual(filterCalls, 2)
        XCTAssertTrue(controller.channels.contains { $0.cid == originalCid })
        XCTAssertTrue(controller.channels.contains { $0.cid == originallyUnownedCid })
    }

    private func addOrUpdateChannel(cid: ChannelId, ownerId: String, query: ChannelListQuery?) throws {
        try database.writeSynchronously { session in
            let payload = self.dummyPayload(with: cid, members: [.dummy(user: .dummy(userId: self.memberId))], channelExtraData: ["owner_id": .string(ownerId)])
            try session.saveChannel(payload: payload, query: query, cache: nil)
        }
    }

    private func prepareControllerWithOwnerFilter(userId: UserId, onFilterCall: @escaping () -> Void) {
        let filter: (ChatChannel) -> Bool = { channel in
            onFilterCall()
            guard case let .string(owner) = channel.extraData["owner_id"] else { return false }
            return owner == userId
        }

        // Prepare controller

        client.authenticationRepository.setMockToken()
        query = .init(filter: .and(
            [
                .containMembers(userIds: [userId]),
                .notEqual(.init(rawValue: "owner_id"), to: userId)
            ]
        ))
        controller = ChatChannelListController(query: query, client: client, filter: filter, environment: env.environment)
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

        let cid: ChannelId = .unique
        let delegate = Delegate(cid: cid)

        controller.callbackQueue = .main
        controller.delegate = delegate

        client.databaseContainer.write { session in
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
        /// Ensure that runtimeCheck is enabled
        StreamRuntimeCheck.isChannelLocalFilteringEnabled = true

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

        AssertAsync.willBeEqual(
            controller.channels.map(\.cid),
            [],
            file: file,
            line: line
        )

        // Simulate changes in the DB:
        _ = try waitFor { [unowned client] in
            client?.databaseContainer.write({ [query] session in
                try channelsInDB().forEach { payload in
                    try session.saveChannel(payload: payload, query: query, cache: nil)
                }
            }, completion: $0)
        }

        // Assert the resulting value is updated
        AssertAsync.willBeEqual(
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
        let memberId1 = UserId.unique
        let memberId2 = UserId.unique
        let cid = ChannelId.unique

        try assertFilterPredicate(
            .in(.members, values: [memberId1, memberId2]),
            channelsInDB: [
                .dummy(channel: .dummy(members: [.dummy(), .dummy()])),
                .dummy(channel: .dummy(members: [.dummy()])),
                .dummy(channel: .dummy(cid: cid, members: [.dummy(user: .dummy(userId: memberId1)), .dummy(user: .dummy(userId: memberId2))]))
            ],
            expectedResult: [cid]
        )
    }

    func test_filterPredicate_notIn_containsExpectedItems() throws {
        let memberId1 = UserId.unique
        let memberId2 = UserId.unique
        let cid1 = ChannelId.unique
        let cid2 = ChannelId.unique

        try assertFilterPredicate(
            .notIn(.members, values: [memberId1, memberId2]),
            channelsInDB: [
                .dummy(channel: .dummy(cid: cid1, members: [.dummy(), .dummy()])),
                .dummy(channel: .dummy(cid: cid2, members: [.dummy()])),
                .dummy(channel: .dummy(members: [.dummy(user: .dummy(userId: memberId1)), .dummy(user: .dummy(userId: memberId2))]))
            ],
            expectedResult: [cid1, cid2]
        )
    }

    func test_filterPredicate_autocomplete_containsExpectedItems() throws {
        let cid1 = ChannelId.unique
        let cid2 = ChannelId.unique

        try assertFilterPredicate(
            .autocomplete(.name, text: "team"),
            channelsInDB: [
                .dummy(channel: .dummy(cid: cid1, name: "teamStream")),
                .dummy(channel: .dummy(cid: cid2, name: "TeAm_original")),
                .dummy(channel: .dummy(name: "random"))
            ],
            expectedResult: [cid1, cid2]
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
        let memberId2 = UserId.unique
        let cid = ChannelId.unique

        try assertFilterPredicate(
            .and([
                .in(.members, values: [memberId1, memberId2]),
                .contains(.name, value: "team")
            ]),
            channelsInDB: [
                .dummy(channel: .dummy(name: "streamtEam")),
                .dummy(channel: .dummy(name: "originalTeam")),
                .dummy(channel: .dummy(name: "basketball_team", members: [.dummy(user: .dummy(userId: memberId2))])),
                .dummy(channel: .dummy(cid: cid, name: "teamDream", members: [.dummy(user: .dummy(userId: memberId1)), .dummy(user: .dummy(userId: memberId2))])),
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
