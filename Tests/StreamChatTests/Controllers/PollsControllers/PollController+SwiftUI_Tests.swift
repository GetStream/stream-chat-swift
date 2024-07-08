//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class PollController_SwiftUI_Tests: iOS13TestCase {
    var pollController: PollController_Mock!

    var client: ChatClient_Mock!
    var messageId: MessageId!
    var pollId: String!

    override func setUp() {
        super.setUp()
        messageId = .unique
        pollId = .unique
        client = ChatClient_Mock.mock
        pollController = PollController_Mock(client: client, messageId: messageId, pollId: pollId)
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&pollController)
        pollController = nil
        super.tearDown()
    }

    func test_controllerInitialValuesAreLoaded() {
        let observableObject = pollController.observableObject

        XCTAssertEqual(observableObject.state, .initialized)
        XCTAssertEqual(observableObject.poll, nil)
        XCTAssertEqual(observableObject.ownVotes, [])
    }

    func test_observableObject_reactsToDelegateUpdatePollCallback() {
        let observableObject = pollController.observableObject

        // Simulate poll creation
        let newPoll: Poll = .unique
        pollController.poll_simulated = newPoll

        pollController.delegateCallback {
            $0.pollController(self.pollController, didUpdatePoll: .create(newPoll))
        }

        AssertAsync.willBeEqual(observableObject.poll, newPoll)
    }

    func test_observableObject_reactsToDelegateOwnVotesChangesCallback() {
        let observableObject = pollController.observableObject

        // Simulate own vote.
        let ownVote: PollVote = .unique
        pollController.ownVotes_simulated = [ownVote]
        pollController.delegateCallback {
            $0.pollController(
                self.pollController,
                didUpdateCurrentUserVotes: [.insert(ownVote, index: .init())]
            )
        }

        AssertAsync.willBeEqual(Array(observableObject.ownVotes), [ownVote])
    }

    func test_observableObject_reactsToDelegateStateChangesCallback() {
        let observableObject = pollController.observableObject
        // Simulate state change
        let newState: DataController.State = .remoteDataFetchFailed(ClientError(with: TestError()))
        pollController.state_simulated = newState
        pollController.delegateCallback {
            $0.controller(
                self.pollController,
                didChangeState: newState
            )
        }

        AssertAsync.willBeEqual(observableObject.state, newState)
    }
}
