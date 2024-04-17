//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class PollPayload_Tests: XCTestCase {
    func test_decodingPollPayload() throws {
        let url = XCTestCase.mockData(fromJSONFile: "Poll")
        let payload = try JSONDecoder.default.decode(PollPayloadResponse.self, from: url).poll

        XCTAssertEqual(payload.id, "7fd88eb3-fc05-4e89-89af-36c6d8995dda")
        XCTAssertEqual(payload.name, "test")
        XCTAssertEqual(payload.description, "")
        XCTAssertEqual(payload.votingVisibility, "public")
        XCTAssertEqual(payload.enforceUniqueVote, false)
        XCTAssertNil(payload.maxVotesAllowed)
        XCTAssertEqual(payload.allowUserSuggestedOptions, false)
        XCTAssertEqual(payload.allowAnswers, false)
        XCTAssertEqual(payload.voteCount, 0)
        XCTAssertTrue(payload.options.isEmpty)
        XCTAssertEqual(payload.answersCount, 0)
        XCTAssertNil(payload.voteCountsByOption)
        XCTAssertTrue(payload.latestVotesByOption.isEmpty)
        XCTAssertTrue(payload.ownVotes.isEmpty)
        XCTAssertEqual(payload.createdById, "luke_skywalker")
        XCTAssertNotNil(payload.createdBy)
    }
}
