//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient
import XCTest

final class MemberListController_Tests: StressTestCase {
    private var env: TestEnvironment!
    
    var query: ChannelMemberListQuery<NameAndImageExtraData>!
    var client: ChatClient!
    var controller: ChatChannelMemberListController!
    var controllerCallbackQueueID: UUID!
    var callbackQueueID: UUID { controllerCallbackQueueID }
    
    override func setUp() {
        super.setUp()
        
        env = TestEnvironment()
        client = _ChatClient.mock
        query = .init(cid: .unique)
        controller = .init(query: query, client: client, environment: env.environment)
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }
    
    override func tearDown() {
        client.mockAPIClient.cleanUp()
        
        query = nil
        controllerCallbackQueueID = nil
        
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
            Assert.canBeReleased(&env)
        }
        
        super.tearDown()
    }
    
    // MARK: - Controller setup
    
    func test_client_createsUserControllerCorrectly() throws {
        let controller = client.memberListController(query: query)
        
        // Assert `state` is correct.
        XCTAssertEqual(controller.state, .initialized)
        
        // Assert `client` is assigned correctly.
        XCTAssertTrue(controller.client === client)
        
        // Assert `query` is correct.
        XCTAssertEqual(controller.query.queryHash, query.queryHash)
    }
    
    func test_initialState() throws {
        // Assert `state` is correct.
        XCTAssertEqual(controller.state, .initialized)
        
        // Assert `client` is assigned correctly.
        XCTAssertTrue(controller.client === client)
        
        // Assert `query` is correct.
        XCTAssertEqual(controller.query.queryHash, query.queryHash)
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
        
        // Simulate successfull network call.
        env.memberListUpdater!.load_completion!(nil)
        
        AssertAsync {
            // Assert controller is in `remoteDataFetched` state.
            Assert.willBeEqual(self.controller.state, .remoteDataFetched)
            // Assert completion is called
            Assert.willBeTrue(completionIsCalled)
        }
    }
    
    func test_synchronize_changesState_and_propogatesObserverErrorOnCallbackQueue() {
        // Update observer to throw the error.
        let observerError = TestError()
        env.memberListObserverSynchronizeError = observerError
        
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
    
    func test_synchronize_changesState_and_propogatesListUpdaterErrorOnCallbackQueue() {
        // Simulate `synchronize` call.
        var synchronizeError: Error?
        controller.synchronize { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            synchronizeError = error
        }
        
        // Simulate failed network call.
        let updaterError = TestError()
        env.memberListUpdater!.load_completion?(updaterError)
        
        AssertAsync {
            // Assert controller is in `remoteDataFetchFailed` state.
            Assert.willBeEqual(self.controller.state, .remoteDataFetchFailed(ClientError(with: updaterError)))
            // Assert error from updater is forwarded.
            Assert.willBeEqual(synchronizeError as? TestError, updaterError)
        }
    }
    
    func test_synchronize_doesNotInvokeUpdater_ifObserverFails() {
        // Update observer to throw the error.
        env.memberListObserverSynchronizeError = TestError()
        
        // Simulate `synchronize` call.
        controller.synchronize()
        
        // Assert updater in not called.
        XCTAssertNil(env.memberListUpdater?.load_query)
    }
    
    func test_synchronize_callsUserUpdater_ifObserverSucceeds() {
        // Simulate `synchronize` call.
        controller.synchronize()
        
        // Assert updater in called.
        XCTAssertEqual(env.memberListUpdater!.load_query!.queryHash, controller.query.queryHash)
        XCTAssertNotNil(env.memberListUpdater!.load_completion)
    }
    
    // MARK: - Local data fetching triggers
    
    func test_observerIsTriggeredOnlyOnce() {
        // Check initial state
        XCTAssertEqual(controller.state, .initialized)
        
        // Set the delegate
        controller.delegate = TestDelegate(expectedQueueId: callbackQueueID)
        
        // Assert state changed
        AssertAsync.willBeEqual(controller.state, .localDataFetched)
        
        // Update observer to throw the error
        env.memberListObserver?.synchronizeError = TestError()
        
        // Set `delegate` / call `synchronize` / access `member` again
        _ = controller.members
        
        // Assert controllers stays in `localDataFetched`
        AssertAsync.staysEqual(controller.state, .localDataFetched)
    }
    
    func test_localDataIsFetched_whenDelegateIsSet() {
        // Check initial state
        XCTAssertEqual(controller.state, .initialized)
        
        // Set the delegate
        controller.delegate = TestDelegate(expectedQueueId: callbackQueueID)
        
        // Assert state changed
        AssertAsync.willBeEqual(controller.state, .localDataFetched)
    }
    
    func test_localDataIsFetched_whenUserIsAccessed() {
        // Check initial state
        XCTAssertEqual(controller.state, .initialized)
        
        // Access the members
        _ = controller.members
        
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
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        
        // Set the delegate
        controller.delegate = delegate
        
        // Assert the delegate is assigned correctly
        XCTAssert(controller.delegate === delegate)
    }
    
    func test_delegate_isNotifiedAboutStateChanges() throws {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate
        
        // Synchronize
        controller.synchronize()
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)
        
        // Simulate network call response
        env.memberListUpdater!.load_completion!(nil)
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .remoteDataFetched)
    }
    
    func test_genericDelegate_isNotifiedAboutStateChanges() throws {
        // Set the generic delegate
        let delegate = TestDelegateGeneric(expectedQueueId: callbackQueueID)
        controller.setDelegate(delegate)
        
        // Synchronize
        controller.synchronize()
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)
        
        // Simulate network call response
        env.memberListUpdater!.load_completion!(nil)
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .remoteDataFetched)
    }
    
    func test_delegate_isNotifiedAboutMembersUpdates() throws {
        let member1ID: UserId = .unique
        let member2ID: UserId = .unique
        
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate
        
        // Create channel in the database.
        try client.databaseContainer.createChannel(cid: query.cid)
        
        // Create 2 members, the first created more recently
        var member1: MemberPayload = .dummy(
            userId: member1ID,
            createdAt: Date()
        )
        var member2: MemberPayload = .dummy(
            userId: member2ID,
            createdAt: Date().addingTimeInterval(-10)
        )
        
        // Save both members to the database and link to the query.
        try client.databaseContainer.writeSynchronously { session in
            for member in [member1, member2] {
                try session.saveMember(
                    payload: member,
                    channelId: self.query.cid,
                    query: self.query
                )
            }
        }
        
        // Assert `insert` changes are received by the delegate.
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateMembers_changes?.count, 2)
            Assert
                .willBeTrue(
                    (delegate.didUpdateMembers_changes ?? []).map { $0.fieldChange(\.id) }
                        .contains(.insert(member1ID, index: [0, 0]))
                )
            Assert
                .willBeTrue(
                    (delegate.didUpdateMembers_changes ?? []).map { $0.fieldChange(\.id) }
                        .contains(.insert(member2ID, index: [0, 1]))
                )
        }
        
        // Simulate `synchronize` call to fetch user from remote
        controller.synchronize()

        // Update 2 members, the first created more recently
        member1 = .dummy(
            userId: member1ID,
            createdAt: Date()
        )
        member2 = .dummy(
            userId: member2ID,
            createdAt: Date().addingTimeInterval(-10)
        )
        
        // Save both members to the database and link to the query.
        try client.databaseContainer.writeSynchronously { session in
            for member in [member1, member2] {
                try session.saveMember(payload: member, channelId: self.query.cid, query: self.query)
            }
        }
        env.memberListUpdater!.load_completion!(nil)

        // Assert `update` changes are received by the delegate.
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateMembers_changes?.count, 2)
            Assert
                .willBeTrue(
                    (delegate.didUpdateMembers_changes ?? []).map { $0.fieldChange(\.id) }
                        .contains(.update(member1ID, index: [0, 0]))
                )
            Assert
                .willBeTrue(
                    (delegate.didUpdateMembers_changes ?? []).map { $0.fieldChange(\.id) }
                        .contains(.update(member2ID, index: [0, 1]))
                )
        }
        
        // Update second member to be created earlier than the first one.
        try client.databaseContainer.writeSynchronously { session in
            session.member(userId: member2.user.id, cid: self.query.cid)?.memberCreatedAt = Date()
        }
        
        // Assert `move` change is received for the second member.
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateMembers_changes?.count, 1)
            Assert
                .willBeTrue(
                    (delegate.didUpdateMembers_changes ?? []).map { $0.fieldChange(\.id) }
                        .contains(.move(member2ID, fromIndex: [0, 1], toIndex: [0, 0]))
                )
        }
        
        // Simulate database flush
        try client.databaseContainer.removeAllData()

        // Assert `remove` entity changes are received by the delegate.
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateMembers_changes?.count, 2)
            Assert
                .willBeTrue(
                    (delegate.didUpdateMembers_changes ?? []).map { $0.fieldChange(\.id) }
                        .contains(.remove(member1ID, index: [0, 1]))
                )
            Assert
                .willBeTrue(
                    (delegate.didUpdateMembers_changes ?? []).map { $0.fieldChange(\.id) }
                        .contains(.remove(member2ID, index: [0, 0]))
                )
            Assert.willBeEqual(self.controller.members, [])
        }
    }
    
    // MARK: - Load next members
    
    func test_loadNextMembers_propogatesError() {
        // Simulate `loadNextMembers` call and catch the completion.
        var completionError: Error?
        controller.loadNextMembers { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }
        
        // Simulate network response with the error.
        let networkError = TestError()
        env.memberListUpdater!.load_completion!(networkError)
        
        // Assert error is propogated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }
    
    func test_loadNextMembers_propogatesNilError() {
        // Simulate `loadNextMembers` call and catch the completion.
        var completionIsCalled = false
        controller.loadNextMembers { [callbackQueueID] error in
            // Assert callback queue is correct.
            AssertTestQueue(withId: callbackQueueID)
            // Assert there is no error.
            XCTAssertNil(error)
            completionIsCalled = true
        }
        
        // Simulate successful network response.
        env.memberListUpdater!.load_completion!(nil)
        
        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
    }
    
    func test_loadNextMembers_callsUserUpdaterWithCorrectValues_and_updatesTheQuery() {
        let limit = 10
        let oldPagination = controller.query.pagination
        let newPagination: Pagination = .init(pageSize: limit, offset: controller.members.count)
        
        // Simulate `loadNextMembers` call.
        controller.loadNextMembers(limit: limit)
        
        // Assert update is called with updated pagination.
        XCTAssertEqual(env.memberListUpdater!.load_query!.pagination, newPagination)
        // Assert controller still has old pagination.
        XCTAssertEqual(controller.query.pagination, oldPagination)
        
        // Simulate successful network response.
        env.memberListUpdater!.load_completion!(nil)
        
        // Assert controller's query is updated with the new pagination.
        AssertAsync.willBeEqual(controller.query.pagination, newPagination)
    }
}

private class TestEnvironment {
    @Atomic var memberListUpdater: ChannelMemberListUpdaterMock<DefaultExtraData>?
    @Atomic var memberListObserver: ListDatabaseObserverMock<ChatChannelMember, MemberDTO>?
    @Atomic var memberListObserverSynchronizeError: Error?
    
    lazy var environment: ChatChannelMemberListController.Environment = .init(
        memberListUpdaterBuilder: { [unowned self] in
            self.memberListUpdater = .init(
                database: $0,
                webSocketClient: $1,
                apiClient: $2
            )
            return self.memberListUpdater!
        },
        memberListObserverBuilder: { [unowned self] in
            self.memberListObserver = .init(
                context: $0,
                fetchRequest: $1,
                itemCreator: $2,
                fetchedResultsControllerType: $3
            )
            self.memberListObserver?.synchronizeError = self.memberListObserverSynchronizeError
            return self.memberListObserver!
        }
    )
}

// A concrete `ChatChannelMemberListControllerDelegate` implementation allowing capturing the delegate calls
private class TestDelegate: QueueAwareDelegate, ChatChannelMemberListControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didUpdateMembers_changes: [ListChange<ChatChannelMember>]?
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        validateQueue()
        self.state = state
    }
    
    func memberListController(
        _ controller: ChatChannelMemberListController,
        didChangeMembers changes: [ListChange<ChatChannelMember>]
    ) {
        validateQueue()
        didUpdateMembers_changes = changes
    }
}

// A concrete `_ChatChannelMemberListControllerDelegate` implementation allowing capturing the delegate calls.
private class TestDelegateGeneric: QueueAwareDelegate, _ChatChannelMemberListControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didUpdateMembers_changes: [ListChange<ChatChannelMember>]?
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        validateQueue()
        self.state = state
    }
    
    func memberListController(
        _ controller: ChatChannelMemberListController,
        didChangeMembers changes: [ListChange<ChatChannelMember>]
    ) {
        validateQueue()
        didUpdateMembers_changes = changes
    }
}
