//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13, *)
final class UserController_Combine_Tests: iOS13TestCase {
    var userController: ChatUserController!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup

    override func setUp() {
        super.setUp()
        
        userController = ChatUserController(userId: .unique, client: .mock)
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        userController = nil
        
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func test_statePublisher() {
        // Setup recording.
        var recording = Record<DataController.State, Never>.Recording()
                
        // Setup the chain.
        userController
            .statePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChatUserController? = userController
        userController = nil
        
        // Simulate delegate invocation.
        controller?.delegateCallback { $0.controller(controller!, didChangeState: .remoteDataFetched) }
        
        // Assert all state changes are delivered.
        XCTAssertEqual(recording.output, [.localDataFetched, .remoteDataFetched])
    }

    func test_userChangePublisher() {
        // Setup recording.
        var recording = Record<EntityChange<ChatUser>, Never>.Recording()
        
        // Setup the chain.
        userController
            .userChangePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChatUserController? = userController
        userController = nil

        // Simulate delegate invocation with the new user.
        let newUser: ChatUser = .unique
        controller?.delegateCallback {
            $0.userController(controller!, didUpdateUser: .create(newUser))
        }
        
        // Assert user change is delivered.
        XCTAssertEqual(recording.output, [.create(newUser)])
    }
}
