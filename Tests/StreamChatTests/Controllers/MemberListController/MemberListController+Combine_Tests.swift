//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13, *)
final class MemberListController_Combine_Tests: iOS13TestCase {
    var memberListController: ChatChannelMemberListController!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup

    override func setUp() {
        super.setUp()
        
        memberListController = .init(query: .init(cid: .unique), client: .mock)
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        AssertAsync.canBeReleased(&memberListController)
        memberListController = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func test_statePublisher() {
        // Setup recording.
        var recording = Record<DataController.State, Never>.Recording()
                
        // Setup the chain.
        memberListController
            .statePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChatChannelMemberListController? = memberListController
        memberListController = nil
        
        // Simulate delegate invocation.
        controller?.delegateCallback { $0.controller(controller!, didChangeState: .remoteDataFetched) }
        
        // Assert all state changes are delivered.
        XCTAssertEqual(recording.output, [.localDataFetched, .remoteDataFetched])
    }

    func test_memberChangePublisher() {
        // Setup recording.
        var recording = Record<[ListChange<ChatChannelMember>], Never>.Recording()
        
        // Setup the chain.
        memberListController
            .membersChangesPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChatChannelMemberListController? = memberListController
        memberListController = nil
        
        // Simulate delegate invocation with the members change.
        let change: ListChange<ChatChannelMember> = .insert(.dummy, index: [0, 1])
        controller?.delegateCallback {
            $0.memberListController(controller!, didChangeMembers: [change])
        }
        
        // Assert members changes are delivered.
        XCTAssertEqual(recording.output.last, [change])
    }
}
