//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class Poll_Tests: XCTestCase {
    func test_currentMaximumVoteCount() {
        let poll = Poll(
            allowAnswers: true,
            allowUserSuggestedOptions: false,
            answersCount: 10,
            createdAt: Date(),
            pollDescription: "Sample poll",
            enforceUniqueVote: true,
            id: "123",
            name: "Test Poll",
            updatedAt: nil,
            voteCount: 20,
            extraData: [:],
            voteCountsByOption: ["option1": 5, "option2": 10],
            isClosed: false,
            maxVotesAllowed: 1,
            votingVisibility: .public,
            createdBy: nil,
            latestAnswers: [],
            options: [],
            latestVotesByOption: [],
            latestVotes: [],
            ownVotes: []
        )

        XCTAssertEqual(poll.currentMaximumVoteCount, 10)
    }

    func test_isOptionWinner_whenClosed_whenMostVotes_returnsTrue() {
        let option = PollOption(id: "option1", text: "Option 1")
        let poll = Poll(
            allowAnswers: true,
            allowUserSuggestedOptions: false,
            answersCount: 10,
            createdAt: Date(),
            pollDescription: "Sample poll",
            enforceUniqueVote: true,
            id: "123",
            name: "Test Poll",
            updatedAt: nil,
            voteCount: 20,
            extraData: [:],
            voteCountsByOption: ["option1": 10, "option2": 5],
            isClosed: true,
            maxVotesAllowed: 1,
            votingVisibility: .public,
            createdBy: nil,
            latestAnswers: [],
            options: [],
            latestVotesByOption: [],
            latestVotes: [],
            ownVotes: []
        )

        XCTAssertTrue(poll.isOptionWinner(option))
    }

    func test_isOptionWinner_whenClosed_whenOneOfMostVotes_returnsFalse() {
        let option = PollOption(id: "option1", text: "Option 1")
        let poll = Poll(
            allowAnswers: true,
            allowUserSuggestedOptions: false,
            answersCount: 10,
            createdAt: Date(),
            pollDescription: "Sample poll",
            enforceUniqueVote: true,
            id: "123",
            name: "Test Poll",
            updatedAt: nil,
            voteCount: 20,
            extraData: [:],
            voteCountsByOption: ["option1": 10, "option2": 10],
            isClosed: true,
            maxVotesAllowed: 1,
            votingVisibility: .public,
            createdBy: nil,
            latestAnswers: [],
            options: [],
            latestVotesByOption: [],
            latestVotes: [],
            ownVotes: []
        )

        XCTAssertFalse(poll.isOptionWinner(option))
    }

    func test_isOptionWinner_whenNotClosed_returnsFalse() {
        let option = PollOption(id: "option1", text: "Option 1")
        let poll = Poll(
            allowAnswers: true,
            allowUserSuggestedOptions: false,
            answersCount: 10,
            createdAt: Date(),
            pollDescription: "Sample poll",
            enforceUniqueVote: true,
            id: "123",
            name: "Test Poll",
            updatedAt: nil,
            voteCount: 20,
            extraData: [:],
            voteCountsByOption: ["option1": 10, "option2": 5],
            isClosed: false,
            maxVotesAllowed: 1,
            votingVisibility: .public,
            createdBy: nil,
            latestAnswers: [],
            options: [],
            latestVotesByOption: [],
            latestVotes: [],
            ownVotes: []
        )

        XCTAssertFalse(poll.isOptionWinner(option))
    }

    func test_isOptionOneOfTheWinners_whenClosed_whenOneOfMostVotes_returnsTrue() {
        let option = PollOption(id: "option1", text: "Option 1")
        let poll = Poll(
            allowAnswers: true,
            allowUserSuggestedOptions: false,
            answersCount: 10,
            createdAt: Date(),
            pollDescription: "Sample poll",
            enforceUniqueVote: true,
            id: "123",
            name: "Test Poll",
            updatedAt: nil,
            voteCount: 25,
            extraData: [:],
            voteCountsByOption: ["option1": 10, "option2": 10, "option3": 5],
            isClosed: true,
            maxVotesAllowed: 1,
            votingVisibility: .public,
            createdBy: nil,
            latestAnswers: [],
            options: [],
            latestVotesByOption: [],
            latestVotes: [],
            ownVotes: []
        )

        XCTAssertTrue(poll.isOptionOneOfTheWinners(option))
    }

    func test_isOptionOneOfTheWinners_whenNotClosed_whenOneOfMostVotes_returnsFalse() {
        let option = PollOption(id: "option1", text: "Option 1")
        let poll = Poll(
            allowAnswers: true,
            allowUserSuggestedOptions: false,
            answersCount: 10,
            createdAt: Date(),
            pollDescription: "Sample poll",
            enforceUniqueVote: true,
            id: "123",
            name: "Test Poll",
            updatedAt: nil,
            voteCount: 20,
            extraData: [:],
            voteCountsByOption: ["option1": 10, "option2": 10],
            isClosed: false,
            maxVotesAllowed: 1,
            votingVisibility: .public,
            createdBy: nil,
            latestAnswers: [],
            options: [],
            latestVotesByOption: [],
            latestVotes: [],
            ownVotes: []
        )

        XCTAssertFalse(poll.isOptionOneOfTheWinners(option))
    }

    func test_isOptionWithMostVotes_whenTheOnlyOneWithMostVotes_returnsTrue() {
        let option = PollOption(id: "option1", text: "Option 1")
        let poll = Poll(
            allowAnswers: true,
            allowUserSuggestedOptions: false,
            answersCount: 10,
            createdAt: Date(),
            pollDescription: "Sample poll",
            enforceUniqueVote: true,
            id: "123",
            name: "Test Poll",
            updatedAt: nil,
            voteCount: 20,
            extraData: [:],
            voteCountsByOption: ["option1": 10, "option2": 5],
            isClosed: false,
            maxVotesAllowed: 1,
            votingVisibility: .public,
            createdBy: nil,
            latestAnswers: [],
            options: [],
            latestVotesByOption: [],
            latestVotes: [],
            ownVotes: []
        )

        XCTAssertTrue(poll.isOptionWithMostVotes(option))
    }

    func test_isOptionWithMostVotes_whenOneOfTheMaximumVotes_returnsFalse() {
        let option = PollOption(id: "option1", text: "Option 1")
        let poll = Poll(
            allowAnswers: true,
            allowUserSuggestedOptions: false,
            answersCount: 10,
            createdAt: Date(),
            pollDescription: "Sample poll",
            enforceUniqueVote: true,
            id: "123",
            name: "Test Poll",
            updatedAt: nil,
            voteCount: 20,
            extraData: [:],
            voteCountsByOption: ["option1": 10, "option2": 10],
            isClosed: false,
            maxVotesAllowed: 1,
            votingVisibility: .public,
            createdBy: nil,
            latestAnswers: [],
            options: [],
            latestVotesByOption: [],
            latestVotes: [],
            ownVotes: []
        )

        XCTAssertFalse(poll.isOptionWithMostVotes(option))
    }

    func test_isOptionWithMaximumVotes_whenOneOfTheMostVotes_returnsTrue() {
        let option = PollOption(id: "option1", text: "Option 1")
        let poll = Poll(
            allowAnswers: true,
            allowUserSuggestedOptions: false,
            answersCount: 10,
            createdAt: Date(),
            pollDescription: "Sample poll",
            enforceUniqueVote: true,
            id: "123",
            name: "Test Poll",
            updatedAt: nil,
            voteCount: 20,
            extraData: [:],
            voteCountsByOption: ["option1": 10, "option2": 10],
            isClosed: false,
            maxVotesAllowed: 1,
            votingVisibility: .public,
            createdBy: nil,
            latestAnswers: [],
            options: [],
            latestVotesByOption: [],
            latestVotes: [],
            ownVotes: []
        )

        XCTAssertTrue(poll.isOptionWithMaximumVotes(option))
    }

    func test_isOptionWithMaximumVotes_whenOneOfTheLeastVotes_returnsFalse() {
        let option = PollOption(id: "option1", text: "Option 1")
        let poll = Poll(
            allowAnswers: true,
            allowUserSuggestedOptions: false,
            answersCount: 10,
            createdAt: Date(),
            pollDescription: "Sample poll",
            enforceUniqueVote: true,
            id: "123",
            name: "Test Poll",
            updatedAt: nil,
            voteCount: 20,
            extraData: [:],
            voteCountsByOption: ["option1": 5, "option2": 10],
            isClosed: false,
            maxVotesAllowed: 1,
            votingVisibility: .public,
            createdBy: nil,
            latestAnswers: [],
            options: [],
            latestVotesByOption: [],
            latestVotes: [],
            ownVotes: []
        )

        XCTAssertFalse(poll.isOptionWithMaximumVotes(option))
    }

    func test_voteCountForOption() {
        let option = PollOption(id: "option1", text: "Option 1")
        let poll = Poll(
            allowAnswers: true,
            allowUserSuggestedOptions: false,
            answersCount: 10,
            createdAt: Date(),
            pollDescription: "Sample poll",
            enforceUniqueVote: true,
            id: "123",
            name: "Test Poll",
            updatedAt: nil,
            voteCount: 20,
            extraData: [:],
            voteCountsByOption: ["option1": 5, "option2": 10],
            isClosed: false,
            maxVotesAllowed: 1,
            votingVisibility: .public,
            createdBy: nil,
            latestAnswers: [],
            options: [],
            latestVotesByOption: [],
            latestVotes: [],
            ownVotes: []
        )

        XCTAssertEqual(poll.voteCount(for: option), 5)
    }

    func test_voteRatioForOption() {
        let option = PollOption(id: "option1", text: "Option 1")
        let poll = Poll(
            allowAnswers: true,
            allowUserSuggestedOptions: false,
            answersCount: 10,
            createdAt: Date(),
            pollDescription: "Sample poll",
            enforceUniqueVote: true,
            id: "123",
            name: "Test Poll",
            updatedAt: nil,
            voteCount: 20,
            extraData: [:],
            voteCountsByOption: ["option1": 5, "option2": 10],
            isClosed: false,
            maxVotesAllowed: 1,
            votingVisibility: .public,
            createdBy: nil,
            latestAnswers: [],
            options: [],
            latestVotesByOption: [],
            latestVotes: [],
            ownVotes: []
        )

        XCTAssertEqual(poll.voteRatio(for: option), 0.5)
    }
    
    func test_voteRatioForOption_whenOneOfTheMostVotes() {
        let option = PollOption(id: "option1", text: "Option 1")
        let poll = Poll(
            allowAnswers: true,
            allowUserSuggestedOptions: false,
            answersCount: 10,
            createdAt: Date(),
            pollDescription: "Sample poll",
            enforceUniqueVote: true,
            id: "123",
            name: "Test Poll",
            updatedAt: nil,
            voteCount: 20,
            extraData: [:],
            voteCountsByOption: ["option1": 10, "option2": 10, "option3": 5],
            isClosed: false,
            maxVotesAllowed: 1,
            votingVisibility: .public,
            createdBy: nil,
            latestAnswers: [],
            options: [],
            latestVotesByOption: [],
            latestVotes: [],
            ownVotes: []
        )

        XCTAssertEqual(poll.voteRatio(for: option), 1)
    }

    func test_voteRatioForOption_whenCurrentMaxVoteCountIsZero_returnZero() {
        let option = PollOption(id: "option1", text: "Option 1")
        let poll = Poll(
            allowAnswers: true,
            allowUserSuggestedOptions: false,
            answersCount: 10,
            createdAt: Date(),
            pollDescription: "Sample poll",
            enforceUniqueVote: true,
            id: "123",
            name: "Test Poll",
            updatedAt: nil,
            voteCount: 0,
            extraData: [:],
            voteCountsByOption: [:],
            isClosed: false,
            maxVotesAllowed: 1,
            votingVisibility: .public,
            createdBy: nil,
            latestAnswers: [],
            options: [],
            latestVotesByOption: [],
            latestVotes: [],
            ownVotes: []
        )

        XCTAssertEqual(poll.voteRatio(for: option), 0)
    }

    func test_currentUserVoteForOption() {
        let option = PollOption(id: "option1", text: "Option 1")
        let vote = PollVote(
            id: .unique,
            createdAt: .unique,
            updatedAt: .unique,
            pollId: "123",
            optionId: "option1",
            isAnswer: false,
            answerText: nil,
            user: .unique
        )
        let poll = Poll(
            allowAnswers: true,
            allowUserSuggestedOptions: false,
            answersCount: 10,
            createdAt: Date(),
            pollDescription: "Sample poll",
            enforceUniqueVote: true,
            id: "123",
            name: "Test Poll",
            updatedAt: nil,
            voteCount: 20,
            extraData: [:],
            voteCountsByOption: ["option1": 5, "option2": 10],
            isClosed: false,
            maxVotesAllowed: 1,
            votingVisibility: .public,
            createdBy: nil,
            latestAnswers: [],
            options: [],
            latestVotesByOption: [],
            latestVotes: [],
            ownVotes: [vote]
        )

        XCTAssertEqual(poll.currentUserVote(for: option), vote)
    }

    func test_hasCurrentUserVotedForOption() {
        let option = PollOption(id: "option1", text: "Option 1")
        let vote = PollVote(
            id: .unique,
            createdAt: .unique,
            updatedAt: .unique,
            pollId: "123",
            optionId: "option1",
            isAnswer: false,
            answerText: nil,
            user: .unique
        )
        let poll = Poll(
            allowAnswers: true,
            allowUserSuggestedOptions: false,
            answersCount: 10,
            createdAt: Date(),
            pollDescription: "Sample poll",
            enforceUniqueVote: true,
            id: "123",
            name: "Test Poll",
            updatedAt: nil,
            voteCount: 20,
            extraData: [:],
            voteCountsByOption: ["option1": 5, "option2": 10],
            isClosed: false,
            maxVotesAllowed: 1,
            votingVisibility: .public,
            createdBy: nil,
            latestAnswers: [],
            options: [],
            latestVotesByOption: [],
            latestVotes: [],
            ownVotes: [vote]
        )

        XCTAssertTrue(poll.hasCurrentUserVoted(for: option))
    }

    // MARK: - Translations

    func test_translatedName_returnsTranslation() {
        let poll = Poll.mock(
            name: "Lunch",
            nameTranslations: [.english: "Lunch", .spanish: "Almuerzo"],
            originalLanguage: .english
        )

        XCTAssertEqual(poll.translatedName(for: .spanish), "Almuerzo")
    }

    func test_translatedName_whenLanguageIsTheOriginalLanguage_returnsNil() {
        let poll = Poll.mock(
            name: "Lunch",
            nameTranslations: [.english: "Lunch, please", .spanish: "Almuerzo"],
            originalLanguage: .english
        )

        XCTAssertNil(poll.translatedName(for: .english))
    }

    func test_translatedName_whenTranslationIsTheSameAsTheName_returnsNil() {
        let poll = Poll.mock(name: "Pizza", nameTranslations: [.spanish: "Pizza"], originalLanguage: .english)

        XCTAssertNil(poll.translatedName(for: .spanish))
    }

    func test_translatedName_whenNoTranslation_returnsNil() {
        let poll = Poll.mock(name: "Lunch", nameTranslations: [.spanish: "Almuerzo"], originalLanguage: .english)

        XCTAssertNil(poll.translatedName(for: .french))
        XCTAssertNil(Poll.mock(name: "Lunch").translatedName(for: .spanish))
    }

    func test_translatedDescription() {
        let poll = Poll.mock(
            pollDescription: "Pick one",
            descriptionTranslations: [.spanish: "Elige uno"],
            originalLanguage: .english
        )

        XCTAssertEqual(poll.translatedDescription(for: .spanish), "Elige uno")
        XCTAssertNil(poll.translatedDescription(for: .english))
        XCTAssertNil(Poll.mock(pollDescription: nil, descriptionTranslations: [.spanish: "Elige uno"]).translatedDescription(for: .spanish))
    }

    func test_translatedDescription_usesDescriptionOriginalLanguage() {
        let poll = Poll.mock(
            pollDescription: "Pick one",
            name: "Pizza",
            nameTranslations: [.english: "Pizza"],
            descriptionTranslations: [.italian: "Scegline uno"],
            originalLanguage: .italian,
            descriptionOriginalLanguage: .english
        )

        XCTAssertEqual(poll.translatedDescription(for: .italian), "Scegline uno")
        XCTAssertNil(poll.translatedDescription(for: .english))
    }

    func test_hasTranslation_whenNameIsTranslated_returnsTrue() {
        let poll = Poll.mock(name: "Lunch", nameTranslations: [.spanish: "Almuerzo"], originalLanguage: .english)

        XCTAssertTrue(poll.hasTranslation(for: .spanish))
    }

    func test_hasTranslation_whenOnlyAnOptionIsTranslated_returnsTrue() {
        let poll = Poll.mock(
            name: "Pizza",
            options: [PollOption(text: "Soup", translations: [.spanish: "Sopa"], originalLanguage: .english)],
            nameTranslations: [.spanish: "Pizza"],
            originalLanguage: .english
        )

        XCTAssertTrue(poll.hasTranslation(for: .spanish))
    }

    func test_hasTranslation_whenNoValidTranslation_returnsFalse() {
        let poll = Poll.mock(
            name: "Lunch",
            options: [PollOption(text: "Pizza", translations: [.spanish: "Pizza", .french: ""], originalLanguage: .english)],
            nameTranslations: [.english: "Lunch, please", .spanish: "Almuerzo"],
            originalLanguage: .english
        )

        XCTAssertFalse(poll.hasTranslation(for: .english))
        XCTAssertFalse(poll.hasTranslation(for: .french))
        XCTAssertFalse(Poll.mock(name: "Lunch").hasTranslation(for: .spanish))
    }

    func test_pollOption_translatedText() {
        let option = PollOption(text: "Soup", translations: [.spanish: "Sopa"], originalLanguage: .english)

        XCTAssertEqual(option.translatedText(for: .spanish), "Sopa")
        XCTAssertNil(option.translatedText(for: .english))
        XCTAssertNil(option.translatedText(for: .french))
    }

    func test_pollVote_translatedAnswerText() {
        let vote = PollVote.mock(
            isAnswer: true,
            answerText: "Fish, please",
            answerTextTranslations: [.spanish: "Pescado, por favor"],
            originalLanguage: .english
        )

        XCTAssertEqual(vote.translatedAnswerText(for: .spanish), "Pescado, por favor")
        XCTAssertNil(vote.translatedAnswerText(for: .english))
        XCTAssertNil(PollVote.mock(answerTextTranslations: [.spanish: "Hola"]).translatedAnswerText(for: .spanish))
    }

    func test_nameInLanguage() {
        let poll = Poll.mock(name: "Lunch", nameTranslations: [.spanish: "Almuerzo"], originalLanguage: .english)

        XCTAssertEqual(poll.name(in: .spanish), "Almuerzo")
        XCTAssertEqual(poll.name(in: .french), "Lunch")
        XCTAssertEqual(poll.name(in: nil), "Lunch")
    }

    func test_textInLanguage_whenTranslationIsEmpty_returnsOriginalText() {
        let poll = Poll.mock(name: "Lunch", nameTranslations: [.spanish: ""], originalLanguage: .english)
        let option = PollOption(text: "Soup", translations: [.spanish: ""], originalLanguage: .english)
        let vote = PollVote.mock(answerText: "Fish", answerTextTranslations: [.spanish: ""], originalLanguage: .english)

        XCTAssertNil(poll.translatedName(for: .spanish))
        XCTAssertEqual(poll.name(in: .spanish), "Lunch")
        XCTAssertEqual(option.text(in: .spanish), "Soup")
        XCTAssertEqual(vote.answerText(in: .spanish), "Fish")
    }

    func test_pollOption_textInLanguage() {
        let option = PollOption(text: "Soup", translations: [.spanish: "Sopa"], originalLanguage: .english)

        XCTAssertEqual(option.text(in: .spanish), "Sopa")
        XCTAssertEqual(option.text(in: .english), "Soup")
        XCTAssertEqual(option.text(in: nil), "Soup")
    }

    func test_pollVote_answerTextInLanguage() {
        let vote = PollVote.mock(
            isAnswer: true,
            answerText: "Fish, please",
            answerTextTranslations: [.spanish: "Pescado, por favor"],
            originalLanguage: .english
        )

        XCTAssertEqual(vote.answerText(in: .spanish), "Pescado, por favor")
        XCTAssertEqual(vote.answerText(in: .french), "Fish, please")
        XCTAssertEqual(vote.answerText(in: nil), "Fish, please")
        XCTAssertNil(PollVote.mock(answerText: nil).answerText(in: .spanish))
    }

    func test_equality_comparesTranslations() {
        let createdAt = Date()
        let poll = Poll.mock(createdAt: createdAt, id: "poll", name: "Lunch")
        let samePoll = Poll.mock(createdAt: createdAt, id: "poll", name: "Lunch")
        let translatedPoll = Poll.mock(
            createdAt: createdAt,
            id: "poll",
            name: "Lunch",
            nameTranslations: [.spanish: "Almuerzo"]
        )

        XCTAssertEqual(poll, samePoll)
        XCTAssertNotEqual(poll, translatedPoll)
    }
}
