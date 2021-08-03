//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

@available(iOS 13, *)
class UserListController_SwiftUI_Tests: iOS13TestCase {
    var userListController: UserListControllerMock!
    
    override func setUp() {
        super.setUp()
        userListController = UserListControllerMock()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&userListController)
        super.tearDown()
    }
    
    func test_controllerInitialValuesAreLoaded() {
        userListController.state_simulated = .localDataFetched
        userListController.users_simulated = [.unique]
        
        let observableObject = userListController.observableObject
        
        XCTAssertEqual(observableObject.state, userListController.state)
        XCTAssertEqual(observableObject.users, userListController.users)
    }
    
    func test_observableObject_reactsToDelegateUserChangesCallback() {
        let observableObject = userListController.observableObject
        
        // Simulate user change
        let newUser: ChatUser = .unique
        userListController.users_simulated = [newUser]
        userListController.delegateCallback {
            $0.controller(
                self.userListController,
                didChangeUsers: [.insert(newUser, index: [0, 1])]
            )
        }
        
        AssertAsync.willBeEqual(Array(observableObject.users), [newUser])
    }
    
    func test_observableObject_reactsToDelegateStateChangesCallback() {
        let observableObject = userListController.observableObject
        
        // Simulate state change
        let newState: DataController.State = .remoteDataFetchFailed(ClientError(with: TestError()))
        userListController.state_simulated = newState
        userListController.delegateCallback {
            $0.controller(
                self.userListController,
                didChangeState: newState
            )
        }
        
        AssertAsync.willBeEqual(observableObject.state, newState)
    }
}

class UserListControllerMock: ChatUserListController {
    @Atomic var synchronize_called = false
    
    var users_simulated: [ChatUser]?
    override var users: LazyCachedMapCollection<ChatUser> {
        users_simulated.map { $0.lazyCachedMap { $0 } } ?? super.users
    }

    var state_simulated: DataController.State?
    override var state: DataController.State {
        get { state_simulated ?? super.state }
        set { super.state = newValue }
    }
    
    init() {
        super.init(query: .init(filter: .none), client: .mock)
    }

    override func synchronize(_ completion: ((Error?) -> Void)? = nil) {
        synchronize_called = true
    }
}
