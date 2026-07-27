//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class PollsEndpoints_Tests: XCTestCase {
    func test_createPoll() throws {
        let request = CreatePollRequest(
            allowAnswers: true,
            allowUserSuggestedOptions: true,
            description: "Desc",
            enforceUniqueVote: false,
            id: "test",
            isClosed: false,
            maxVotesAllowed: 1,
            name: "test"
        )
        let endpoint = Endpoint<PollResponse>.createPoll(createPollRequest: request)

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
        let endpoint = Endpoint<EmptyResponse>.deletePoll(pollId: "test", userId: nil)

        XCTAssertEqual(endpoint.method, .delete)
        XCTAssertEqual(endpoint.path.value, "/api/v2/polls/test")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
    }

    func test_updatePollPartial() throws {
        let request = UpdatePollPartialRequest(set: ["name": .string("test_updated")])
        let endpoint = Endpoint<PollResponse>.updatePollPartial(
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
        let request = CreatePollOptionRequest(text: "sample")
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
        let request = QueryPollVotesRequest(limit: 30, prev: "10")
        let endpoint = Endpoint<PollVotesResponse>.queryPollVotes(
            pollId: "test",
            userId: nil,
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
        let request = CastPollVoteRequest(
            vote: .init(answerText: "test", optionId: "option")
        )
        let endpoint = Endpoint<PollVoteResponse>.castPollVote(
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
        let endpoint = Endpoint<PollVoteResponse>.deletePollVote(
            messageId: "message_id",
            pollId: "test",
            voteId: "vote",
            userId: nil
        )

        XCTAssertEqual(endpoint.method, .delete)
        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/messages/message_id/polls/test/vote/vote")
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.requiresToken, true)
        XCTAssertNil(endpoint.queryItems)
    }
}
