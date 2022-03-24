//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13, *)
class CurrentUserController_Combine_Tests: iOS13TestCase {
    var currentUserController: CurrentUserControllerMock!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        currentUserController = CurrentUserControllerMock()
        cancellables = []
    }
    
    override func tearDown() {
        // Release existing subscriptions and make sure the controller gets released, too
        cancellables = nil
        AssertAsync.canBeReleased(&currentUserController)
        super.tearDown()
    }
    
    func test_currentUserChangePublisher() {
        // Setup Recording publishers
        var recording = Record<EntityChange<CurrentChatUser>, Never>.Recording()
        
        // Setup the chain
        currentUserController
            .currentUserChangePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: CurrentUserControllerMock? = currentUserController
        currentUserController = nil

        let newCurrentUser: CurrentChatUser = .mock(id: .unique)
        controller?.currentUser_simulated = newCurrentUser
        controller?.delegateCallback {
            $0.currentUserController(controller!, didChangeCurrentUser: .create(newCurrentUser))
        }
        
        XCTAssertEqual(recording.output, [.create(newCurrentUser)])
    }
    
    func test_unreadCountPublisher() {
        // Setup Recording publishers
        var recording = Record<UnreadCount, Never>.Recording()
        
        // Setup the chain
        currentUserController
            .unreadCountPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: CurrentUserControllerMock? = currentUserController
        currentUserController = nil

        let newUnreadCount: UnreadCount = .dummy
        controller?.unreadCount_simulated = newUnreadCount
        controller?.delegateCallback {
            $0.currentUserController(controller!, didChangeCurrentUserUnreadCount: newUnreadCount)
        }
        
        XCTAssertEqual(recording.output, [.noUnread, newUnreadCount])
    }
}
