//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13, *)
final class CurrentUserController_SwiftUI_Tests: iOS13TestCase {
    var currentUserController: CurrentUserController_Mock!
    
    override func setUp() {
        super.setUp()
        currentUserController = CurrentUserController_Mock()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&currentUserController)
        currentUserController = nil
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
