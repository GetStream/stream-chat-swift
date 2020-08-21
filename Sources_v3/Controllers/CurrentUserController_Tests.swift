//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient
import XCTest

final class CurrentUserController_Tests: XCTestCase {
    private var client: ChatClient!
    private var controller: CurrentUserController!
    private var controllerCallbackQueueID: UUID!
    private var callbackQueueID: UUID { controllerCallbackQueueID }
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        client = Client(config: ChatClientConfig(apiKey: .init(.unique)))
        controller = CurrentUserController(client: client, environment: .init())
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }
    
    override func tearDown() {
        weak var weak_client = client
        weak var weak_controller = controller
        
        client = nil
        controller = nil
        controllerCallbackQueueID = nil
        
        // We need to assert asynchronously, because there can be some delegate callbacks happening
        // on the background queue, that keeps the controller alive, until they have finished.
        AssertAsync {
            Assert.willBeNil(weak_client)
            Assert.willBeNil(weak_controller)
        }
        
        super.tearDown()
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
        let currentUserPayload: CurrentUserPayload<DefaultDataTypes.User> = .dummy(userId: .unique,
                                                                                   role: .user,
                                                                                   extraData: extraData)
        
        // Set the delegate
        let delegate = TestDelegate()
        delegate.expectedQueueId = controllerCallbackQueueID
        controller.delegate = delegate

        // Start updating
        let startUpdatingError = try await(controller.startUpdating)
        
        // Assert `startUpdating` finished without any error
        XCTAssertNil(startUpdatingError)

        // Simulate saving current user to a database
        let createUserError = try await {
            client.databaseContainer.write({ session in
                try session.saveCurrentUser(payload: currentUserPayload, unreadCount: nil)
            }, completion: $0)
        }
        
        // Assert saving current user to a database finished without any error
        XCTAssertNil(createUserError)
        
        // Assert delegate received correct entity change
        AssertAsync {
            Assert.willBeEqual(delegate.didChangeCurrentUser_change?.fieldChange(\.id), .create(currentUserPayload.id))
            Assert.willBeEqual(delegate.didChangeCurrentUser_change?.item.extraData, extraData)
        }
    }
    
    func test_delegate_isNotifiedAboutUpdatedUser() throws {
        var extraData = NameAndImageExtraData(name: .unique, imageURL: .unique())
        var currentUserPayload: CurrentUserPayload<DefaultDataTypes.User> = .dummy(userId: .unique,
                                                                                   role: .user,
                                                                                   extraData: extraData)
        
        // Set the delegate
        let delegate = TestDelegate()
        delegate.expectedQueueId = controllerCallbackQueueID
        controller.delegate = delegate

        // Start updating
        let startUpdatingError = try await(controller.startUpdating)
        
        // Assert `startUpdating` finished without any error
        XCTAssertNil(startUpdatingError)

        // Simulate saving current user to a database
        let createUserError = try await {
            client.databaseContainer.write({ session in
                try session.saveCurrentUser(payload: currentUserPayload, unreadCount: nil)
            }, completion: $0)
        }
        
        // Assert saving current user to a database finished without any error
        XCTAssertNil(createUserError)
        
        // Update current user data
        extraData = NameAndImageExtraData(name: .unique, imageURL: .unique())
        currentUserPayload = .dummy(userId: currentUserPayload.id,
                                    role: currentUserPayload.role,
                                    extraData: extraData)
        
        // Simulate updating current user in a database
        let updateUserError = try await {
            client.databaseContainer.write({ session in
                try session.saveCurrentUser(payload: currentUserPayload, unreadCount: nil)
            }, completion: $0)
        }
        
        // Assert updating current user to a database finished without any error
        XCTAssertNil(updateUserError)
        
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
        let createUserError = try await {
            client.databaseContainer.write({ session in
                let currentUserPayload: CurrentUserPayload<DefaultDataTypes.User> = .dummy(userId: .unique, role: .user)
                try session.saveCurrentUser(payload: currentUserPayload, unreadCount: unreadCount)
            }, completion: $0)
        }
        
        // Assert saving current user to a database finished without any error
        XCTAssertNil(createUserError)

        // Assert delegate received correct unread count
        AssertAsync.willBeEqual(delegate.didChangeCurrentUserUnreadCount_count, unreadCount)
    }
    
    func test_delegate_isNotifiedAboutDeletedUser() {
        //TODO: Write the test once the db flushing is fixed
    }
    
    func test_delegate_isNotifiedAboutNoUnreadCount_whenUserIsDeleted() {
        //TODO: Write the test once the db flushing is fixed
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
