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
        var recording = Record<[ListChange<ChatMessage>], Never>.Recording()
        
        // Setup the chain
        channelController
            .messagesChangesPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChannelControllerMock? = channelController
        channelController = nil

        let newMessage: ChatMessage = .unique
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
    
    func test_typingUsersPublisher() {
        // Setup Recording publishers
        var recording = Record<Set<ChatUser>, Never>.Recording()
        
        // Setup the chain
        channelController
            .typingUsersPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChannelControllerMock? = channelController
        channelController = nil

        let typingUser = ChatUser(
            id: .unique,
            name: .unique,
            imageURL: .unique(),
            isOnline: true,
            isBanned: false,
            isFlaggedByCurrentUser: false,
            userRole: .user,
            createdAt: .unique,
            updatedAt: .unique,
            lastActiveAt: .unique,
            teams: [],
            extraData: .defaultValue
        )
        
        controller?.delegateCallback {
            $0.channelController(controller!, didChangeTypingUsers: [typingUser])
        }
        
        XCTAssertEqual(recording.output, [[typingUser]])
    }
}
