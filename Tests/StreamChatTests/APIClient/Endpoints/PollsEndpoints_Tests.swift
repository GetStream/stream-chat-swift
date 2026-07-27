//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class PollsEndpoints_Tests: XCTestCase {
    func test_createPoll_buildsV2Endpoint() {
        let endpoint: Endpoint<PollResponse> = .createPoll(createPollRequest: .init(name: "Lunch"))
        
        XCTAssertEqual(endpoint.path.value, "/api/v2/polls")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }
    
    func test_queryPollVotes_buildsV2Endpoint() {
        let pollId = "123"
        let endpoint: Endpoint<PollVotesResponse> = .queryPollVotes(
            pollId: pollId,
            userId: nil,
            queryPollVotesRequest: .init()
        )
        
        XCTAssertEqual(endpoint.path.value, "/api/v2/polls/\(pollId)/votes")
        XCTAssertEqual(endpoint.method, .post)
    }
    
    func test_castPollVote_buildsV2Endpoint() {
        let messageId: MessageId = .unique
        let pollId = "123"
        let endpoint: Endpoint<PollVoteResponse> = .castPollVote(
            messageId: messageId,
            pollId: pollId,
            castPollVoteRequest: .init(vote: .init(optionId: "1"))
        )
        
        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/messages/\(messageId)/polls/\(pollId)/vote")
        XCTAssertEqual(endpoint.method, .post)
    }
    
    func test_deletePollVote_buildsV2Endpoint() {
        let messageId: MessageId = .unique
        let pollId = "123"
        let voteId = "456"
        let endpoint: Endpoint<PollVoteResponse> = .deletePollVote(
            messageId: messageId,
            pollId: pollId,
            voteId: voteId,
            userId: nil
        )
        
        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/messages/\(messageId)/polls/\(pollId)/vote/\(voteId)")
        XCTAssertEqual(endpoint.method, .delete)
    }
    
    func test_deletePoll_buildsV2Endpoint() {
        let pollId = "123"
        let endpoint: Endpoint<EmptyResponse> = .deletePoll(pollId: pollId, userId: nil)
        
        XCTAssertEqual(endpoint.path.value, "/api/v2/polls/\(pollId)")
        XCTAssertEqual(endpoint.method, .delete)
    }
}
