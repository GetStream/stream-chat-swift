//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
@testable import StreamChatClient
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
    
    func test_startUpdatingIsCalled_whenPublisherIsAccessed() {
        assert(messageController.startUpdating_called == false)
        _ = messageController.statePublisher
        XCTAssertTrue(messageController.startUpdating_called)
    }
    
    func test_statePublisher() {
        // Setup Recording publishers
        var recording = Record<Controller.State, Never>.Recording()
        
        // Setup the chain
        messageController
            .statePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: MessageControllerMock? = messageController
        messageController = nil
        
        controller?.delegateCallback { $0.controller(controller!, didChangeState: .localDataFetched) }
        controller?.delegateCallback { $0.controller(controller!, didChangeState: .remoteDataFetched) }
        
        XCTAssertEqual(recording.output, [.inactive, .localDataFetched, .remoteDataFetched])
    }

    func test_messageChangePublisher() {
        // Setup Recording publishers
        var recording = Record<EntityChange<Message>, Never>.Recording()
        
        // Setup the chain
        messageController
            .messageChangePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: MessageControllerMock? = messageController
        messageController = nil

        let newMessage: Message = .unique
        controller?.message_simulated = newMessage
        controller?.delegateCallback {
            $0.messageController(controller!, didChangeMessage: .create(newMessage))
        }
        
        XCTAssertEqual(recording.output, [.create(newMessage)])
    }
}
