//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class PollVoteListController_SwiftUI_Tests: iOS13TestCase {
    var voteListController: PollVoteListController_Mock!

    var client: ChatClient_Mock!
    var optionId: String!
    var pollId: String!

    override func setUp() {
        super.setUp()
        optionId = .unique
        pollId = .unique
        client = ChatClient_Mock.mock
        voteListController = PollVoteListController_Mock(
            query: .init(pollId: pollId, optionId: optionId),
            client: client
        )
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&voteListController)
        voteListController = nil
        super.tearDown()
    }

    func test_controllerInitialValuesAreLoaded() {
        let observableObject = voteListController.observableObject

        XCTAssertEqual(observableObject.state, .localDataFetched)
        XCTAssertEqual(observableObject.votes, [])
    }

    func test_observableObject_reactsToDelegateUpdateVotesCallback() {
        let observableObject = voteListController.observableObject

        // Simulate poll vote creation
        let pollVote: PollVote = .unique
        let votes = LazyCachedMapCollection([pollVote])
        voteListController.votes_simulated = votes

        voteListController.delegateCallback {
            $0.controller(self.voteListController, didChangeVotes: [.insert(pollVote, index: .init())])
        }

        AssertAsync.willBeEqual(observableObject.votes, votes)
    }

    func test_observableObject_reactsToDelegateStateChangesCallback() {
        let observableObject = voteListController.observableObject
        // Simulate state change
        let newState: DataController.State = .remoteDataFetchFailed(ClientError(with: TestError()))
        voteListController.state_simulated = newState
        voteListController.delegateCallback {
            $0.controller(
                self.voteListController,
                didChangeState: newState
            )
        }

        AssertAsync.willBeEqual(observableObject.state, newState)
    }
}
