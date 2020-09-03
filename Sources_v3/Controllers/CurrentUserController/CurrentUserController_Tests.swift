//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient
import XCTest

final class CurrentUserController_Tests: StressTestCase {
    private var env: TestEnvironment!
    private var client: ChatClient!
    private var controller: CurrentUserController!
    private var controllerCallbackQueueID: UUID!
    private var callbackQueueID: UUID { controllerCallbackQueueID }
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        env = TestEnvironment()
        client = Client(
            config: ChatClientConfig(apiKey: .init(.unique)),
            workerBuilders: [Worker.init],
            environment: env.clientEnvironment
        )
        controller = CurrentUserController(client: client, environment: env.currentUserControllerEnvironment)
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }
    
    override func tearDown() {
        controllerCallbackQueueID = nil
        
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
            Assert.canBeReleased(&env)
        }

        super.tearDown()
    }
    
    // MARK: Controller

    func test_initialState() {
        // Assert client is assigned correctly
        XCTAssertTrue(controller.client === client)
        
        // Assert initial state is correct
        XCTAssertEqual(controller.state, .inactive)
        
        // Assert user is nil
        XCTAssertNil(controller.currentUser)
        
        // Assert unread-count is zero
        XCTAssertEqual(controller.unreadCount, .noUnread)
    }
    
    func test_startUpdating_changesStateCorrectly_ifCompletesWithAnyError() throws {
        // Start updating
        _ = try await(controller.startUpdating)
        
        // Assert state changes to `.localDataFetched`
        XCTAssertEqual(controller.state, .localDataFetched)
    }
    
    func test_startUpdating_stateStaysInactive_ifCompletesWithError() throws {
        // Update mock observer to throws the error
        env.currentUserObserverStartUpdatingError = TestError()

        // Start updating
        _ = try await(controller.startUpdating)
        
        // Assert state stays inative
        XCTAssertEqual(controller.state, .inactive)
    }
    
    func test_startUpdating_propogatesError() throws {
        // Update mock observer to throws the error
        env.currentUserObserverStartUpdatingError = TestError()
        
        // Start updating and catch the error
        let startUpdatingError = try await(controller.startUpdating)
        
        // Assert error is propogated
        XCTAssertNotNil(startUpdatingError)
    }
    
    func test_correctDataIsAvailable_whenStartUpdatingCompletes() throws {
        let unreadCount = UnreadCount(channels: 10, messages: 212)
        let userPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user, unreadCount: unreadCount)

        // Save user to the db
        try env.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Start updating
        _ = try await(controller.startUpdating)
        
        // Assert user exists
        XCTAssertEqual(controller.unreadCount, unreadCount)
        XCTAssertEqual(controller.currentUser?.id, userPayload.id)
    }
    
    // MARK: - Delegate
    
    func test_delegate_isAssignedCorrectly() {
        let delegate = TestDelegate()
        
        // Set the delegate
        controller.delegate = delegate
        
        // Assert the delegate is assigned correctly
        XCTAssert(controller.delegate === delegate)
    }

    func test_delegate_isNotifiedAboutStateChanges() throws {
        // Set the delegate
        let delegate = TestDelegate()
        delegate.expectedQueueId = controllerCallbackQueueID
        controller.delegate = delegate
        
        // Assert no state changes received so far
        XCTAssertNil(delegate.state)
        
        // Start updating
        let startUpdatingError = try await(controller.startUpdating)
        
        // Assert `startUpdating` finished without any error
        XCTAssertNil(startUpdatingError)
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)
    }
    
    func test_genericDelegate_isNotifiedAboutStateChanges() throws {
        // Set the delegate
        let delegate = TestDelegateGeneric()
        delegate.expectedQueueId = controllerCallbackQueueID
        controller.setDelegate(delegate)
        
        // Assert no state changes received so far
        XCTAssertNil(delegate.state)
        
        // Start updating
        let startUpdatingError = try await(controller.startUpdating)
        
        // Assert `startUpdating` finished without any error
        XCTAssertNil(startUpdatingError)
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)
    }
    
    func test_delegate_isNotifiedAboutCreatedUser() throws {
        let extraData = NameAndImageExtraData(name: .unique, imageURL: .unique())
        let currentUserPayload: CurrentUserPayload<DefaultDataTypes.User> = .dummy(
            userId: .unique,
            role: .user,
            extraData: extraData
        )
        
        // Set the delegate
        let delegate = TestDelegate()
        delegate.expectedQueueId = controllerCallbackQueueID
        controller.delegate = delegate

        // Start updating
        let startUpdatingError = try await(controller.startUpdating)
        
        // Assert `startUpdating` finished without any error
        XCTAssertNil(startUpdatingError)

        // Simulate saving current user to a database
        try env.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: currentUserPayload)
        }
        
        // Assert delegate received correct entity change
        AssertAsync {
            Assert.willBeEqual(delegate.didChangeCurrentUser_change?.fieldChange(\.id), .create(currentUserPayload.id))
            Assert.willBeEqual(delegate.didChangeCurrentUser_change?.fieldChange(\.extraData), .create(extraData))
        }
    }
    
    func test_delegate_isNotifiedAboutUpdatedUser() throws {
        var extraData = NameAndImageExtraData(name: .unique, imageURL: .unique())
        var currentUserPayload: CurrentUserPayload<DefaultDataTypes.User> = .dummy(
            userId: .unique,
            role: .user,
            extraData: extraData
        )
        
        // Set the delegate
        let delegate = TestDelegate()
        delegate.expectedQueueId = controllerCallbackQueueID
        controller.delegate = delegate

        // Start updating
        let startUpdatingError = try await(controller.startUpdating)
        
        // Assert `startUpdating` finished without any error
        XCTAssertNil(startUpdatingError)

        // Simulate saving current user to a database
        try env.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: currentUserPayload)
        }
        
        // Update current user data
        extraData = NameAndImageExtraData(name: .unique, imageURL: .unique())
        currentUserPayload = .dummy(
            userId: currentUserPayload.id,
            role: currentUserPayload.role,
            extraData: extraData
        )
        
        // Simulate updating current user in a database
        try env.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: currentUserPayload)
        }
        
        // Assert delegate received correct entity change
        AssertAsync {
            Assert.willBeEqual(delegate.didChangeCurrentUser_change?.fieldChange(\.id), .update(currentUserPayload.id))
            Assert.willBeEqual(delegate.didChangeCurrentUser_change?.fieldChange(\.extraData), .update(extraData))
        }
    }

    func test_delegate_isNotifiedAboutUnreadCount_whenUserIsCreated() throws {
        let unreadCount = UnreadCount(channels: 10, messages: 15)
        
        // Set the delegate
        let delegate = TestDelegate()
        delegate.expectedQueueId = controllerCallbackQueueID
        controller.delegate = delegate

        // Start updating
        let startUpdatingError = try await(controller.startUpdating)
        
        // Assert `startUpdating` finished without any error
        XCTAssertNil(startUpdatingError)

        // Simulate saving current user to a database
        try env.databaseContainer.writeSynchronously {
            let currentUserPayload: CurrentUserPayload<DefaultDataTypes.User> = .dummy(
                userId: .unique,
                role: .user,
                unreadCount: unreadCount
            )
            try $0.saveCurrentUser(payload: currentUserPayload)
        }

        // Assert delegate received correct unread count
        AssertAsync.willBeEqual(delegate.didChangeCurrentUserUnreadCount_count, unreadCount)
    }
    
    func test_delegate_isNotifiedAboutDeletedUser() {
        // TODO: Write the test once the db flushing is fixed
        XCTAssertTrue(true)
    }
    
    func test_delegate_isNotifiedAboutNoUnreadCount_whenUserIsDeleted() {
        // TODO: Write the test once the db flushing is fixed
        XCTAssertTrue(true)
    }
}

private class TestDelegate: QueueAwareDelegate, CurrentUserControllerDelegate {
    @Atomic var state: Controller.State?
    @Atomic var didChangeCurrentUser_change: EntityChange<CurrentUser>?
    @Atomic var didChangeCurrentUserUnreadCount_count: UnreadCount?
    
    func controller(_ controller: Controller, didChangeState state: Controller.State) {
        self.state = state
        validateQueue()
    }

    func currentUserController(_ controller: CurrentUserController, didChangeCurrentUser change: EntityChange<CurrentUser>) {
        didChangeCurrentUser_change = change
        validateQueue()
    }
    
    func currentUserController(_ controller: CurrentUserController, didChangeCurrentUserUnreadCount count: UnreadCount) {
        didChangeCurrentUserUnreadCount_count = count
        validateQueue()
    }
}

private class TestDelegateGeneric: QueueAwareDelegate, CurrentUserControllerDelegateGeneric {
    @Atomic var state: Controller.State?
    @Atomic var didChangeCurrentUser_change: EntityChange<CurrentUser>?
    @Atomic var didChangeCurrentUserUnreadCount_count: UnreadCount?
   
    func controller(_ controller: Controller, didChangeState state: Controller.State) {
        self.state = state
        validateQueue()
    }
    
    func currentUserController(_ controller: CurrentUserController, didChangeCurrentUser change: EntityChange<CurrentUser>) {
        didChangeCurrentUser_change = change
        validateQueue()
    }
    
    func currentUserController(_ controller: CurrentUserController, didChangeCurrentUserUnreadCount count: UnreadCount) {
        didChangeCurrentUserUnreadCount_count = count
        validateQueue()
    }
}

private class TestEnvironment {
    var currentUserObserver: EntityDatabaseObserverMock<CurrentUser, CurrentUserDTO>!
    var currentUserObserverStartUpdatingError: Error?

    lazy var currentUserControllerEnvironment: CurrentUserController
        .Environment = .init(currentUserObserverBuilder: { [unowned self] in
            self.currentUserObserver = .init(context: $0, fetchRequest: $1, itemCreator: $2, fetchedResultsControllerType: $3)
            self.currentUserObserver.startUpdatingError = self.currentUserObserverStartUpdatingError
            return self.currentUserObserver!
        })
    
    var databaseContainer: DatabaseContainerMock!
    
    lazy var clientEnvironment: ChatClient.Environment = .init(databaseContainerBuilder: { [unowned self] in
        self.databaseContainer = try! DatabaseContainerMock(kind: $0)
        return self.databaseContainer
    })
}
