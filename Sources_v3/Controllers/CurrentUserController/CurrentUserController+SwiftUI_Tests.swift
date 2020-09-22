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
    
    func test_controllerInitialValuesAreLoaded() {
        currentUserController.currentUser_simulated = .init(id: .unique)
        
        let observableObject = currentUserController.observableObject
        
        XCTAssertEqual(observableObject.currentUser, currentUserController.currentUser)
    }
    
    func test_observableObject_reactsToDelegateCurrentUserChangesCallback() {
        let observableObject = currentUserController.observableObject
        
        // Simulate current user change
        let newCurrentUser: CurrentChatUser = .init(id: .unique)
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

class CurrentUserControllerMock: CurrentChatUserController {
    var currentUser_simulated: _CurrentChatUser<DefaultExtraData.User>?
    override var currentUser: _CurrentChatUser<DefaultExtraData.User>? {
        currentUser_simulated ?? super.currentUser
    }
    
    var unreadCount_simulated: UnreadCount?
    override var unreadCount: UnreadCount {
        unreadCount_simulated ?? super.unreadCount
    }
    
    init() {
        super.init(client: .mock)
    }
}
