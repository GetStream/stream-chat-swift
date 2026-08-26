//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class PollsEndpoints_Tests: XCTestCase {
    func test_votingVisibility_encodesRawValueAsSingleValue() {
        let votingVisibility = VotingVisibility(rawValue: "future-visibility")

        XCTAssertEqual(JSONEncoder.default.encodedString(votingVisibility), "future-visibility")
    }

    func test_createPoll() throws {
        let request = CreatePollRequestBody(
            allowAnswers: true,
            allowUserSuggestedOptions: true,
            description: "Desc",
            enforceUniqueVote: false,
            id: "test",
            isClosed: false,
            maxVotesAllowed: 1,
            name: "test"
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
        XCTAssertEqual(endpoint.path.value, "/api/v2/polls")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }
    
    func test_deletePoll() {
        let endpoint = Endpoint<EmptyResponse>.deletePoll(pollId: "test")
        
        XCTAssertEqual(endpoint.method, .delete)
        XCTAssertEqual(endpoint.path.value, "/api/v2/polls/test")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
    }
    
    func test_updatePollPartial() throws {
        let request = UpdatePollPartialRequestBody(set: ["name": .string("test_updated")])
        let endpoint = Endpoint<PollPayloadResponse>.updatePollPartial(
            pollId: "test",
            updatePollPartialRequest: request
        )
        
        let expectedBody: [String: Any] = [
            "set": [
                "name": "test_updated"
            ]
        ]
        let body = try AnyEndpoint(endpoint).bodyAsDictionary()

        XCTAssertEqual(endpoint.method, .patch)
        XCTAssertEqual(endpoint.path.value, "/api/v2/polls/test")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }
    
    func test_createPollOption() throws {
        let request = CreatePollOptionRequestBody(text: "sample")
        let endpoint = Endpoint<PollOptionResponse>.createPollOption(
            pollId: "test",
            createPollOptionRequest: request
        )
        
        let expectedBody: [String: Any] = ["text": "sample"]
        let body = try AnyEndpoint(endpoint).bodyAsDictionary()

        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.path.value, "/api/v2/polls/test/options")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }
    
    func test_queryPollVotes() throws {
        let request = QueryPollVotesRequestBody(limit: 30, prev: "10")
        let endpoint = Endpoint<PollVoteListResponse>.queryPollVotes(
            pollId: "test",
            queryPollVotesRequest: request
        )
        
        let expectedBody: [String: Any] = ["limit": 30, "prev": "10"]
        let body = try AnyEndpoint(endpoint).bodyAsDictionary()

        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.path.value, "/api/v2/polls/test/votes")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }
    
    func test_castPollVote() throws {
        let request = CastPollVoteRequestBody(
            vote: .init(answerText: "test", optionId: "option")
        )
        let endpoint = Endpoint<PollVotePayloadResponse>.castPollVote(
            messageId: "message_id",
            pollId: "test",
            castPollVoteRequest: request
        )
        
        let expectedBody: [String: Any] = [
            "vote": ["answer_text": "test", "option_id": "option"]
        ]
        let body = try AnyEndpoint(endpoint).bodyAsDictionary()

        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/messages/message_id/polls/test/vote")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
        AssertDictionary(body, expectedBody)
    }
    
    func test_removePollVote() {
        let endpoint = Endpoint<PollVotePayloadResponse>.deletePollVote(
            messageId: "message_id",
            pollId: "test",
            voteId: "vote"
        )

        XCTAssertEqual(endpoint.method, .delete)
        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/messages/message_id/polls/test/vote/vote")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
    }
}
