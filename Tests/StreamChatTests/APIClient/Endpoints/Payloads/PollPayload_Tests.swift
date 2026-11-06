//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        XCTAssertEqual(payload.votingVisibility, .public)
        XCTAssertEqual(payload.enforceUniqueVote, false)
        XCTAssertNil(payload.maxVotesAllowed)
        XCTAssertEqual(payload.allowUserSuggestedOptions, false)
        XCTAssertEqual(payload.allowAnswers, false)
        XCTAssertEqual(payload.voteCount, 0)
        XCTAssertEqual(payload.options[0].id, "option1")
        XCTAssertEqual(payload.options[0].text, "option1 text")
        XCTAssertEqual(payload.answersCount, 0)
        XCTAssertTrue(payload.voteCountsByOption.isEmpty)
        XCTAssertTrue(payload.latestVotesByOption.isEmpty)
        XCTAssertEqual(payload.ownVotes.count, 1)
        XCTAssertEqual(payload.createdById, "luke_skywalker")
        XCTAssertNotNil(payload.createdBy)
    }

    func test_decodingPollPayload_withTranslations() throws {
        let json = """
        {
            "id": "poll_lunch",
            "name": "What's for lunch?",
            "name_i18n": { "language": "en", "en_text": "What's for lunch?", "es_text": "¿Qué hay de almuerzo?" },
            "description": "Pick one",
            "description_i18n": { "language": "en", "en_text": "Pick one", "es_text": "Elige uno" },
            "voting_visibility": "public",
            "enforce_unique_vote": false,
            "allow_user_suggested_options": false,
            "allow_answers": true,
            "vote_count": 0,
            "answers_count": 1,
            "custom": {},
            "options": [
                {
                    "id": "opt_pizza",
                    "text": "Pizza",
                    "text_i18n": { "language": "en", "en_text": "Pizza", "es_text": "Pizza" },
                    "custom": {}
                }
            ],
            "latest_answers": [
                {
                    "id": "answer",
                    "poll_id": "poll_lunch",
                    "option_id": "",
                    "answer_text": "Fish, please",
                    "answer_text_i18n": { "language": "en", "en_text": "Fish, please", "es_text": "Pescado, por favor" },
                    "is_answer": true,
                    "created_at": "2024-04-17T14:46:23.001349Z",
                    "updated_at": "2024-04-17T14:46:23.001349Z"
                }
            ],
            "vote_counts_by_option": {},
            "latest_votes_by_option": {},
            "own_votes": [],
            "created_by_id": "luke_skywalker",
            "created_at": "2024-04-17T14:46:23.001349Z",
            "updated_at": "2024-04-17T14:46:23.001349Z"
        }
        """
        let payload = try JSONDecoder.default.decode(PollPayload.self, from: Data(json.utf8))

        XCTAssertEqual(payload.nameI18n?["es_text"], "¿Qué hay de almuerzo?")
        XCTAssertEqual(payload.nameI18n?["language"], "en")
        XCTAssertEqual(payload.descriptionI18n?["es_text"], "Elige uno")
        XCTAssertEqual(payload.options[0].textI18n?["es_text"], "Pizza")
        XCTAssertEqual(payload.latestAnswers[0].answerTextI18n?["es_text"], "Pescado, por favor")
    }

    func test_decodingPollPayload_withoutTranslations() throws {
        let url = XCTestCase.mockData(fromJSONFile: "Poll")
        let payload = try JSONDecoder.default.decode(PollPayloadResponse.self, from: url).poll

        XCTAssertNil(payload.nameI18n)
        XCTAssertNil(payload.descriptionI18n)
        XCTAssertNil(payload.options[0].textI18n)
        XCTAssertNil(payload.ownVotes[0].answerTextI18n)
    }
}
