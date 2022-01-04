//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

@available(iOS 13, *)
final class MemberListController_SwiftUI_Tests: iOS13TestCase {
    var query: ChannelMemberListQuery!
    var memberListController: ChatChannelMemberListControllerMock!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        query = .init(cid: .unique)
        memberListController = .init(query: query, client: .mock)
    }
    
    override func tearDown() {
        query = nil
        AssertAsync.canBeReleased(&memberListController)
        
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func test_controllerInitialValuesAreLoaded() {
        // Simulate state and member list.
        memberListController.state_simulated = .localDataFetched
        memberListController.members_simulated = [.dummy, .dummy, .dummy]
        
        // Get an observable object.
        let observableObject = memberListController.observableObject
        
        // Assert simulated values are forwarded to observable object.
        XCTAssertEqual(observableObject.state, memberListController.state)
        XCTAssertEqual(observableObject.members, memberListController.members)
    }
    
    func test_observableObject_reactsToDelegateMemberChangesCallback() {
        // Get an observable object.
        let observableObject = memberListController.observableObject
        
        // Simulate member change.
        let newMember: ChatChannelMember = .dummy
        memberListController.members_simulated = [newMember]
        memberListController.delegateCallback {
            $0.memberListController(
                self.memberListController,
                didChangeMembers: [.insert(newMember, index: [0, 0])]
            )
        }
        
        // Simulate the changes are forwarded to observable object.
        AssertAsync.willBeEqual(Array(observableObject.members), [newMember])
    }
    
    func test_observableObject_reactsToDelegateStateChangesCallback() {
        // Get an observable object.
        let observableObject = memberListController.observableObject
        
        // Simulate state change.
        let newState: DataController.State = .remoteDataFetchFailed(ClientError(with: TestError()))
        memberListController.state_simulated = newState
        memberListController.delegateCallback {
            $0.controller(
                self.memberListController,
                didChangeState: newState
            )
        }
        
        // Simulate the updated state is forwarded to observable object.
        AssertAsync.willBeEqual(observableObject.state, newState)
    }
}
