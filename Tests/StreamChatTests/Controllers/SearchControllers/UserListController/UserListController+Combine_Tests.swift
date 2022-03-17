//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13, *)
final class UserListController_Combine_Tests: iOS13TestCase {
    var userListController: UserListControllerMock!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        userListController = UserListControllerMock()
        cancellables = []
    }
    
    override func tearDown() {
        // Release existing subscriptions and make sure the controller gets released, too
        cancellables = nil
        userListController = nil
        super.tearDown()
    }
    
    func test_statePublisher() {
        // Setup Recording publishers
        var recording = Record<DataController.State, Never>.Recording()
        
        // Setup the chain
        userListController
            .statePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: UserListControllerMock? = userListController
        userListController = nil
        
        controller?.delegateCallback { $0.controller(controller!, didChangeState: .remoteDataFetched) }
        
        XCTAssertEqual(recording.output, [.localDataFetched, .remoteDataFetched])
    }

    func test_usersChangesPublisher() {
        // Setup Recording publishers
        var recording = Record<[ListChange<ChatUser>], Never>.Recording()
        
        // Setup the chain
        userListController
            .usersChangesPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: UserListControllerMock? = userListController
        userListController = nil

        let newUser: ChatUser = .unique
        controller?.users_simulated = [newUser]
        controller?.delegateCallback {
            $0.controller(controller!, didChangeUsers: [.insert(newUser, index: [0, 1])])
        }
        
        XCTAssertEqual(recording.output, [[.insert(newUser, index: [0, 1])]])
    }
}
