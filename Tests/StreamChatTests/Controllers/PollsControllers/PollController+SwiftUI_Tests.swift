//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13, *)
final class PollController_SwiftUI_Tests: iOS13TestCase {
    var pollController: PollController!

    var client: ChatClient_Mock!
    var messageId: MessageId!
    var pollId: String!

    override func setUp() {
        super.setUp()
        messageId = .unique
        pollId = .unique
        client = ChatClient_Mock.mock
        pollController = PollController(client: client, messageId: messageId, pollId: pollId)
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&pollController)
        pollController = nil
        super.tearDown()
    }

    func test_controllerInitialValuesAreLoaded() {
        let observableObject = pollController.observableObject

        XCTAssertEqual(observableObject.state, .localDataFetched)
        XCTAssertEqual(observableObject.poll, nil)
        XCTAssertEqual(observableObject.ownVotes, [])
    }

//    func test_observableObject_reactsToDelegateMessageChangeCallback() {
//        let observableObject = pollController.observableObject
//
//        // Simulate poll creation
//        let newPoll: Poll = .unique
//
//        pollController.delegateCallback {
//            $0.pollController(self.pollController, didUpdatePoll: .create(newPoll))
//        }
//
//        AssertAsync.willBeEqual(observableObject.poll, newPoll)
//    }

//    func test_observableObject_reactsToDelegateRepliesChangesCallback() {
//        let observableObject = messageController.observableObject
//
//        // Simulate replies changes
//        let newReply: ChatMessage = .unique
//        messageController.replies_mock = [newReply]
//        messageController.delegateCallback {
//            $0.messageController(
//                self.messageController,
//                didChangeReplies: [.insert(newReply, index: .init())]
//            )
//        }
//
//        AssertAsync.willBeEqual(Array(observableObject.replies), [newReply])
//    }
//
//    func test_observableObject_reactsToDelegateReactionsChangesCallback() {
//        let observableObject = messageController.observableObject
//
//        let newReaction: ChatMessageReaction = .init(
//            type: "likes",
//            score: 3,
//            createdAt: .unique,
//            updatedAt: .unique,
//            author: .unique,
//            extraData: [:]
//        )
//
//        messageController.reactions = [newReaction]
//        messageController.delegateCallback {
//            $0.messageController(
//                self.messageController,
//                didChangeReactions: [newReaction]
//            )
//        }
//
//        AssertAsync.willBeEqual(Array(observableObject.reactions), [newReaction])
//    }
//
//    func test_observableObject_reactsToDelegateStateChangesCallback() {
//        let observableObject = messageController.observableObject
//        // Simulate state change
//        let newState: DataController.State = .remoteDataFetchFailed(ClientError(with: TestError()))
//        messageController.state_mock = newState
//        messageController.delegateCallback {
//            $0.controller(
//                self.messageController,
//                didChangeState: newState
//            )
//        }
//
//        AssertAsync.willBeEqual(observableObject.state, newState)
//    }
}
