//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
import XCTest

@available(iOS 13, *)
final class UserController_SwiftUI_Tests: iOS13TestCase {
    var userController: ChatUserController!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        userController = ChatUserController(userId: .unique, client: .mock)
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&userController)
        
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func test_controllerInitialValuesAreLoaded() {
        // Get an observable wrapper.
        let observableObject = userController.observableObject
        
        // Assert wrapper's fields are up-to-date.
        XCTAssertEqual(observableObject.state, userController.state)
        XCTAssertEqual(observableObject.user, userController.user)
    }
    
    func test_observableObject_reactsToDelegateUserChangesCallback() {
        // Get an observable wrapper.
        let observableObject = userController.observableObject
        
        // Simulate user change.
        let newUser: ChatUser = .unique
        userController.delegateCallback {
            $0.userController(
                self.userController,
                didUpdateUser: .create(newUser)
            )
        }
        
        // Assert the change is received.
        AssertAsync.willBeEqual(observableObject.user, newUser)
    }
    
    func test_observableObject_reactsToDelegateStateChangesCallback() {
        // Get an observable wrapper.
        let observableObject = userController.observableObject
        
        // Simulate state change.
        let newState: DataController.State = .remoteDataFetchFailed(ClientError(with: TestError()))
        userController.delegateCallback {
            $0.controller(
                self.userController,
                didChangeState: newState
            )
        }
        
        // Assert the change is received.
        AssertAsync.willBeEqual(observableObject.state, newState)
    }
}

extension ChatUser {
    static var unique: ChatUser {
        .mock(
            id: .unique,
            isOnline: true,
            isBanned: true,
            userRole: .user,
            createdAt: .unique,
            updatedAt: .unique,
            lastActiveAt: .unique,
            teams: [],
            extraData: [:]
        )
    }
}
