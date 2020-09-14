//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

@available(iOS 13, *)
class CurrentUserController_SwiftUI_Tests: iOS13TestCase {
    var currentUserController: CurrentUserControllerMock!
    
    override func setUp() {
        super.setUp()
        currentUserController = CurrentUserControllerMock()
    }
    
    func test_startUpdatingIsCalled_whenObservableObjectCreated() {
        assert(currentUserController.startUpdating_called == false)
        _ = currentUserController.observableObject
        XCTAssertTrue(currentUserController.startUpdating_called)
    }
    
    func test_controllerInitialValuesAreLoaded() {
        currentUserController.state_simulated = .localDataFetched
        currentUserController.currentUser_simulated = .init(id: .unique)
        
        let observableObject = currentUserController.observableObject
        
        XCTAssertEqual(observableObject.state, currentUserController.state)
        XCTAssertEqual(observableObject.currentUser, currentUserController.currentUser)
    }
    
    func test_observableObject_reactsToDelegateCurrentUserChangesCallback() {
        let observableObject = currentUserController.observableObject
        
        // Simulate current user change
        let newCurrentUser: CurrentUser = .init(id: .unique)
        currentUserController.currentUser_simulated = newCurrentUser
        currentUserController.delegateCallback {
            $0.currentUserController(
                self.currentUserController,
                didChangeCurrentUser: .create(newCurrentUser)
            )
        }
        
        AssertAsync.willBeEqual(observableObject.currentUser, newCurrentUser)
    }
    
    func test_observableObject_reactsToDelegateUnreadCountChangesCallback() {
        let observableObject = currentUserController.observableObject
        
        // Simulate unread count change
        let newUnreadCount: UnreadCount = .dummy
        currentUserController.unreadCount_simulated = newUnreadCount
        currentUserController.delegateCallback {
            $0.currentUserController(
                self.currentUserController,
                didChangeCurrentUserUnreadCount: newUnreadCount
            )
        }
        
        AssertAsync.willBeEqual(observableObject.unreadCount, newUnreadCount)
    }
    
    func test_observableObject_reactsToDelegateStateChangesCallback() {
        let observableObject = currentUserController.observableObject
        
        // Simulate state change
        let newState: Controller.State = .remoteDataFetchFailed(ClientError(with: TestError()))
        currentUserController.state_simulated = newState
        currentUserController.delegateCallback {
            $0.controller(
                self.currentUserController,
                didChangeState: newState
            )
        }
        
        AssertAsync.willBeEqual(observableObject.state, newState)
    }
    
    func test_observableObject_reactsToDelegateConnectionStatusChangesCallback() {
        let observableObject = currentUserController.observableObject
        
        // Simulate connection status change
        let newStatus: ConnectionStatus = .connected
        currentUserController.delegateCallback {
            $0.currentUserController(
                self.currentUserController,
                didUpdateConnectionStatus: newStatus
            )
        }
        
        AssertAsync.willBeEqual(observableObject.connectionStatus, newStatus)
    }
}

class CurrentUserControllerMock: CurrentUserController {
    @Atomic var startUpdating_called = false
    
    var currentUser_simulated: CurrentUserModel<DefaultDataTypes.User>?
    override var currentUser: CurrentUserModel<DefaultDataTypes.User>? {
        currentUser_simulated ?? super.currentUser
    }
    
    var unreadCount_simulated: UnreadCount?
    override var unreadCount: UnreadCount {
        unreadCount_simulated ?? super.unreadCount
    }

    var state_simulated: Controller.State?
    override var state: Controller.State {
        get { state_simulated ?? super.state }
        set { super.state = newValue }
    }
    
    init() {
        super.init(client: .mock)
    }

    override func startUpdating(_ completion: ((Error?) -> Void)? = nil) {
        startUpdating_called = true
    }
}
