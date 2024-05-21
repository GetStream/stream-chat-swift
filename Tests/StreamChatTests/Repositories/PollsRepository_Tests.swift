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
        
        repository.createPoll(name: pollName) { result in
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
        
        repository.createPoll(name: pollName) { result in
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
    
    func test_castPollVote_whenSuccess() {
        let completionCalled = expectation(description: "completion called")
        let pollOptionId = "345"
        let pollId = "123"
        let messageId: String = .unique
                
        repository.castPollVote(
            messageId: messageId,
            pollId: pollId,
            answerText: nil,
            optionId: pollOptionId,
            currentUserId: .unique,
            query: nil
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
    
    func test_castPollVote_whenFailure() {
        let completionCalled = expectation(description: "completion called")
        let pollId = "123"
        let messageId: String = .unique
        let pollOptionId = "345"

        repository.castPollVote(
            messageId: messageId,
            pollId: pollId,
            answerText: nil,
            optionId: pollOptionId,
            currentUserId: .unique,
            query: nil
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
}
