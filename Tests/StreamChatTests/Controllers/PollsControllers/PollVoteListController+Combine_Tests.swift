//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class PollVoteListController_Combine_Tests: iOS13TestCase {
    var voteListController: PollVoteListController!
    var cancellables: Set<AnyCancellable>!
    var client: ChatClient_Mock!
    var optionId: String!
    var pollId: String!

    override func setUp() {
        super.setUp()
        optionId = .unique
        pollId = .unique
        client = ChatClient_Mock.mock
        voteListController = PollVoteListController(
            query: .init(
                pollId: pollId,
                optionId: optionId
            ),
            client: client
        )
        cancellables = []
    }

    override func tearDown() {
        // Release existing subscriptions and make sure the controller gets released, too
        cancellables = nil
        AssertAsync.canBeReleased(&voteListController)
        voteListController = nil
        super.tearDown()
    }

    func test_statePublisher() {
        // Setup Recording publishers
        var recording = Record<DataController.State, Never>.Recording()

        // Setup the chain
        voteListController
            .statePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)

        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: PollVoteListController? = voteListController
        voteListController = nil

        controller?.delegateCallback { $0.controller(controller!, didChangeState: .remoteDataFetched) }

        AssertAsync.willBeEqual(recording.output, [.localDataFetched, .remoteDataFetched])
    }

    func test_voteChangesPublisher() {
        // Setup Recording publishers
        var recording = Record<[ListChange<PollVote>], Never>.Recording()

        // Setup the chain
        voteListController
            .voteChangesPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)

        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: PollVoteListController? = voteListController
        voteListController = nil

        let vote: PollVote = .unique
        let changes: [ListChange<PollVote>] = .init([.insert(vote, index: .init())])
        controller?.delegateCallback {
            $0.controller(controller!, didChangeVotes: changes)
        }

        XCTAssertEqual(recording.output, .init(arrayLiteral: [.insert(vote, index: .init())]))
    }
}
