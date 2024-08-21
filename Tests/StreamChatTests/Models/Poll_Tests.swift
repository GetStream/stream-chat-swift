//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
            ownVotes: [vote]
        )

        XCTAssertTrue(poll.hasCurrentUserVoted(for: option))
    }
}
