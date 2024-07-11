//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class PollController_Combine_Tests: iOS13TestCase {
    var pollController: PollController!
    var cancellables: Set<AnyCancellable>!
    var client: ChatClient_Mock!
    var messageId: MessageId!
    var pollId: String!

    override func setUp() {
        super.setUp()
        messageId = .unique
        pollId = .unique
        client = ChatClient_Mock.mock
        pollController = PollController(client: client, messageId: messageId, pollId: pollId)
        cancellables = []
    }

    override func tearDown() {
        // Release existing subscriptions and make sure the controller gets released, too
        cancellables = nil
        AssertAsync.canBeReleased(&pollController)
        pollController = nil
        super.tearDown()
    }

    func test_statePublisher() {
        // Setup Recording publishers
        var recording = Record<DataController.State, Never>.Recording()

        // Setup the chain
        pollController
            .statePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)

        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: PollController? = pollController
        pollController = nil

        controller?.delegateCallback { $0.controller(controller!, didChangeState: .remoteDataFetched) }

        AssertAsync.willBeEqual(recording.output, [.initialized, .remoteDataFetched])
    }

    func test_pollChangesChangePublisher() {
        // Setup Recording publishers
        var recording = Record<EntityChange<Poll>, Never>.Recording()

        // Setup the chain
        pollController
            .pollChangesPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)

        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: PollController? = pollController
        pollController = nil

        let poll: Poll = .unique
        controller?.delegateCallback {
            $0.pollController(controller!, didUpdatePoll: .create(poll))
        }

        XCTAssertEqual(recording.output, [.create(poll)])
    }
    
    func test_currentUserVotesChangePublisher() {
        // Setup Recording publishers
        var recording = Record<[ListChange<PollVote>], Never>.Recording()

        // Setup the chain
        pollController
            .currentUserVotesChanges
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)

        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: PollController? = pollController
        pollController = nil

        let pollVote = PollVote(
            id: "123",
            createdAt: Date(),
            updatedAt: Date(),
            pollId: "123",
            optionId: nil,
            isAnswer: false,
            answerText: nil,
            user: .unique
        )
        controller?.delegateCallback {
            $0.pollController(
                controller!,
                didUpdateCurrentUserVotes: [.insert(pollVote, index: IndexPath(row: 0, section: 0))]
            )
        }

        XCTAssertEqual(recording.output, [[.insert(pollVote, index: IndexPath(row: 0, section: 0))]])
    }
}
