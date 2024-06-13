//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class PollsRepository_Tests: XCTestCase {
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer!
    var repository: PollsRepository!

    override func setUp() {
        super.setUp()

        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        repository = PollsRepository(database: database, apiClient: apiClient)
    }

    override func tearDown() {
        apiClient.cleanUp()

        apiClient = nil
        repository = nil
        database = nil

        super.tearDown()
    }

    // MARK: - Poll creation
    
    func test_createPoll_whenSuccessfull() {
        let completionCalled = expectation(description: "completion called")
        let pollName = "Test Poll"
        
        repository.createPoll(
            name: pollName,
            allowAnswers: nil,
            allowUserSuggestedOptions: nil,
            description: nil,
            enforceUniqueVote: nil,
            maxVotesAllowed: nil,
            votingVisibility: nil,
            options: nil,
            custom: nil
        ) { result in
            XCTAssertNil(result.error)
            completionCalled.fulfill()
        }
        
        let payload = XCTestCase().dummyPollPayload()
        let response = PollPayloadResponse(duration: "", poll: payload)
        apiClient.test_simulateResponse(.success(response))
        
        wait(for: [completionCalled], timeout: defaultTimeout)
        let referenceEndpoint: Endpoint<PollPayloadResponse> = .createPoll(
            createPollRequest: .init(name: pollName)
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
        XCTAssertEqual(payload.name, pollName)
    }
    
    func test_createPoll_whenFailure() {
        let completionCalled = expectation(description: "completion called")
        let pollName = "Test Poll"
        
        repository.createPoll(
            name: pollName,
            allowAnswers: nil,
            allowUserSuggestedOptions: nil,
            description: nil,
            enforceUniqueVote: nil,
            maxVotesAllowed: nil,
            votingVisibility: nil,
            options: nil,
            custom: nil
        ) { result in
            XCTAssertNotNil(result.error)
            completionCalled.fulfill()
        }
        
        let error = TestError()
        apiClient.test_simulateResponse(Result<PollPayloadResponse, Error>.failure(error))
        
        wait(for: [completionCalled], timeout: defaultTimeout)
        let referenceEndpoint: Endpoint<PollPayloadResponse> = .createPoll(
            createPollRequest: .init(name: pollName)
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    // MARK: - Closing poll
    
    func test_closePoll_whenSuccessfull() {
        let completionCalled = expectation(description: "completion called")
        let pollName = "Test Poll"
        let payload = XCTestCase().dummyPollPayload()
                
        repository.closePoll(pollId: payload.id) { error in
            XCTAssertNil(error)
            completionCalled.fulfill()
        }
        
        let response = PollPayloadResponse(duration: "", poll: payload)
        apiClient.test_simulateResponse(.success(response))
        
        wait(for: [completionCalled], timeout: defaultTimeout)
        let referenceEndpoint: Endpoint<PollPayloadResponse> = .updatePollPartial(
            pollId: payload.id,
            updatePollPartialRequest: .init(pollId: payload.id, set: ["is_closed": .bool(true)])
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
        XCTAssertEqual(payload.name, pollName)
    }
    
    func test_closePoll_whenFailure() {
        let completionCalled = expectation(description: "completion called")
        let pollId = "123"
        
        repository.closePoll(pollId: pollId) { error in
            XCTAssertNotNil(error)
            completionCalled.fulfill()
        }
        
        let error = TestError()
        apiClient.test_simulateResponse(Result<PollPayloadResponse, Error>.failure(error))
        
        wait(for: [completionCalled], timeout: defaultTimeout)
        let referenceEndpoint: Endpoint<PollPayloadResponse> = .updatePollPartial(
            pollId: pollId,
            updatePollPartialRequest: .init(pollId: pollId, set: ["is_closed": .bool(true)])
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    // MARK: - Suggest options
    
    func test_suggestPollOption_whenSuccess() {
        let completionCalled = expectation(description: "completion called")
        let pollOption = "Test option"
        let pollId = "123"
        let payload = XCTestCase().dummyPollOptionPayload(text: pollOption)
                
        repository.suggestPollOption(pollId: pollId, text: pollOption) { error in
            XCTAssertNil(error)
            completionCalled.fulfill()
        }
        
        let response = PollOptionResponse(duration: "", pollOption: payload)
        apiClient.test_simulateResponse(.success(response))
        
        wait(for: [completionCalled], timeout: defaultTimeout)
        let referenceEndpoint: Endpoint<PollOptionResponse> = .createPollOption(
            pollId: pollId,
            createPollOptionRequest: .init(pollId: pollId, text: pollOption)
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
        XCTAssertEqual(payload.text, pollOption)
    }
    
    func test_suggestPollOption_whenFailure() {
        let completionCalled = expectation(description: "completion called")
        let pollOption = "Test option"
        let pollId = "123"
                
        repository.suggestPollOption(pollId: pollId, text: pollOption) { error in
            XCTAssertNotNil(error)
            completionCalled.fulfill()
        }
        
        let error = TestError()
        apiClient.test_simulateResponse(Result<PollOptionResponse, Error>.failure(error))
        
        wait(for: [completionCalled], timeout: defaultTimeout)
        let referenceEndpoint: Endpoint<PollOptionResponse> = .createPollOption(
            pollId: pollId,
            createPollOptionRequest: .init(pollId: pollId, text: pollOption)
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    // MARK: - Casting votes
    
    func test_castPollVote_whenSuccess() throws {
        let completionCalled = expectation(description: "completion called")
        let pollOptionId = "345"
        let pollId = "123"
        let messageId: String = .unique
        
        try database.writeSynchronously { session in
            try session.savePoll(
                payload: self.dummyPollPayload(
                    id: pollId,
                    options: [self.dummyPollOptionPayload(id: pollOptionId)]
                ),
                cache: nil
            )
        }
                
        repository.castPollVote(
            messageId: messageId,
            pollId: pollId,
            answerText: nil,
            optionId: pollOptionId,
            currentUserId: .unique,
            query: nil,
            deleteExistingVotes: []
        ) { error in
            XCTAssertNil(error)
            completionCalled.fulfill()
        }
        
        wait(for: [apiClient.request_expectation], timeout: defaultTimeout)
        
        let payload = XCTestCase().dummyPollVotePayload(optionId: pollOptionId, pollId: pollId)
        let response = PollVotePayloadResponse(duration: "", vote: payload)
        apiClient.test_simulateResponse(.success(response))
        
        wait(for: [completionCalled], timeout: defaultTimeout)
        let referenceEndpoint: Endpoint<PollVotePayloadResponse> = .castPollVote(
            messageId: messageId,
            pollId: pollId,
            vote: .init(pollId: pollId, vote: .init(optionId: pollOptionId))
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
        XCTAssertEqual(payload.optionId, pollOptionId)
    }
    
    func test_castPollVote_whenFailure() throws {
        let completionCalled = expectation(description: "completion called")
        let pollId = "123"
        let messageId: String = .unique
        let pollOptionId = "345"
        
        try database.writeSynchronously { session in
            try session.savePoll(
                payload: self.dummyPollPayload(
                    id: pollId,
                    options: [self.dummyPollOptionPayload(id: pollOptionId)]
                ),
                cache: nil
            )
        }

        repository.castPollVote(
            messageId: messageId,
            pollId: pollId,
            answerText: nil,
            optionId: pollOptionId,
            currentUserId: .unique,
            query: nil,
            deleteExistingVotes: []
        ) { error in
            XCTAssertNotNil(error)
            completionCalled.fulfill()
        }
        
        wait(for: [apiClient.request_expectation], timeout: defaultTimeout)
        
        let error = TestError()
        apiClient.test_simulateResponse(Result<PollVotePayloadResponse, Error>.failure(error))
        
        wait(for: [completionCalled], timeout: defaultTimeout)
        let referenceEndpoint: Endpoint<PollVotePayloadResponse> = .castPollVote(
            messageId: messageId,
            pollId: pollId,
            vote: .init(pollId: pollId, vote: .init(optionId: pollOptionId))
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_castPollVote_whenLocallySaving_thenLatestAnswerDoesNotIncludeVote() throws {
        let completionCalled = expectation(description: "completion called")
        let pollId = "123"
        let messageId: String = .unique
        let pollOptionId = "345"
        
        try database.writeSynchronously { session in
            try session.savePoll(
                payload: self.dummyPollPayload(
                    id: pollId,
                    options: [self.dummyPollOptionPayload(id: pollOptionId)]
                ),
                cache: nil
            )
        }
        
        repository.castPollVote(
            messageId: messageId,
            pollId: pollId,
            answerText: nil,
            optionId: pollOptionId,
            currentUserId: .unique,
            query: nil,
            deleteExistingVotes: []
        ) { _ in
            completionCalled.fulfill()
        }
        wait(for: [apiClient.request_expectation], timeout: defaultTimeout)

        database.backgroundReadOnlyContext.performAndWait {
            let poll = try? database.backgroundReadOnlyContext.poll(id: pollId)
            XCTAssertEqual(0, poll?.latestAnswers.count)
        }
        
        apiClient.test_simulateResponse(Result<PollVotePayloadResponse, Error>.failure(TestError()))
        wait(for: [completionCalled], timeout: defaultTimeout)
    }
    
    func test_castPollAnswer_whenSuccess() {
        let completionCalled = expectation(description: "completion called")
        let pollId = "123"
        let messageId: String = .unique
        let answer = "Answer"
        
        repository.castPollVote(
            messageId: messageId,
            pollId: pollId,
            answerText: answer,
            optionId: nil,
            currentUserId: .unique,
            query: nil,
            deleteExistingVotes: []
        ) { error in
            XCTAssertNil(error)
            completionCalled.fulfill()
        }
        
        wait(for: [apiClient.request_expectation], timeout: defaultTimeout)
        
        let payload = XCTestCase().dummyPollVotePayload(optionId: nil, pollId: pollId, answerText: answer)
        let response = PollVotePayloadResponse(duration: "", vote: payload)
        apiClient.test_simulateResponse(.success(response))
        
        wait(for: [completionCalled], timeout: defaultTimeout)
        let referenceEndpoint: Endpoint<PollVotePayloadResponse> = .castPollVote(
            messageId: messageId,
            pollId: pollId,
            vote: .init(pollId: pollId, vote: .init(answerText: answer))
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
        XCTAssertEqual(payload.optionId, nil)
        XCTAssertEqual(payload.answerText, answer)
    }
    
    func test_castPollAnswer_whenFailure() {
        let completionCalled = expectation(description: "completion called")
        let pollId = "123"
        let messageId: String = .unique
        let answer = "Answer"

        repository.castPollVote(
            messageId: messageId,
            pollId: pollId,
            answerText: answer,
            optionId: nil,
            currentUserId: .unique,
            query: nil,
            deleteExistingVotes: []
        ) { error in
            XCTAssertNotNil(error)
            completionCalled.fulfill()
        }
        
        wait(for: [apiClient.request_expectation], timeout: defaultTimeout)
        
        let error = TestError()
        apiClient.test_simulateResponse(Result<PollVotePayloadResponse, Error>.failure(error))
        
        wait(for: [completionCalled], timeout: defaultTimeout)
        let referenceEndpoint: Endpoint<PollVotePayloadResponse> = .castPollVote(
            messageId: messageId,
            pollId: pollId,
            vote: .init(pollId: pollId, vote: .init(answerText: answer))
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    // MARK: - Removing votes
    
    func test_removePollVote_whenSuccess() throws {
        let completionCalled = expectation(description: "completion called")
        let pollOptionId = "345"
        let pollId = "123"
        let messageId: String = .unique
        var voteId: String!
        let currentUserId = String.unique
        
        let payload = XCTestCase().dummyPollVotePayload(optionId: pollOptionId, pollId: pollId)
        
        try database.createCurrentUser(id: currentUserId)
        
        try database.writeSynchronously { session in
            let poll = XCTestCase().dummyPollPayload(id: pollId, user: .dummy(userId: currentUserId))
            try session.savePoll(payload: poll, cache: nil)
        }
        
        try database.writeSynchronously { session in
            let dto = try session.savePollVote(payload: payload, query: nil, cache: nil)
            voteId = dto.id
        }
        
        repository.removePollVote(messageId: messageId, pollId: pollId, voteId: voteId) { error in
            XCTAssertNil(error)
            completionCalled.fulfill()
        }
        
        wait(for: [apiClient.request_expectation], timeout: defaultTimeout)
        
        let response = PollVotePayloadResponse(duration: "", vote: payload)
        apiClient.test_simulateResponse(.success(response))
        
        wait(for: [completionCalled], timeout: defaultTimeout)
        let referenceEndpoint: Endpoint<PollVotePayloadResponse> = .removePollVote(
            messageId: messageId,
            pollId: pollId,
            voteId: voteId
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
        XCTAssertEqual(payload.optionId, pollOptionId)
    }
    
    func test_removePollVote_whenFailure() throws {
        let completionCalled = expectation(description: "completion called")
        let pollOptionId = "345"
        let pollId = "123"
        let messageId: String = .unique
        var voteId: String!
        let currentUserId = String.unique
        
        let payload = XCTestCase().dummyPollVotePayload(optionId: pollOptionId, pollId: pollId)
        
        try database.createCurrentUser(id: currentUserId)
        
        try database.writeSynchronously { session in
            let poll = XCTestCase().dummyPollPayload(id: pollId, user: .dummy(userId: currentUserId))
            try session.savePoll(payload: poll, cache: nil)
        }
        
        try database.writeSynchronously { session in
            let dto = try session.savePollVote(payload: payload, query: nil, cache: nil)
            voteId = dto.id
        }
        
        repository.removePollVote(messageId: messageId, pollId: pollId, voteId: voteId) { error in
            XCTAssertNotNil(error)
            completionCalled.fulfill()
        }
        
        wait(for: [apiClient.request_expectation], timeout: defaultTimeout)
        
        let error = TestError()
        apiClient.test_simulateResponse(Result<PollVotePayloadResponse, Error>.failure(error))
        
        wait(for: [completionCalled], timeout: defaultTimeout)
        let referenceEndpoint: Endpoint<PollVotePayloadResponse> = .removePollVote(
            messageId: messageId,
            pollId: pollId,
            voteId: voteId
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    // MARK: - Querying votes
    
    func test_queryPollVotes_whenSuccess() {
        let completionCalled = expectation(description: "completion called")
        let pollId = String.unique
        let optionId = String.unique
        let query = PollVoteListQuery(pollId: pollId, optionId: optionId)
        
        repository.queryPollVotes(query: query) { result in
            XCTAssertNil(result.error)
            completionCalled.fulfill()
        }
        
        let vote = XCTestCase().dummyPollVotePayload()
        let response = PollVoteListResponse(duration: "", votes: [vote])
        apiClient.test_simulateResponse(.success(response))
        
        wait(for: [completionCalled], timeout: defaultTimeout)
        let referenceEndpoint: Endpoint<PollVoteListResponse> = .queryPollVotes(pollId: pollId, query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
        XCTAssertEqual(response.votes.count, 1)
    }
    
    func test_queryPollVotes_whenFailure() {
        let completionCalled = expectation(description: "completion called")
        let pollId = String.unique
        let optionId = String.unique
        let query = PollVoteListQuery(pollId: pollId, optionId: optionId)
        
        repository.queryPollVotes(query: query) { result in
            XCTAssertNotNil(result.error)
            completionCalled.fulfill()
        }
        
        let error = TestError()
        apiClient.test_simulateResponse(Result<PollVoteListResponse, Error>.failure(error))
        
        wait(for: [completionCalled], timeout: defaultTimeout)
        let referenceEndpoint: Endpoint<PollVoteListResponse> = .queryPollVotes(pollId: pollId, query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_queryPollVotesById_whenSuccess() {
        let completionCalled = expectation(description: "completion called")
        let pollId = String.unique
        
        repository.queryPollVotes(
            pollId: pollId,
            limit: nil,
            next: nil,
            prev: nil,
            sort: [nil],
            filter: nil
        ) { result in
            XCTAssertNil(result.error)
            completionCalled.fulfill()
        }
        
        let vote = XCTestCase().dummyPollVotePayload()
        let response = PollVoteListResponse(duration: "", votes: [vote])
        apiClient.test_simulateResponse(.success(response))
        
        wait(for: [completionCalled], timeout: defaultTimeout)
        let referenceEndpoint: Endpoint<PollVoteListResponse> = .queryPollVotes(
            pollId: pollId, queryPollVotesRequest: .init(pollId: pollId, sort: [nil])
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
        XCTAssertEqual(response.votes.count, 1)
    }
    
    func test_queryPollVotesById_whenFailure() {
        let completionCalled = expectation(description: "completion called")
        let pollId = String.unique
        
        repository.queryPollVotes(
            pollId: pollId,
            limit: nil,
            next: nil,
            prev: nil,
            sort: [nil],
            filter: nil
        ) { result in
            XCTAssertNotNil(result.error)
            completionCalled.fulfill()
        }
        
        let error = TestError()
        apiClient.test_simulateResponse(Result<PollVoteListResponse, Error>.failure(error))
        
        wait(for: [completionCalled], timeout: defaultTimeout)
        let referenceEndpoint: Endpoint<PollVoteListResponse> = .queryPollVotes(
            pollId: pollId, queryPollVotesRequest: .init(pollId: pollId, sort: [nil])
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
}
