//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13, *)
final class MemberController_SwiftUI_Tests: iOS13TestCase {
    var memberController: ChatChannelMemberController!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        memberController = .init(userId: .unique, cid: .unique, client: .mock)
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&memberController)
        memberController = nil
        
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func test_controllerInitialValuesAreLoaded() {
        // Get an observable wrapper.
        let observableObject = memberController.observableObject
        
        // Assert wrapper's fields are up-to-date.
        XCTAssertEqual(observableObject.state, memberController.state)
        XCTAssertEqual(observableObject.member, memberController.member)
    }
    
    func test_observableObject_reactsToDelegateUserChangesCallback() {
        // Get an observable wrapper.
        let observableObject = memberController.observableObject

        // Simulate member change.
        let newMember: ChatChannelMember = .dummy
        memberController.delegateCallback {
            $0.memberController(
                self.memberController,
                didUpdateMember: .create(newMember)
            )
        }
        
        // Assert the item is received.
        AssertAsync.willBeEqual(observableObject.member, newMember)
    }
    
    func test_observableObject_reactsToDelegateStateChangesCallback() {
        // Get an observable wrapper.
        let observableObject = memberController.observableObject
        
        // Simulate state change.
        let newState: DataController.State = .remoteDataFetchFailed(ClientError(with: TestError()))
        memberController.delegateCallback {
            $0.controller(
                self.memberController,
                didChangeState: newState
            )
        }
        
        // Assert the state is received.
        AssertAsync.willBeEqual(observableObject.state, newState)
    }
}
