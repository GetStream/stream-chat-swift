//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class PollController_Tests: XCTestCase {
    fileprivate var env: PollController.Environment!

    var client: ChatClient_Mock!

    var messageId: MessageId!
    var pollId: String!
    
    var currentUserId: UserId!

    var controller: PollController!
    var controllerCallbackQueueID: UUID!
    /// Workaround for unwrapping **controllerCallbackQueueID!** in each closure that captures it
    private var callbackQueueID: UUID { controllerCallbackQueueID }

    override func setUp() {
        super.setUp()

        env = PollController.Environment()
        client = ChatClient.mock
        messageId = .unique
        pollId = .unique
        currentUserId = .unique
        
        controller = PollController(
            client: client,
            messageId: messageId,
            pollId: pollId,
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
        messageId = nil
        controllerCallbackQueueID = nil

        super.tearDown()
    }
    
    // MARK: - Controller
    
    func test_controllerIsCreatedCorrectly() {
        let controller = client.pollController(messageId: messageId, pollId: pollId)

        // Assert controller has correct `cid`
        XCTAssertEqual(controller.pollId, pollId)
        // Assert controller has correct `messageId`
        XCTAssertEqual(controller.messageId, messageId)
    }

    func test_initialState() {
        // Assert client is assigned correctly
        XCTAssertTrue(controller.client === client)

        // Assert initial state is correct
        XCTAssertEqual(controller.state, .initialized)

        // Assert message is nil
        XCTAssertNil(controller.poll)
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

    func test_pollIsUpToDate_withoutSynchronizeCall() throws {
        // Assert message is `nil` initially and start observing DB
        XCTAssertNil(controller.poll)

        // Create current user in the database
        try client.databaseContainer.createCurrentUser(id: currentUserId)

        // Create poll in that matches controller's `pollId`
        let user = UserPayload.dummy(userId: currentUserId)
        try client.databaseContainer.createPoll(id: pollId, createdBy: user)

        // Assert message is fetched from the database and has correct field values
        var poll = try XCTUnwrap(controller.poll)
        XCTAssertEqual(poll.id, pollId)

        // Simulate response from the backend with updated `name`, update the local poll in the database
        let updatedName = "Poll Updated"
        let pollPayload: PollPayload = XCTestCase().dummyPollPayload(
            id: pollId,
            name: updatedName,
            user: user
        )
        try client.databaseContainer.writeSynchronously { session in
            try session.savePoll(payload: pollPayload, cache: nil)
        }

        // Assert the controller's `poll` is up-to-date
        poll = try XCTUnwrap(controller.poll)
        XCTAssertEqual(poll.id, pollId)
        XCTAssertEqual(poll.name, updatedName)
    }
    
    func test_ownVotesAreFetched_afterCallingSynchronize() throws {
        // Simulate `synchronize` call
        controller.synchronize()
        
        // Create current user in the database
        try client.databaseContainer.createCurrentUser(id: currentUserId)
        
        let user = UserPayload.dummy(userId: currentUserId)
        try client.databaseContainer.createPoll(id: pollId, createdBy: user)

        // Create own votes.
        var ownVotes = [PollVotePayload]()
        for _ in 0..<5 {
            ownVotes.append(XCTestCase().dummyPollVotePayload(pollId: pollId, userId: user.id, user: user))
        }
        
        let response = PollVoteListResponse(duration: "", votes: ownVotes)
        let query = controller.ownVotesQuery
        try client.databaseContainer.writeSynchronously { session in
            try session.savePollVotes(payload: response, query: query, cache: nil)
        }

        XCTAssertEqual(controller.poll?.id, pollId)
        XCTAssertEqual(controller.ownVotes.count, ownVotes.count)
        
        controller = nil
        client = nil
    }
    
    // MARK: - Casting votes
    
    func test_addVote_propagatesError() {
        // Simulate `castPollVote` call and catch the completion.
        var completionError: Error?
        controller.castPollVote(answerText: nil, optionId: "123") {
            completionError = $0
        }

        // Simulate network response with the error.
        let networkError = TestError()
        client.mockPollsRepository.castPollVote_completion?(networkError)

        // Assert error is propagated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }
    
    func test_addVote_propagatesSuccess() {
        // Simulate `addVote` call and catch the completion.
        var completionIsCalled = false
        controller.castPollVote(answerText: nil, optionId: "123") { error in
            XCTAssertNil(error)
            completionIsCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate successful network response.
        client.mockPollsRepository.castPollVote_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        client.mockPollsRepository.castPollVote_completion = nil

        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    // MARK: - Removing votes
    
    func test_removeVote_propagatesError() {
        // Simulate `removePollVote` call and catch the completion.
        var completionError: Error?
        controller.removePollVote(voteId: "123") {
            completionError = $0
        }

        // Simulate network response with the error.
        let networkError = TestError()
        client.mockPollsRepository.removePollVote_completion?(networkError)

        // Assert error is propagated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }
    
    func test_removePollVote_propagatesSuccess() {
        // Simulate `removePollVote` call and catch the completion.
        var completionIsCalled = false
        controller.removePollVote(voteId: "123") {
            XCTAssertNil($0)
            completionIsCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate successful network response.
        client.mockPollsRepository.removePollVote_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        client.mockPollsRepository.removePollVote_completion = nil

        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    // MARK: - Closing poll
    
    func test_closePoll_propagatesError() {
        // Simulate `closePoll` call and catch the completion.
        var completionError: Error?
        controller.closePoll {
            completionError = $0
        }

        // Simulate network response with the error.
        let networkError = TestError()
        client.mockPollsRepository.closePoll_completion?(networkError)

        // Assert error is propagated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }
    
    func test_closePoll_propagatesSuccess() {
        // Simulate `closePoll` call and catch the completion.
        var completionIsCalled = false
        controller.closePoll {
            XCTAssertNil($0)
            completionIsCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate successful network response.
        client.mockPollsRepository.closePoll_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        client.mockPollsRepository.closePoll_completion = nil

        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    // MARK: - Suggest poll options
    
    func test_suggestPollOption_propagatesError() {
        // Simulate `suggestPollOption` call and catch the completion.
        var completionError: Error?
        controller.suggestPollOption(text: "test") {
            completionError = $0
        }

        // Simulate network response with the error.
        let networkError = TestError()
        client.mockPollsRepository.suggestPollOption_completion?(networkError)

        // Assert error is propagated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }
    
    func test_suggestPollOption_propagatesSuccess() {
        // Simulate `suggestPollOption` call and catch the completion.
        var completionIsCalled = false
        controller.suggestPollOption(text: "test") {
            XCTAssertNil($0)
            completionIsCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate successful network response.
        client.mockPollsRepository.suggestPollOption_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        client.mockPollsRepository.suggestPollOption_completion = nil

        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
}
