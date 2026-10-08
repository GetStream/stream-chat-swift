//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

final class Polls_Tests: StreamTestCase {
    private let question = "Best color?"
    private let firstOption = "Red"
    private let secondOption = "Blue"
    private var options: [String] { [firstOption, secondOption] }

    func test_optionIsUnchecked_whenUserRemovesPollVote() throws {
        linkToScenario(withId: 11938)

        GIVEN("user creates a poll and votes") {
            userRobot
                .login()
                .openChannel()
                .createPoll(question: question, options: options)
                .castPollVote(firstOption)
                .assertPollOption(firstOption, isChecked: true)
        }
        WHEN("user taps on the voted option again") {
            userRobot.removePollVote(firstOption)
        }
        THEN("the option is unchecked") {
            userRobot.assertPollOption(firstOption, isChecked: false)
        }
    }

    func test_participantVoteIsShownInPollResults_whenParticipantVotesInPoll() throws {
        linkToScenario(withId: 11939)

        GIVEN("user creates a poll") {
            userRobot
                .login()
                .openChannel()
                .createPoll(question: question, options: options)
                .assertMessageDeliveryStatus(.sent)
        }
        AND("participant votes for an option") {
            participantRobot.castPollVote(option: firstOption)
        }
        WHEN("user opens the poll results") {
            userRobot
                .assertPollOptionVoteCount(firstOption, count: 1)
                .openPollResults()
        }
        THEN("the participant vote is shown") {
            userRobot.assertPollResults(voterName: participantRobot.name)
        }
    }

    func test_pollIsClosed_whenUserEndsPoll() throws {
        linkToScenario(withId: 11940)

        GIVEN("user creates a poll") {
            userRobot
                .login()
                .openChannel()
                .createPoll(question: question, options: options)
                .assertPollOption(firstOption)
        }
        WHEN("user ends the poll") {
            userRobot.endPoll()
        }
        THEN("the poll is shown as ended") {
            userRobot.assertPollClosed()
        }
    }

    // MARK: - iOS only

    func test_userVotesForSeveralOptions_whenPollAllowsMultipleVotes() throws {
        linkToScenario(withId: 11941)

        GIVEN("user creates a poll that allows multiple votes") {
            userRobot
                .login()
                .openChannel()
                .createPoll(question: question, options: options, multipleVotes: true)
                .assertPollMessage(question: question, multipleVotes: true)
        }
        WHEN("user votes for both options") {
            userRobot
                .castPollVote(firstOption)
                .assertPollOption(firstOption, isChecked: true)
                .castPollVote(secondOption)
        }
        THEN("both options are checked") {
            userRobot
                .assertPollOption(secondOption, isChecked: true)
                .assertPollOption(firstOption, isChecked: true)
        }
    }
}
