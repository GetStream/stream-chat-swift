//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
@testable import StreamChat
import XCTest

@available(iOS 13, *)
final class MemberController_Combine_Tests: iOS13TestCase {
    var memberController: ChatChannelMemberController!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup

    override func setUp() {
        super.setUp()
        
        memberController = .init(userId: .unique, cid: .unique, client: .mock)
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        AssertAsync.canBeReleased(&memberController)
        
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func test_statePublisher() {
        // Setup recording.
        var recording = Record<DataController.State, Never>.Recording()
                
        // Setup the chain.
        memberController
            .statePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChatChannelMemberController? = memberController
        memberController = nil
        
        // Simulate delegate invocation.
        controller?.delegateCallback { $0.controller(controller!, didChangeState: .remoteDataFetched) }
        
        // Assert all state changes are delivered.
        XCTAssertEqual(recording.output, [.localDataFetched, .remoteDataFetched])
    }

    func test_memberChangePublisher() {
        // Setup recording.
        var recording = Record<EntityChange<ChatChannelMember>, Never>.Recording()
        
        // Setup the chain.
        memberController
            .memberChangePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChatChannelMemberController? = memberController
        memberController = nil

        // Simulate delegate invocation with the new member.
        let newMember: ChatChannelMember = .dummy
        controller?.delegateCallback {
            $0.memberController(controller!, didUpdateMember: .create(newMember))
        }
        
        // Assert member change is delivered.
        XCTAssertEqual(recording.output, [.create(newMember)])
    }
}

extension _ChatChannelMember {
    static var dummy: _ChatChannelMember {
        .init(
            id: .unique,
            isOnline: true,
            isBanned: false,
            userRole: .user,
            userCreatedAt: .unique,
            userUpdatedAt: .unique,
            lastActiveAt: .unique,
            extraData: .defaultValue,
            memberRole: .member,
            memberCreatedAt: .unique,
            memberUpdatedAt: .unique,
            isInvited: true,
            inviteAcceptedAt: .unique,
            inviteRejectedAt: nil
        )
    }
}
