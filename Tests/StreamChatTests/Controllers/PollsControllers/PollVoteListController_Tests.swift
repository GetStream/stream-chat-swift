//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
    }

    override func tearDown() {
        env = nil

        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
        }

        pollId = nil
        optionId = nil

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
        nonisolated(unsafe) var completionError: Error?
        let expectation = expectation(description: "synchronize")
        controller.synchronize {
            completionError = $0
            expectation.fulfill()
        }

        // Simulate network response with the error
        let networkError = TestError()
        client.mockPollsRepository.getQueryPollVotes_completion?(.failure(networkError))
        client.mockPollsRepository.getQueryPollVotes_completion = nil

        wait(for: [expectation], timeout: defaultTimeout)
        
        XCTAssertEqual(completionError as? TestError, networkError)
        XCTAssertEqual(controller.state, .remoteDataFetchFailed(ClientError(with: networkError)))
    }

    func test_synchronize_changesStateCorrectly_ifNoErrorsHappen() throws {
        // Simulate `synchronize` call
        nonisolated(unsafe) var completionError: Error?
        nonisolated(unsafe) var completionCalled = false
        let expectation = expectation(description: "synchronize")
        controller.synchronize {
            completionError = $0
            completionCalled = true
            expectation.fulfill()
        }

        // Assert controller is in `localDataFetched` state
        XCTAssertEqual(controller.state, .localDataFetched)

        // Simulate network response with the error
        client.mockPollsRepository.getQueryPollVotes_completion?(.success(.init(votes: [])))
        // Release reference of completion so we can deallocate stuff
        client.mockPollsRepository.getQueryPollVotes_completion = nil

        wait(for: [expectation], timeout: defaultTimeout)
        
        XCTAssertTrue(completionCalled)
        XCTAssertNil(completionError)
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
    
    func test_loadMoreVotes_whenSuccess_whenPaginationNextNotNil() {
        let exp = expectation(description: "loadVotes completion")
        controller.loadMoreVotes(limit: 2) { [weak self] _ in
            let votes = self?.controller.votes
            XCTAssertNotNil(votes)
            exp.fulfill()
        }
        
        client.mockPollsRepository.getQueryPollVotes_completion?(
            .success(
                .init(
                    votes: [
                        .unique,
                        .unique
                    ],
                    next: "A"
                )
            )
        )

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertFalse(controller.hasLoadedAllVotes)
    }
    
    func test_loadMoreVotes_whenSuccess_whenPaginationNextNil() {
        let exp = expectation(description: "loadVotes completion")
        controller.loadMoreVotes(limit: 5) { [weak self] _ in
            let votes = self?.controller.votes
            XCTAssertNotNil(votes)
            exp.fulfill()
        }
        
        client.mockPollsRepository.getQueryPollVotes_completion?(.success(.init(votes: [
            .unique,
            .unique
        ])))

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertTrue(controller.hasLoadedAllVotes)
    }
    
    // MARK: - EventsControllerDelegate Tests
    
    func test_eventsController_didReceiveEvent_PollVoteCastedEvent_withAnswerVote() {
        // Create a vote list controller for answers (optionId = nil)
        let answerQuery = PollVoteListQuery(pollId: pollId)
        let answerController = PollVoteListController(
            query: answerQuery,
            client: client,
            environment: env
        )
        
        // Create an answer vote (isAnswer = true)
        let answerVote = PollVote.mock(
            pollId: pollId,
            optionId: nil,
            isAnswer: true,
            answerText: "Test answer"
        )
        
        let poll = Poll.unique
        let event = PollVoteCastedEvent(vote: answerVote, poll: poll, createdAt: Date())
        
        // Track link method calls
        var linkCallCount = 0
        var linkedVote: PollVote?
        var linkedQuery: PollVoteListQuery?
        
        // Mock the link method to track calls
        let originalLink = client.mockPollsRepository.link
        client.mockPollsRepository.link = { pollVote, query in
            linkCallCount += 1
            linkedVote = pollVote
            linkedQuery = query
        }
        
        // Simulate receiving the event
        answerController.didReceiveEvent(event)
        
        // Verify the vote was linked
        XCTAssertEqual(linkCallCount, 1)
        XCTAssertEqual(linkedVote?.id, answerVote.id)
        XCTAssertEqual(linkedQuery?.pollId, answerQuery.pollId)
        XCTAssertEqual(linkedQuery?.optionId, answerQuery.optionId)
        
        // Restore original method
        client.mockPollsRepository.link = originalLink
    }
    
    func test_eventsController_didReceiveEvent_PollVoteCastedEvent_withRegularVote() {
        // Create a vote list controller for a specific option
        let regularQuery = PollVoteListQuery(pollId: pollId, optionId: optionId)
        let regularController = PollVoteListController(
            query: regularQuery,
            client: client,
            environment: env
        )
        
        // Create a regular vote (isAnswer = false)
        let regularVote = PollVote.mock(
            pollId: pollId,
            optionId: optionId,
            isAnswer: false
        )
        
        let poll = Poll.unique
        let event = PollVoteCastedEvent(vote: regularVote, poll: poll, createdAt: Date())
        
        // Track link method calls
        var linkCallCount = 0
        var linkedVote: PollVote?
        var linkedQuery: PollVoteListQuery?
        
        // Mock the link method to track calls
        let originalLink = client.mockPollsRepository.link
        client.mockPollsRepository.link = { pollVote, query in
            linkCallCount += 1
            linkedVote = pollVote
            linkedQuery = query
        }
        
        // Simulate receiving the event
        regularController.didReceiveEvent(event)
        
        // Verify the vote was linked
        XCTAssertEqual(linkCallCount, 1)
        XCTAssertEqual(linkedVote?.id, regularVote.id)
        XCTAssertEqual(linkedQuery?.pollId, regularQuery.pollId)
        XCTAssertEqual(linkedQuery?.optionId, regularQuery.optionId)
        
        // Restore original method
        client.mockPollsRepository.link = originalLink
    }
    
    func test_eventsController_didReceiveEvent_PollVoteChangedEvent_withAnswerVote() {
        // Create a vote list controller for answers (optionId = nil)
        let answerQuery = PollVoteListQuery(pollId: pollId)
        let answerController = PollVoteListController(
            query: answerQuery,
            client: client,
            environment: env
        )
        
        // Create an answer vote (isAnswer = true)
        let answerVote = PollVote.mock(
            pollId: pollId,
            optionId: nil,
            isAnswer: true,
            answerText: "Updated answer"
        )
        
        let poll = Poll.unique
        let event = PollVoteChangedEvent(vote: answerVote, poll: poll, createdAt: Date())
        
        // Track link method calls
        var linkCallCount = 0
        var linkedVote: PollVote?
        var linkedQuery: PollVoteListQuery?
        
        // Mock the link method to track calls
        let originalLink = client.mockPollsRepository.link
        client.mockPollsRepository.link = { pollVote, query in
            linkCallCount += 1
            linkedVote = pollVote
            linkedQuery = query
        }
        
        // Simulate receiving the event
        answerController.didReceiveEvent(event)
        
        // Verify the vote was linked
        XCTAssertEqual(linkCallCount, 1)
        XCTAssertEqual(linkedVote?.id, answerVote.id)
        XCTAssertEqual(linkedQuery?.pollId, answerQuery.pollId)
        XCTAssertEqual(linkedQuery?.optionId, answerQuery.optionId)
        
        // Restore original method
        client.mockPollsRepository.link = originalLink
    }
    
    func test_eventsController_didReceiveEvent_PollVoteChangedEvent_withRegularVote() {
        // Create a vote list controller for a specific option
        let regularQuery = PollVoteListQuery(pollId: pollId, optionId: optionId)
        let regularController = PollVoteListController(
            query: regularQuery,
            client: client,
            environment: env
        )
        
        // Create a regular vote (isAnswer = false)
        let regularVote = PollVote.mock(
            pollId: pollId,
            optionId: optionId,
            isAnswer: false
        )
        
        let poll = Poll.unique
        let event = PollVoteChangedEvent(vote: regularVote, poll: poll, createdAt: Date())
        
        // Track link method calls
        var linkCallCount = 0
        var linkedVote: PollVote?
        var linkedQuery: PollVoteListQuery?
        
        // Mock the link method to track calls
        let originalLink = client.mockPollsRepository.link
        client.mockPollsRepository.link = { pollVote, query in
            linkCallCount += 1
            linkedVote = pollVote
            linkedQuery = query
        }
        
        // Simulate receiving the event
        regularController.didReceiveEvent(event)
        
        // Verify the vote was linked
        XCTAssertEqual(linkCallCount, 1)
        XCTAssertEqual(linkedVote?.id, regularVote.id)
        XCTAssertEqual(linkedQuery?.pollId, regularQuery.pollId)
        XCTAssertEqual(linkedQuery?.optionId, regularQuery.optionId)
        
        // Restore original method
        client.mockPollsRepository.link = originalLink
    }
    
    func test_eventsController_didReceiveEvent_ignoresVotesWithDifferentPollId() {
        // Create a vote list controller
        let controller = PollVoteListController(
            query: query,
            client: client,
            environment: env
        )
        
        // Create a vote with different poll ID
        let differentPollId = String.unique
        let vote = PollVote.mock(
            pollId: differentPollId,
            optionId: optionId,
            isAnswer: false
        )
        
        let poll = Poll.unique
        let event = PollVoteCastedEvent(vote: vote, poll: poll, createdAt: Date())
        
        // Track link method calls
        var linkCallCount = 0
        
        // Mock the link method to track calls
        let originalLink = client.mockPollsRepository.link
        client.mockPollsRepository.link = { _, _ in
            linkCallCount += 1
        }
        
        // Simulate receiving the event
        controller.didReceiveEvent(event)
        
        // Verify the vote was NOT linked due to different poll ID
        XCTAssertEqual(linkCallCount, 0)
        
        // Restore original method
        client.mockPollsRepository.link = originalLink
    }
    
    func test_eventsController_didReceiveEvent_ignoresAnswerVotesWhenOptionIdIsSet() {
        // Create a vote list controller for a specific option
        let regularQuery = PollVoteListController(
            query: query,
            client: client,
            environment: env
        )
        
        // Create an answer vote (isAnswer = true) but controller is for specific option
        let answerVote = PollVote.mock(
            pollId: pollId,
            optionId: nil,
            isAnswer: true,
            answerText: "Test answer"
        )
        
        let poll = Poll.unique
        let event = PollVoteCastedEvent(vote: answerVote, poll: poll, createdAt: Date())
        
        // Track link method calls
        var linkCallCount = 0
        
        // Mock the link method to track calls
        let originalLink = client.mockPollsRepository.link
        client.mockPollsRepository.link = { _, _ in
            linkCallCount += 1
        }
        
        // Simulate receiving the event
        regularQuery.didReceiveEvent(event)
        
        // Verify the vote was NOT linked because answer votes should only be linked when optionId is nil
        XCTAssertEqual(linkCallCount, 0)
        
        // Restore original method
        client.mockPollsRepository.link = originalLink
    }
    
    func test_eventsController_didReceiveEvent_ignoresRegularVotesWhenOptionIdDoesNotMatch() {
        // Create a vote list controller for a specific option
        let controller = PollVoteListController(
            query: query,
            client: client,
            environment: env
        )
        
        // Create a regular vote with different option ID
        let differentOptionId = String.unique
        let vote = PollVote.mock(
            pollId: pollId,
            optionId: differentOptionId,
            isAnswer: false
        )
        
        let poll = Poll.unique
        let event = PollVoteCastedEvent(vote: vote, poll: poll, createdAt: Date())
        
        // Track link method calls
        var linkCallCount = 0
        
        // Mock the link method to track calls
        let originalLink = client.mockPollsRepository.link
        client.mockPollsRepository.link = { _, _ in
            linkCallCount += 1
        }
        
        // Simulate receiving the event
        controller.didReceiveEvent(event)
        
        // Verify the vote was NOT linked because option IDs don't match
        XCTAssertEqual(linkCallCount, 0)
        
        // Restore original method
        client.mockPollsRepository.link = originalLink
    }
    
    // MARK: - Poll Observer Tests
    
    func test_pollProperty_returnsPollFromObserver() {
        // Create a poll in the database
        let user = UserPayload.dummy(userId: currentUserId)
        let poll = dummyPollPayload(id: pollId, user: user)

        try! client.databaseContainer.writeSynchronously { session in
            try session.savePoll(payload: poll, cache: nil)
        }
        
        // Synchronize to start observers
        controller.synchronize()
        
        // Verify poll is returned
        XCTAssertNotNil(controller.poll)
        XCTAssertEqual(controller.poll?.id, pollId)
    }
    
    func test_pollProperty_returnsNilWhenNoPollExists() {
        // Don't create any poll in database
        controller.synchronize()
        
        // Verify poll is nil
        XCTAssertNil(controller.poll)
    }
    
    @MainActor func test_pollObserver_notifiesDelegateOnPollUpdate() {
        // Create initial poll
        let user = UserPayload.dummy(userId: currentUserId)
        let initialPoll = dummyPollPayload(id: pollId, user: user)

        try! client.databaseContainer.writeSynchronously { session in
            try session.savePoll(payload: initialPoll, cache: nil)
        }

        // Set up delegate
        let delegate = TestDelegate()
        controller.delegate = delegate

        // Wait for expection
        let exp = expectation(description: "didUpdatePoll called")
        exp.expectedFulfillmentCount = 2
        delegate.didUpdatePollCompletion = {
            exp.fulfill()
        }

        // Synchronize to start observers
        controller.synchronize()
        
        // Update poll in database
        let updatedPoll = dummyPollPayload(
            id: pollId,
            name: "Updated Poll Name",
            user: user
        )
        
        try! client.databaseContainer.writeSynchronously { session in
            try session.savePoll(payload: updatedPoll, cache: nil)
        }
        
        // Verify delegate was notified
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(delegate.didUpdatePollCalled, true)
        XCTAssertEqual(delegate.updatedPoll?.id, pollId)
        XCTAssertEqual(delegate.updatedPoll?.name, "Updated Poll Name")
    }
}

// MARK: - Test Helper

private class TestDelegate: PollVoteListControllerDelegate {
    var didUpdatePollCalled = false
    var updatedPoll: Poll?
    var didUpdatePollCompletion: (() -> Void)?

    func controller(_ controller: PollVoteListController, didUpdatePoll poll: Poll) {
        didUpdatePollCalled = true
        updatedPoll = poll
        didUpdatePollCompletion?()
    }
    
    func controller(_ controller: PollVoteListController, didChangeVotes changes: [ListChange<PollVote>]) {
        // Not used in these tests
    }
}
