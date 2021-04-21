//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
@testable import StreamChat
import XCTest

@available(iOS 13, *)
class ChannelController_Combine_Tests: iOS13TestCase {
    var channelController: ChannelControllerMock!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        channelController = ChannelControllerMock()
        cancellables = []
    }
    
    override func tearDown() {
        // Release existing subscriptions and make sure the controller gets released, too
        cancellables = nil
        AssertAsync.canBeReleased(&channelController)
        super.tearDown()
    }
    
    func test_statePublisher() {
        // Setup Recording publishers
        var recording = Record<DataController.State, Never>.Recording()
                
        // Setup the chain
        channelController
            .statePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChannelControllerMock? = channelController
        channelController = nil
        
        controller?.delegateCallback { $0.controller(controller!, didChangeState: .remoteDataFetched) }
        
        XCTAssertEqual(recording.output, [.localDataFetched, .remoteDataFetched])
    }

    func test_channelChangePublisher() {
        // Setup Recording publishers
        var recording = Record<EntityChange<ChatChannel>, Never>.Recording()
        
        // Setup the chain
        channelController
            .channelChangePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChannelControllerMock? = channelController
        channelController = nil

        let newChannel: ChatChannel = .mock(cid: .unique, name: .unique, imageURL: .unique(), extraData: .defaultValue)
        controller?.channel_simulated = newChannel
        controller?.delegateCallback {
            $0.channelController(controller!, didUpdateChannel: .create(newChannel))
        }
        
        XCTAssertEqual(recording.output, [.create(newChannel)])
    }
    
    func test_messagesChangesPublisher() {
        // Setup Recording publishers
        var recording = Record<[ListChange<_ChatMessage<NoExtraData>>], Never>.Recording()
        
        // Setup the chain
        channelController
            .messagesChangesPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChannelControllerMock? = channelController
        channelController = nil

        let newMessage: _ChatMessage = .unique
        controller?.messages_simulated = [newMessage]
        controller?.delegateCallback {
            $0.channelController(controller!, didUpdateMessages: [.insert(newMessage, index: .init())])
        }
        
        XCTAssertEqual(recording.output, [[.insert(newMessage, index: .init())]])
    }
    
    func test_memberEventPublisher() {
        // Setup Recording publishers
        var recording = Record<MemberEvent, Never>.Recording()
        
        // Setup the chain
        channelController
            .memberEventPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChannelControllerMock? = channelController
        channelController = nil

        let memberEvent: TestMemberEvent = .unique
        controller?.delegateCallback {
            $0.channelController(controller!, didReceiveMemberEvent: memberEvent)
        }
        
        XCTAssertEqual(recording.output as! [TestMemberEvent], [memberEvent])
    }
    
    func test_typingMembersPublisher() {
        // Setup Recording publishers
        var recording = Record<Set<ChatChannelMember>, Never>.Recording()
        
        // Setup the chain
        channelController
            .typingMembersPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChannelControllerMock? = channelController
        channelController = nil

        let typingMember = ChatChannelMember(
            id: .unique,
            name: .unique,
            imageURL: .unique(),
            isOnline: true,
            isBanned: false,
            isFlaggedByCurrentUser: false,
            userRole: .user,
            userCreatedAt: .unique,
            userUpdatedAt: .unique,
            lastActiveAt: .unique,
            teams: [],
            extraData: .defaultValue,
            memberRole: .member,
            memberCreatedAt: .unique,
            memberUpdatedAt: .unique,
            isInvited: false,
            inviteAcceptedAt: nil,
            inviteRejectedAt: nil,
            isBannedFromChannel: true,
            banExpiresAt: .unique,
            isShadowBannedFromChannel: true
        )
        
        controller?.delegateCallback {
            $0.channelController(controller!, didChangeTypingMembers: [typingMember])
        }
        
        XCTAssertEqual(recording.output, [[typingMember]])
    }
}
