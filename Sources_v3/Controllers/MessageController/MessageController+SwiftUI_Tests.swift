//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

@available(iOS 13, *)
class MessageController_SwiftUI_Tests: iOS13TestCase {
    var messageController: MessageControllerMock!
    
    override func setUp() {
        super.setUp()
        messageController = MessageControllerMock()
    }
    
    func test_controllerInitialValuesAreLoaded() {
        messageController.state_simulated = .localDataFetched
        messageController.message_simulated = .unique
        
        let observableObject = messageController.observableObject
        
        XCTAssertEqual(observableObject.state, messageController.state)
        XCTAssertEqual(observableObject.message, messageController.message)
    }
    
    func test_observableObject_reactsToDelegateMessageChangeCallback() {
        let observableObject = messageController.observableObject
        
        // Simulate message change
        let newMessage: ChatMessage = .unique
        messageController.message_simulated = newMessage
        messageController.delegateCallback {
            $0.messageController(
                self.messageController,
                didChangeMessage: .create(newMessage)
            )
        }
        
        AssertAsync.willBeEqual(observableObject.message, newMessage)
    }
    
    func test_observableObject_reactsToDelegateStateChangesCallback() {
        let observableObject = messageController.observableObject
        // Simulate state change
        let newState: DataController.State = .remoteDataFetchFailed(ClientError(with: TestError()))
        messageController.state_simulated = newState
        messageController.delegateCallback {
            $0.controller(
                self.messageController,
                didChangeState: newState
            )
        }
        
        AssertAsync.willBeEqual(observableObject.state, newState)
    }
}

class MessageControllerMock: ChatMessageController {
    @Atomic var synchronize_called = false
    
    var message_simulated: ChatMessage?
    override var message: ChatMessage? {
        message_simulated ?? super.message
    }

    var state_simulated: DataController.State?
    override var state: DataController.State {
        get { state_simulated ?? super.state }
        set { super.state = newValue }
    }
    
    init() {
        super.init(client: .mock, cid: .unique, messageId: .unique)
    }

    override func synchronize(_ completion: ((Error?) -> Void)? = nil) {
        synchronize_called = true
    }
}
