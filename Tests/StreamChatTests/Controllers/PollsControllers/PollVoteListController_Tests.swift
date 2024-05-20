//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class PollVoteListController_Tests: XCTestCase {
    fileprivate var env: PollVoteListController.Environment!

    var client: ChatClient_Mock!

    var optionId: String!
    var pollId: String!
    
    var query: PollVoteListQuery!
    
    var currentUserId: UserId!

    var controller: PollVoteListController!
    var controllerCallbackQueueID: UUID!
    /// Workaround for unwrapping **controllerCallbackQueueID!** in each closure that captures it
    private var callbackQueueID: UUID { controllerCallbackQueueID }

    override func setUp() {
        super.setUp()

        env = PollVoteListController.Environment()
        client = ChatClient.mock
        optionId = .unique
        pollId = .unique
        currentUserId = .unique
        
        query = PollVoteListQuery(pollId: pollId, optionId: optionId)
        controller = PollVoteListController(
            query: query,
            client: client,
            environment: env
        )
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }

    override func tearDown() {
        env = nil

        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
        }

        pollId = nil
        optionId = nil
        controllerCallbackQueueID = nil

        super.tearDown()
    }
    
    // MARK: - Controller
    
    func test_controllerIsCreatedCorrectly() {
        let controller = client.pollVoteListController(query: query)

        // Assert controller has correct `pollId`
        XCTAssertEqual(controller.query.pollId, pollId)
        // Assert controller has correct `optionId`
        XCTAssertEqual(controller.query.optionId, optionId)
    }

    func test_initialState() {
        // Assert client is assigned correctly
        XCTAssertTrue(controller.client === client)

        // Assert initial state is correct
        XCTAssertEqual(controller.state, .initialized)

        // Assert message is nil
        XCTAssertEqual(controller.votes, [])
    }
    
    // MARK: - Synchronize

    func test_synchronize_forwardsUpdaterError() throws {
        // Simulate `synchronize` call
        var completionError: Error?
        controller.synchronize {
            completionError = $0
        }

        // Simulate network response with the error
        let networkError = TestError()
        client.mockPollsRepository.getQueryPollVotes_completion?(.failure(networkError))
        client.mockPollsRepository.getQueryPollVotes_completion = nil

        AssertAsync {
            // Assert network error is propagated
            Assert.willBeEqual(completionError as? TestError, networkError)
            // Assert network error is propagated
            Assert.willBeEqual(self.controller.state, .remoteDataFetchFailed(ClientError(with: networkError)))
        }
    }

    func test_synchronize_changesStateCorrectly_ifNoErrorsHappen() throws {
        // Simulate `synchronize` call
        var completionError: Error?
        var completionCalled = false
        controller.synchronize {
            completionError = $0
            completionCalled = true
        }

        // Assert controller is in `localDataFetched` state
        XCTAssertEqual(controller.state, .localDataFetched)

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate network response with the error
        client.mockPollsRepository.getQueryPollVotes_completion?(.success([]))
        // Release reference of completion so we can deallocate stuff
        client.mockPollsRepository.getQueryPollVotes_completion = nil

        AssertAsync {
            // Assert completion is called
            Assert.willBeTrue(completionCalled)
            // Assert completion is called without any error
            Assert.staysTrue(completionError == nil)
        }
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_votesAreFetched_afterCallingSynchronize() throws {
        // Simulate `synchronize` call
        controller.synchronize()
        
        // Create current user in the database
        try client.databaseContainer.createCurrentUser(id: currentUserId)
        
        let user = UserPayload.dummy(userId: currentUserId)
        try client.databaseContainer.createPoll(id: pollId, createdBy: user)

        // Create votes.
        var votes = [PollVotePayload]()
        for _ in 0..<5 {
            votes.append(XCTestCase().dummyPollVotePayload(pollId: pollId, userId: user.id, user: user))
        }
        
        let response = PollVoteListResponse(duration: "", votes: votes)
        let query = controller.query
        try client.databaseContainer.writeSynchronously { session in
            try session.savePollVotes(payload: response, query: query, cache: nil)
        }

        XCTAssertEqual(controller.votes.count, votes.count)
        
        controller = nil
        client = nil
    }
    
    // MARK: - Loading votes
    
    func test_loadMoreVotes_whenFailure() {
        let exp = expectation(description: "synchronize completion")
        controller.loadMoreVotes() { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        }
        client.mockPollsRepository.getQueryPollVotes_completion?(.failure(ClientError()))

        wait(for: [exp], timeout: defaultTimeout)

        controller = nil
        client = nil
    }
    
    func test_loadMoreVotes_whenSuccess_whenMoreVotesThanLimit() {
        let exp = expectation(description: "loadVotes completion")
        controller.loadMoreVotes(limit: 2) { [weak self] _ in
            let votes = self?.controller.votes
            XCTAssertNotNil(votes)
            exp.fulfill()
        }
        
        client.mockPollsRepository.getQueryPollVotes_completion?(.success([
            .unique,
            .unique
        ]))

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertFalse(controller.hasLoadedAllVotes)
    }
    
    func test_loadMoreVotes_whenSuccess_whenLessVotesThanLimit() {
        let exp = expectation(description: "loadVotes completion")
        controller.loadMoreVotes(limit: 5) { [weak self] _ in
            let votes = self?.controller.votes
            XCTAssertNotNil(votes)
            exp.fulfill()
        }
        
        client.mockPollsRepository.getQueryPollVotes_completion?(.success([
            .unique,
            .unique
        ]))

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertTrue(controller.hasLoadedAllVotes)
    }
}
