//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13, *)
class CurrentUserController_SwiftUI_Tests: iOS13TestCase {
    var currentUserController: CurrentUserControllerMock!
    
    override func setUp() {
        super.setUp()
        currentUserController = CurrentUserControllerMock()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&currentUserController)
        super.tearDown()
    }
    
    func test_controllerInitialValuesAreLoaded() {
        currentUserController.currentUser_simulated = .mock(id: .unique)
        
        let observableObject = currentUserController.observableObject
        
        XCTAssertEqual(observableObject.currentUser, currentUserController.currentUser)
    }
    
    func test_observableObject_reactsToDelegateCurrentUserChangesCallback() {
        let observableObject = currentUserController.observableObject
        
        // Simulate current user change
        let newCurrentUser: CurrentChatUser = .mock(id: .unique)
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
}

class CurrentUserControllerMock: CurrentChatUserController {
    var currentUser_simulated: CurrentChatUser?
    override var currentUser: CurrentChatUser? {
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
