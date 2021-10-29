//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

@available(iOS 13, *)
class MessageController_SwiftUI_Tests: iOS13TestCase {
    var messageController: MessageControllerMock!
    
    override func setUp() {
        super.setUp()
        messageController = MessageControllerMock()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&messageController)
        super.tearDown()
    }
    
    func test_controllerInitialValuesAreLoaded() {
        messageController.state_simulated = .localDataFetched
        messageController.message_simulated = .unique
        messageController.replies_simulated = [.unique]
        
        let observableObject = messageController.observableObject
        
        XCTAssertEqual(observableObject.state, messageController.state)
        XCTAssertEqual(observableObject.message, messageController.message)
        XCTAssertEqual(observableObject.replies, messageController.replies)
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
    
    func test_observableObject_reactsToDelegateRepliesChangesCallback() {
        let observableObject = messageController.observableObject
        
        // Simulate replies changes
        let newReply: ChatMessage = .unique
        messageController.replies_simulated = [newReply]
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

        messageController.reactions_simulated = [newReaction]
        messageController.delegateCallback {
            $0.messageController(
                self.messageController,
                didChangeReactions: [.insert(newReaction, index: .init())]
            )
        }

        AssertAsync.willBeEqual(Array(observableObject.reactions), [newReaction])
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
    
    var replies_simulated: [ChatMessage]?
    override var replies: LazyCachedMapCollection<ChatMessage> {
        replies_simulated.map { $0.lazyCachedMap { $0 } } ?? super.replies
    }

    var reactions_simulated: [ChatMessageReaction]?
    override var reactions: LazyCachedMapCollection<ChatMessageReaction> {
        reactions_simulated.map { $0.lazyCachedMap { $0 } } ?? super.reactions
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
