//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13, *)
final class CurrentUserController_Combine_Tests: iOS13TestCase {
    var currentUserController: CurrentUserController_Mock!
    var cancellables: Set<AnyCancellable>!

    let initialUnreadCount = UnreadCount(channels: 2, messages: 2)

    override func setUp() {
        super.setUp()
        currentUserController = CurrentUserController_Mock()
        currentUserController.unreadCount_simulated = initialUnreadCount
        cancellables = []
    }

    override func tearDown() {
        // Release existing subscriptions and make sure the controller gets released, too
        cancellables = nil
        AssertAsync.canBeReleased(&currentUserController)
        currentUserController = nil
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
        weak var controller: CurrentUserController_Mock? = currentUserController
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
        weak var controller: CurrentUserController_Mock? = currentUserController
        currentUserController = nil

        let newUnreadCount: UnreadCount = .dummy
        controller?.unreadCount_simulated = newUnreadCount
        controller?.delegateCallback {
            $0.currentUserController(controller!, didChangeCurrentUserUnreadCount: newUnreadCount)
        }

        XCTAssertEqual(recording.output, [initialUnreadCount, newUnreadCount])
    }
}
