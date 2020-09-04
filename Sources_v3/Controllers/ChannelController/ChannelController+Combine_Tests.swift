//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
@testable import StreamChatClient
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
    
    func test_startUpdatingIsCalled_whenPublisherIsAccessed() {
        assert(channelController.startUpdating_called == false)
        _ = channelController.statePublisher
        XCTAssertTrue(channelController.startUpdating_called)
    }
    
    func test_statePublisher() {
        // Setup Recording publishers
        var recording = Record<Controller.State, Never>.Recording()
        
        // Setup the chain
        channelController
            .statePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChannelControllerMock? = channelController
        channelController = nil
        
        controller?.delegateCallback { $0.controller(controller!, didChangeState: .localDataFetched) }
        controller?.delegateCallback { $0.controller(controller!, didChangeState: .remoteDataFetched) }
        
        XCTAssertEqual(recording.output, [.inactive, .localDataFetched, .remoteDataFetched])
    }

    func test_channelChangePublisher() {
        // Setup Recording publishers
        var recording = Record<EntityChange<Channel>, Never>.Recording()
        
        // Setup the chain
        channelController
            .channelChangePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChannelControllerMock? = channelController
        channelController = nil

        let newChannel: Channel = .init(cid: .unique, extraData: .defaultValue)
        controller?.channel_simulated = newChannel
        controller?.delegateCallback {
            $0.channelController(controller!, didUpdateChannel: .create(newChannel))
        }
        
        XCTAssertEqual(recording.output, [.create(newChannel)])
    }
    
    func test_messagesChangesPublisher() {
        // Setup Recording publishers
        var recording = Record<[ListChange<MessageModel<DefaultDataTypes>>], Never>.Recording()
        
        // Setup the chain
        channelController
            .messagesChangesPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChannelControllerMock? = channelController
        channelController = nil

        let newMessage: MessageModel = .unique
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
    
    func test_typingEventPublisher() {
        // Setup Recording publishers
        var recording = Record<TypingEvent, Never>.Recording()
        
        // Setup the chain
        channelController
            .typingEventPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChannelControllerMock? = channelController
        channelController = nil

        let typingEvent: TypingEvent = .unique
        controller?.delegateCallback {
            $0.channelController(controller!, didReceiveTypingEvent: typingEvent)
        }
        
        XCTAssertEqual(recording.output, [typingEvent])
    }
}
