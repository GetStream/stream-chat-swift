//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class PollDTO_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!

    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        database = nil
        super.tearDown()
    }

    func test_savePoll_storesAndLoadsTranslations() throws {
        let pollId = "poll_lunch"
        let currentUserId = String.unique
        try database.createCurrentUser(id: currentUserId)

        let answer = dummyPollVotePayload(
            id: "answer",
            pollId: pollId,
            answerText: "Fish, please",
            isAnswer: true,
            answerTextI18n: ["language": "en", "en_text": "Fish, please", "es_text": "Pescado, por favor"]
        )
        let payload = dummyPollPayload(
            description: "Pick one",
            id: pollId,
            name: "What's for lunch?",
            latestAnswers: [answer],
            options: [
                dummyPollOptionPayload(
                    id: "opt_soup",
                    text: "Soup",
                    textI18n: ["language": "en", "en_text": "Soup", "es_text": "Sopa"]
                )
            ],
            nameI18n: ["language": "en", "en_text": "What's for lunch?", "es_text": "¿Qué hay de almuerzo?"],
            descriptionI18n: ["language": "fr", "fr_text": "Pick one", "es_text": "Elige uno"]
        )

        try database.writeSynchronously { session in
            try session.savePoll(payload: payload, cache: nil, fromEvent: false)
        }

        let poll = try XCTUnwrap(database.readSynchronously { try $0.poll(id: pollId)?.asModel() })
        XCTAssertEqual(poll.originalLanguage, .english)
        XCTAssertEqual(poll.nameTranslations, [.english: "What's for lunch?", .spanish: "¿Qué hay de almuerzo?"])
        XCTAssertEqual(poll.descriptionOriginalLanguage, .french)
        XCTAssertEqual(poll.descriptionTranslations, [.french: "Pick one", .spanish: "Elige uno"])
        XCTAssertEqual(poll.translatedName(for: .spanish), "¿Qué hay de almuerzo?")
        XCTAssertEqual(poll.translatedDescription(for: .spanish), "Elige uno")

        let option = try XCTUnwrap(poll.options.first)
        XCTAssertEqual(option.originalLanguage, .english)
        XCTAssertEqual(option.translations, [.english: "Soup", .spanish: "Sopa"])
        XCTAssertEqual(option.translatedText(for: .spanish), "Sopa")

        let latestAnswer = try XCTUnwrap(poll.latestAnswers.first)
        XCTAssertEqual(latestAnswer.originalLanguage, .english)
        XCTAssertEqual(latestAnswer.answerTextTranslations, [.english: "Fish, please", .spanish: "Pescado, por favor"])
        XCTAssertEqual(latestAnswer.translatedAnswerText(for: .spanish), "Pescado, por favor")
    }

    func test_savePoll_whenTranslationsAreRemoved_clearsTranslations() throws {
        let pollId = String.unique
        try database.createCurrentUser(id: .unique)

        let translatedPayload = dummyPollPayload(
            id: pollId,
            name: "Lunch",
            options: [dummyPollOptionPayload(id: "option", text: "Soup", textI18n: ["language": "en", "es_text": "Sopa"])],
            nameI18n: ["language": "en", "es_text": "Almuerzo"]
        )
        let untranslatedPayload = dummyPollPayload(
            id: pollId,
            name: "Dinner",
            options: [dummyPollOptionPayload(id: "option", text: "Salad")]
        )

        try database.writeSynchronously { session in
            try session.savePoll(payload: translatedPayload, cache: nil, fromEvent: false)
        }
        try database.writeSynchronously { session in
            try session.savePoll(payload: untranslatedPayload, cache: nil, fromEvent: true)
        }

        let poll = try XCTUnwrap(database.readSynchronously { try $0.poll(id: pollId)?.asModel() })
        XCTAssertNil(poll.nameTranslations)
        XCTAssertNil(poll.originalLanguage)
        XCTAssertNil(poll.translatedName(for: .spanish))
        XCTAssertNil(poll.options.first?.translations)
        XCTAssertNil(poll.options.first?.translatedText(for: .spanish))
    }

    func test_savePollVote_storesAndLoadsAnswerTranslations() throws {
        let pollId = String.unique
        try database.createCurrentUser(id: .unique)
        let vote = dummyPollVotePayload(
            id: "answer",
            pollId: pollId,
            answerText: "Bonjour",
            isAnswer: true,
            answerTextI18n: ["language": "fr", "fr_text": "Bonjour", "en_text": "Hello"]
        )

        try database.writeSynchronously { session in
            try session.savePoll(payload: self.dummyPollPayload(id: pollId), cache: nil)
            try session.savePollVote(payload: vote, query: nil, cache: nil)
        }

        let loadedVote = try XCTUnwrap(database.readSynchronously { try $0.pollVote(id: "answer", pollId: pollId)?.asModel() })
        XCTAssertEqual(loadedVote.originalLanguage, .french)
        XCTAssertEqual(loadedVote.answerTextTranslations, [.french: "Bonjour", .english: "Hello"])
        XCTAssertEqual(loadedVote.translatedAnswerText(for: .english), "Hello")
        XCTAssertNil(loadedVote.translatedAnswerText(for: .french))
    }
}
