//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class PollsEndpoints_Tests: XCTestCase {
    func test_createPoll() throws {
        let request = CreatePollRequestBody(
            name: "test",
            allowAnswers: true,
            allowUserSuggestedOptions: true,
            description: "Desc",
            enforceUniqueVote: false,
            id: "test",
            isClosed: false,
            maxVotesAllowed: 1
        )
        let endpoint = Endpoint<PollPayloadResponse>.createPoll(createPollRequest: request)
        
        let expectedBody: [String: Any] = [
            "name": "test",
            "allow_answers": true,
            "allow_user_suggested_options": true,
            "description": "Desc",
            "enforce_unique_vote": false,
            "id": "test",
            "is_closed": false,
            "max_votes_allowed": 1
        ]
        let body = try AnyEndpoint(endpoint).bodyAsDictionary()

        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.path.value, "polls")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }
    
    func test_updatePoll() throws {
        let request = UpdatePollRequestBody(
            id: "test",
            name: "test",
            allowAnswers: true,
            allowUserSuggestedOptions: true,
            description: "Desc",
            enforceUniqueVote: false,
            isClosed: false,
            maxVotesAllowed: 1
        )
        let endpoint = Endpoint<PollPayloadResponse>.updatePoll(updatePollRequest: request)
        
        let expectedBody: [String: Any] = [
            "name": "test",
            "allow_answers": true,
            "allow_user_suggested_options": true,
            "description": "Desc",
            "enforce_unique_vote": false,
            "id": "test",
            "is_closed": false,
            "max_votes_allowed": 1
        ]
        let body = try AnyEndpoint(endpoint).bodyAsDictionary()

        XCTAssertEqual(endpoint.method, .put)
        XCTAssertEqual(endpoint.path.value, "polls")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }
    
    func test_queryPolls() throws {
        let request = QueryPollsRequestBody(limit: 30, prev: "10")
        let endpoint = Endpoint<PollsListPayloadResponse>.queryPolls(queryPollsRequest: request)
        
        let expectedBody: [String: Any] = ["limit": 30, "prev": "10"]
        let body = try AnyEndpoint(endpoint).bodyAsDictionary()

        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.path.value, "polls/query")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }
    
    func test_deletePoll() throws {
        let endpoint = Endpoint<EmptyResponse>.deletePoll(pollId: "test")
        
        XCTAssertEqual(endpoint.method, .delete)
        XCTAssertEqual(endpoint.path.value, "polls/test")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
    }
    
    func test_getPoll() throws {
        let endpoint = Endpoint<PollPayloadResponse>.getPoll(pollId: "test")
        
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.path.value, "polls/test")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
    }
    
    func test_updatePollPartial() throws {
        let request = UpdatePollPartialRequestBody(pollId: "test", set: ["name": "test_updated"])
        let endpoint = Endpoint<PollPayloadResponse>.updatePollPartial(
            pollId: "test",
            updatePollPartialRequest: request
        )
        
        let expectedBody: [String: Any] = [
            "poll_id": "test",
            "set": [
                "name": "test_updated"
            ]
        ]
        let body = try AnyEndpoint(endpoint).bodyAsDictionary()

        XCTAssertEqual(endpoint.method, .patch)
        XCTAssertEqual(endpoint.path.value, "polls/test")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }
    
    func test_createPollOption() throws {
        let request = CreatePollOptionRequestBody(pollId: "test", text: "sample")
        let endpoint = Endpoint<PollOptionResponse>.createPollOption(
            pollId: "test",
            createPollOptionRequest: request
        )
        
        let expectedBody: [String: Any] = [
            "poll_id": "test",
            "text": "sample"
        ]
        let body = try AnyEndpoint(endpoint).bodyAsDictionary()

        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.path.value, "polls/test/options")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }
    
    func test_updatePollOption() throws {
        let request = UpdatePollOptionRequest(id: "option_id", pollId: "test", text: "sample")
        let endpoint = Endpoint<PollOptionResponse>.updatePollOption(
            pollId: "test",
            updatePollOptionRequest: request
        )
        
        let expectedBody: [String: Any] = [
            "id": "option_id",
            "poll_id": "test",
            "text": "sample"
        ]
        let body = try AnyEndpoint(endpoint).bodyAsDictionary()

        XCTAssertEqual(endpoint.method, .put)
        XCTAssertEqual(endpoint.path.value, "polls/test/options")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }
    
    func test_deletePollOption() throws {
        let endpoint = Endpoint<EmptyResponse>.deletePollOption(pollId: "test", optionId: "option_id")

        XCTAssertEqual(endpoint.method, .delete)
        XCTAssertEqual(endpoint.path.value, "polls/test/options/option_id")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
    }
    
    func test_getPollOption() throws {
        let endpoint = Endpoint<PollOptionResponse>.getPollOption(pollId: "test", optionId: "option_id")

        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.path.value, "polls/test/options/option_id")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
    }
    
    func test_queryPollVotes() throws {
        let request = QueryPollVotesRequestBody(pollId: "test", limit: 30, prev: "10")
        let endpoint = Endpoint<PollVoteListResponse>.queryPollVotes(pollId: "test", queryPollVotesRequest: request)
        
        let expectedBody: [String: Any] = ["poll_id": "test", "limit": 30, "prev": "10"]
        let body = try AnyEndpoint(endpoint).bodyAsDictionary()

        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.path.value, "polls/test/votes")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }
    
    func test_castPollVote() throws {
        let request = CastPollVoteRequestBody(
            pollId: "test",
            vote: .init(answerText: "test", optionId: "option")
        )
        let endpoint = Endpoint<PollVotePayloadResponse>.castPollVote(
            messageId: "message_id",
            pollId: "test",
            vote: request
        )
        
        let expectedBody: [String: Any] = [
            "poll_id": "test",
            "vote": ["answer_text": "test", "option_id": "option"]
        ]
        let body = try AnyEndpoint(endpoint).bodyAsDictionary()

        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.path.value, "messages/message_id/polls/test/vote")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }
    
    func test_removePollVote() throws {
        let endpoint = Endpoint<EmptyResponse>.removePollVote(
            messageId: "message_id",
            pollId: "test",
            voteId: "vote"
        )

        XCTAssertEqual(endpoint.method, .delete)
        XCTAssertEqual(endpoint.path.value, "messages/message_id/polls/test/vote/vote")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
    }
}
