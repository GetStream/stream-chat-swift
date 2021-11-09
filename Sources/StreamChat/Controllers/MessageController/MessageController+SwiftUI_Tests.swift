//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13, *)
class MessageController_SwiftUI_Tests: iOS13TestCase {
    var messageController: ChatMessageController_Mock!
    
    override func setUp() {
        super.setUp()
        messageController = ChatMessageController_Mock.mock()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&messageController)
        super.tearDown()
    }
    
    func test_controllerInitialValuesAreLoaded() {
        messageController.state_mock = .localDataFetched
        messageController.message_mock = .unique
        messageController.replies_mock = [.unique]
        
        let observableObject = messageController.observableObject
        
        XCTAssertEqual(observableObject.state, messageController.state)
        XCTAssertEqual(observableObject.message, messageController.message)
        XCTAssertEqual(observableObject.replies, messageController.replies)
    }
    
    func test_observableObject_reactsToDelegateMessageChangeCallback() {
        let observableObject = messageController.observableObject
        
        // Simulate message change
        let newMessage: ChatMessage = .unique
        messageController.message_mock = newMessage
        messageController.delegateCallback {
            $0.messageController(
                self.messageController,
                didChangeMessage: .create(newMessage)
            )
        }
        
        AssertAsync.willBeEqual(observableObject.message, newMessage)
    }
    
    func test_observableObject_reactsToDelegateRepliesChangesCallback() {
        let observableObject = messageController.observableObject
        
        // Simulate replies changes
        let newReply: ChatMessage = .unique
        messageController.replies_mock = [newReply]
        messageController.delegateCallback {
            $0.messageController(
                self.messageController,
                didChangeReplies: [.insert(newReply, index: .init())]
            )
        }
        
        AssertAsync.willBeEqual(Array(observableObject.replies), [newReply])
    }

    func test_observableObject_reactsToDelegateReactionsChangesCallback() {
        let observableObject = messageController.observableObject

        let newReaction: ChatMessageReaction = .init(
            type: "likes",
            score: 3,
            createdAt: .unique,
            updatedAt: .unique,
            author: .unique,
            extraData: [:]
        )

        messageController.reactions = [newReaction]
        messageController.delegateCallback {
            $0.messageController(
                self.messageController,
                didChangeReactions: [newReaction]
            )
        }

        AssertAsync.willBeEqual(Array(observableObject.reactions), [newReaction])
    }
    
    func test_observableObject_reactsToDelegateStateChangesCallback() {
        let observableObject = messageController.observableObject
        // Simulate state change
        let newState: DataController.State = .remoteDataFetchFailed(ClientError(with: TestError()))
        messageController.state_mock = newState
        messageController.delegateCallback {
            $0.controller(
                self.messageController,
                didChangeState: newState
            )
        }
        
        AssertAsync.willBeEqual(observableObject.state, newState)
    }
}
