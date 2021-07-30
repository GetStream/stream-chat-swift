//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
@testable import StreamChat
import XCTest

@available(iOS 13, *)
class MessageController_Combine_Tests: iOS13TestCase {
    var messageController: MessageControllerMock!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        messageController = MessageControllerMock()
        cancellables = []
    }
    
    override func tearDown() {
        // Release existing subscriptions and make sure the controller gets released, too
        cancellables = nil
        AssertAsync.canBeReleased(&messageController)
        super.tearDown()
    }
    
    func test_statePublisher() {
        // Setup Recording publishers
        var recording = Record<DataController.State, Never>.Recording()
        
        // Setup the chain
        messageController
            .statePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: MessageControllerMock? = messageController
        messageController = nil
        
        controller?.delegateCallback { $0.controller(controller!, didChangeState: .remoteDataFetched) }
        
        AssertAsync.willBeEqual(recording.output, [.localDataFetched, .remoteDataFetched])
    }

    func test_messageChangePublisher() {
        // Setup Recording publishers
        var recording = Record<EntityChange<ChatMessage>, Never>.Recording()
        
        // Setup the chain
        messageController
            .messageChangePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: MessageControllerMock? = messageController
        messageController = nil

        let newMessage: ChatMessage = .unique
        controller?.message_simulated = newMessage
        controller?.delegateCallback {
            $0.messageController(controller!, didChangeMessage: .create(newMessage))
        }
        
        XCTAssertEqual(recording.output, [.create(newMessage)])
    }
    
    func test_repliesChangesPublisher() {
        // Setup Recording publishers
        var recording = Record<[ListChange<ChatMessage>], Never>.Recording()
        
        // Setup the chain
        messageController
            .repliesChangesPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: MessageControllerMock? = messageController
        messageController = nil

        let newReply: ChatMessage = .unique
        controller?.replies_simulated = [newReply]
        controller?.delegateCallback {
            $0.messageController(controller!, didChangeReplies: [.insert(newReply, index: .init())])
        }
        
        XCTAssertEqual(recording.output, [[.insert(newReply, index: .init())]])
    }
}
