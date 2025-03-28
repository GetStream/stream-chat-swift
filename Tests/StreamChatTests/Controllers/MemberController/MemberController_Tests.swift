//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MemberController_Tests: XCTestCase {
    fileprivate var env: TestEnvironment!

    var userId: UserId!
    var cid: ChannelId!
    var client: ChatClient!
    var controller: ChatChannelMemberController!
    var controllerCallbackQueueID: UUID!
    /// Workaround for uwrapping **controllerCallbackQueueID!** in each closure that captures it
    private var callbackQueueID: UUID { controllerCallbackQueueID }

    override func setUp() {
        super.setUp()

        env = TestEnvironment()
        client = ChatClient.mock
        userId = .unique
        cid = .unique
        controller = ChatChannelMemberController(userId: userId, cid: cid, client: client, environment: env.environment)
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }

    override func tearDown() {
        userId = nil
        cid = nil
        controllerCallbackQueueID = nil

        env.memberUpdater?.cleanUp()
        env.memberListUpdater?.cleanUp()
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
            Assert.canBeReleased(&env)
        }
        super.tearDown()
    }

    // MARK: - Controller setup

    func test_client_createsUserControllerCorrectly() throws {
        let controller = client.memberController(userId: userId, in: cid)

        // Assert `state` is correct.
        XCTAssertEqual(controller.state, .initialized)

        // Assert `client` is assigned correctly.
        XCTAssertTrue(controller.client === client)

        // Assert `userId` is correct.
        XCTAssertEqual(controller.userId, userId)

        // Assert `cid` is correct.
        XCTAssertEqual(controller.cid, cid)
    }

    func test_initialState() throws {
        // Assert `state` is correct.
        XCTAssertEqual(controller.state, .initialized)

        // Assert `client` is assigned correctly.
        XCTAssertTrue(controller.client === client)

        // Assert `userId` is correct.
        XCTAssertEqual(controller.userId, userId)

        // Assert `cid` is correct.
        XCTAssertEqual(controller.cid, cid)
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
        env.memberListUpdater!.load_completion!(.success([]))
        // Release reference of completion so we can deallocate stuff
        env.memberListUpdater!.load_completion = nil

        // Assert completion is called
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_synchronize_changesState_and_propagatesObserverErrorOnCallbackQueue() {
        // Update observer to throw the error.
        let observerError = TestError()
        env.memberObserverSynchronizeError = observerError

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
        env.memberListUpdater!.load_completion?(.failure(updaterError))

        AssertAsync {
            // Assert controller is in `remoteDataFetchFailed` state.
            Assert.willBeEqual(self.controller.state, .remoteDataFetchFailed(ClientError(with: updaterError)))
            // Assert error from updater is forwarded.
            Assert.willBeEqual(synchronizeError as? TestError, updaterError)
        }
    }

    func test_synchronize_doesNotInvokeUpdater_ifObserverFails() {
        // Update observer to throw the error.
        env.memberObserverSynchronizeError = TestError()

        // Simulate `synchronize` call.
        controller.synchronize()

        // Assert updater in not called.
        XCTAssertNil(env.memberListUpdater?.load_query)
    }

    func test_synchronize_callsUserUpdater_ifObserverSucceeds() {
        // Simulate `synchronize` call.
        controller.synchronize()

        // Assert updater in called
        XCTAssertEqual(env.memberListUpdater!.load_query!.cid, controller.cid)
        XCTAssertNotNil(env.memberListUpdater!.load_completion)
    }

    /// This test simulates a bug where the `member` field was not updated if it wasn't
    /// touched before calling synchronize.
    func test_memberIsFetched_evenAfterCallingSynchronize() throws {
        // Simulate `synchronize` call.
        controller.synchronize()

        // Create a user in the DB
        try client.databaseContainer.createMember(userId: userId, cid: cid)

        // Simulate updater callback
        env.memberListUpdater?.load_completion?(.success([]))

        // Assert the user is loaded
        XCTAssertEqual(controller.member?.id, userId)
    }

    // MARK: - Local data fetching triggers

    func test_observerIsTriggeredOnlyOnce() {
        // Check initial state
        XCTAssertEqual(controller.state, .initialized)

        // Set the delegate
        controller.delegate = ChannelMemberController_Delegate(expectedQueueId: callbackQueueID)

        // Assert state changed
        AssertAsync.willBeEqual(controller.state, .localDataFetched)

        // Update observer to throw the error
        env.memberObserver?.synchronizeError = TestError()

        // Set `delegate` / call `synchronize` / access `member` again
        _ = controller.member

        // Assert controllers stays in `localDataFetched`
        AssertAsync.staysEqual(controller.state, .localDataFetched)
    }

    func test_localDataIsFetched_whenDelegateIsSet() {
        // Check initial state
        XCTAssertEqual(controller.state, .initialized)

        // Set the delegate
        controller.delegate = ChannelMemberController_Delegate(expectedQueueId: callbackQueueID)

        // Assert state changed
        AssertAsync.willBeEqual(controller.state, .localDataFetched)
    }

    func test_localDataIsFetched_whenUserIsAccessed() {
        // Check initial state
        XCTAssertEqual(controller.state, .initialized)

        // Access the member
        _ = controller.member

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
        let delegate = ChannelMemberController_Delegate(expectedQueueId: callbackQueueID)

        // Set the delegate
        controller.delegate = delegate

        // Assert the delegate is assigned correctly
        XCTAssert(controller.delegate === delegate)
    }

    func test_delegate_isNotifiedAboutStateChanges() throws {
        // Set the delegate
        let delegate = ChannelMemberController_Delegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        // Synchronize
        controller.synchronize()

        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)

        // Simulate network call response
        env.memberListUpdater!.load_completion!(.success([]))

        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .remoteDataFetched)
    }

    func test_delegate_isNotifiedAboutMemberUpdates() throws {
        // Set the delegate
        let delegate = ChannelMemberController_Delegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        // Create member in the database.
        let initialRole: MemberRole = .member
        try client.databaseContainer.createMember(userId: userId, role: initialRole, cid: cid)

        // Assert `create` entity change is received by the delegate
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateMember_change?.fieldChange(\.id), .create(self.userId))
            Assert.willBeEqual(delegate.didUpdateMember_change?.fieldChange(\.memberRole), .create(initialRole))
        }

        // Simulate `synchronize` call to fetch user from remote
        controller.synchronize()

        // Simulate response from a backend with updated member
        let updatedRole: MemberRole = .admin
        try client.databaseContainer.writeSynchronously { session in
            let dto = try XCTUnwrap(session.member(userId: self.userId, cid: self.cid))
            dto.channelRoleRaw = updatedRole.rawValue
        }
        env.memberListUpdater!.load_completion!(.success([]))

        // Assert `update` entity change is received by the delegate
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateMember_change?.fieldChange(\.id), .update(self.userId))
            Assert.willBeEqual(delegate.didUpdateMember_change?.fieldChange(\.memberRole), .update(updatedRole))
        }
    }

    // MARK: - Ban user

    func test_ban_propagatesError() {
        // Simulate `ban` call and catch the completion.
        var completionError: Error?
        controller.ban { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate network response with the error.
        let networkError = TestError()
        env.memberUpdater!.banMember_completion!(networkError)

        // Assert error is propogated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }

    func test_ban_propagatesNilError() {
        // Simulate `ban` call and catch the completion.
        var completionIsCalled = false
        controller.ban { [callbackQueueID] error in
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
        env.memberUpdater!.banMember_completion!(nil)
        // Release reference of completion so we can deallocate stuff
        env.memberUpdater!.banMember_completion = nil

        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_ban_callsMemberUpdater_withCorrectValues() {
        let timeout = 10
        let reason: String = .unique

        // Simulate `ban` call.
        controller.ban(for: timeout, reason: reason)

        // Assert updater is called with correct values
        XCTAssertEqual(env.memberUpdater!.banMember_userId, controller.userId)
        XCTAssertEqual(env.memberUpdater!.banMember_cid, controller.cid)
        XCTAssertEqual(env.memberUpdater!.banMember_timeoutInMinutes, timeout)
        XCTAssertEqual(env.memberUpdater!.banMember_reason, reason)
        XCTAssertEqual(env.memberUpdater!.banMember_shadow, false)
    }

    // MARK: - Shadow Ban

    func test_shadowBan_propagatesError() {
        // Simulate `shadowBan` call and catch the completion.
        var completionError: Error?
        controller.shadowBan { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate network response with the error.
        let networkError = TestError()
        env.memberUpdater!.banMember_completion!(networkError)

        // Assert error is propogated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }

    func test_shadowBan_propagatesNilError() {
        // Simulate `shadowBan` call and catch the completion.
        var completionIsCalled = false
        controller.shadowBan { [callbackQueueID] error in
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
        env.memberUpdater!.banMember_completion!(nil)
        // Release reference of completion so we can deallocate stuff
        env.memberUpdater!.banMember_completion = nil

        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_shadowBan_callsMemberUpdater_withCorrectValues() {
        let timeout = 10
        let reason: String = .unique

        // Simulate `shadowBan` call.
        controller.shadowBan(for: timeout, reason: reason)

        // Assert updater is called with correct values
        XCTAssertEqual(env.memberUpdater!.banMember_userId, controller.userId)
        XCTAssertEqual(env.memberUpdater!.banMember_cid, controller.cid)
        XCTAssertEqual(env.memberUpdater!.banMember_timeoutInMinutes, timeout)
        XCTAssertEqual(env.memberUpdater!.banMember_reason, reason)
        XCTAssertEqual(env.memberUpdater!.banMember_shadow, true)
    }

    // MARK: - Unban user

    func test_unban_propagatesError() {
        // Simulate `unban` call and catch the completion.
        var completionError: Error?
        controller.unban { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate network response with the error.
        let networkError = TestError()
        env.memberUpdater!.unbanMember_completion!(networkError)

        // Assert error is propogated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }

    func test_unban_propagatesNilError() {
        // Simulate `unban` call and catch the completion.
        var completionIsCalled = false
        controller.unban { [callbackQueueID] error in
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
        env.memberUpdater!.unbanMember_completion!(nil)
        // Release reference of completion so we can deallocate stuff
        env.memberUpdater!.unbanMember_completion = nil

        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_unban_callsUserUpdater_withCorrectValues() {
        // Simulate `unban` call.
        controller.unban()

        // Assert updater is called with correct values
        XCTAssertEqual(env.memberUpdater!.unbanMember_userId, controller.userId)
        XCTAssertEqual(env.memberUpdater!.unbanMember_cid, controller.cid)
    }

    // MARK: - Partial Update

    func test_partialUpdate_propagatesError() {
        let expectedError = TestError()
        
        // Simulate `partialUpdate` call and catch the completion
        var receivedResult: Result<ChatChannelMember, Error>?
        controller.partialUpdate(extraData: ["key": .string("value")], unsetProperties: ["field"]) { [callbackQueueID] result in
            AssertTestQueue(withId: callbackQueueID)
            receivedResult = result
        }
        
        // Simulate network response with error
        env.memberUpdater!.partialUpdate_completion?(.failure(expectedError))
        
        // Assert error is propagated
        AssertAsync.willBeEqual(receivedResult?.error as? TestError, expectedError)
    }

    func test_partialUpdate_propagatesSuccess() {
        let expectedMember: ChatChannelMember = .mock(id: .unique)

        // Simulate `partialUpdate` call and catch the completion
        var receivedResult: Result<ChatChannelMember, Error>?
        controller.partialUpdate(extraData: ["key": .string("value")], unsetProperties: ["field"]) { [callbackQueueID] result in
            AssertTestQueue(withId: callbackQueueID)
            receivedResult = result
        }
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil
        
        // Simulate successful network response
        env.memberUpdater!.partialUpdate_completion?(.success(expectedMember))
        // Release reference of completion so we can deallocate stuff
        env.memberUpdater!.partialUpdate_completion = nil
        
        // Assert success is propagated
        AssertAsync.willBeEqual(receivedResult?.value?.id, expectedMember.id)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_partialUpdate_callsMemberUpdater_withCorrectValues() {
        let extraData: [String: RawJSON] = ["key": .string("value")]
        let unsetProperties = ["field1", "field2"]
        
        // Simulate `partialUpdate` call
        controller.partialUpdate(extraData: extraData, unsetProperties: unsetProperties)
        
        // Assert updater is called with correct values
        XCTAssertEqual(env.memberUpdater!.partialUpdate_userId, controller.userId)
        XCTAssertEqual(env.memberUpdater!.partialUpdate_cid, controller.cid)
        XCTAssertEqual(env.memberUpdater!.partialUpdate_updates?.extraData, extraData)
        XCTAssertEqual(env.memberUpdater!.partialUpdate_unset, unsetProperties)
    }
}

private class TestEnvironment {
    @Atomic var memberUpdater: ChannelMemberUpdater_Mock?
    @Atomic var memberListUpdater: ChannelMemberListUpdater_Mock?
    @Atomic var memberObserver: BackgroundEntityDatabaseObserver_Mock<ChatChannelMember, MemberDTO>?
    @Atomic var memberObserverSynchronizeError: Error?

    lazy var environment: ChatChannelMemberController.Environment = .init(
        memberUpdaterBuilder: { [unowned self] in
            self.memberUpdater = .init(
                database: $0,
                apiClient: $1
            )
            return self.memberUpdater!
        },
        memberListUpdaterBuilder: { [unowned self] in
            self.memberListUpdater = .init(
                database: $0,
                apiClient: $1
            )
            return self.memberListUpdater!
        },
        memberObserverBuilder: { [unowned self] in
            self.memberObserver = .init(
                database: $0,
                fetchRequest: $1,
                itemCreator: $2,
                fetchedResultsControllerType: $3
            )
            self.memberObserver?.synchronizeError = self.memberObserverSynchronizeError
            return self.memberObserver!
        }
    )
}
