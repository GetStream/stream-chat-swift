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
    
    func test_startUpdatingIsCalled_whenObservableObjectCreated() {
        assert(messageController.startUpdating_called == false)
        _ = messageController.observableObject
        XCTAssertTrue(messageController.startUpdating_called)
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
        let newMessage: Message = .unique
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
        let newState: Controller.State = .remoteDataFetchFailed(ClientError(with: TestError()))
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

class MessageControllerMock: MessageController {
    @Atomic var startUpdating_called = false
    
    var message_simulated: Message?
    override var message: Message? {
        message_simulated ?? super.message
    }

    var state_simulated: Controller.State?
    override var state: Controller.State {
        get { state_simulated ?? super.state }
        set { super.state = newValue }
    }
    
    init() {
        super.init(client: .mock, cid: .unique, messageId: .unique)
    }

    override func startUpdating(_ completion: ((Error?) -> Void)? = nil) {
        startUpdating_called = true
    }
}
