//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

// MARK: Actions

extension UserRobot {
    @discardableResult
    func createPoll(question: String, options: [String], multipleVotes: Bool = false) -> Self {
        MessageListPage.Composer.attachmentButton.wait().safeTap()
        PollsPage.attachmentMenuPollButton.wait().safeTap()
        let questionField = PollsPage.Creation.questionField.wait(timeout: XCUIElement.longWaitTimeout)
        // Toggled before typing, while the keyboard does not cover the setting.
        if multipleVotes {
            PollsPage.Creation.multipleVotesSwitch.wait().waitForHitPoint().safeTap()
        }
        questionField.safeTap()
        questionField.typeText(question)
        for (index, option) in options.enumerated() {
            let optionField = PollsPage.Creation.optionField(at: index).wait()
            optionField.safeTap()
            optionField.typeText(option)
        }
        PollsPage.Creation.createButton.wait().safeTap()
        return self
    }

    @discardableResult
    func castPollVote(_ option: String) -> Self {
        PollsPage.Message.checkbox(in: PollsPage.Message.option(option).wait()).wait().safeTap()
        return self
    }

    /// A tap on an option the user already voted for removes the vote.
    @discardableResult
    func removePollVote(_ option: String) -> Self {
        castPollVote(option)
    }

    @discardableResult
    func openPollResults() -> Self {
        PollsPage.Message.viewResultsButton.wait().safeTap()
        return self
    }

    @discardableResult
    func endPoll() -> Self {
        PollsPage.Message.endPollButton.wait().safeTap()
        PollsPage.Message.endPollConfirmationButton.wait().safeTap()
        return self
    }
}

// MARK: Asserts

extension UserRobot {
    @discardableResult
    func assertPollMessage(
        question: String,
        multipleVotes: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let subtitle = multipleVotes ? PollsPage.Message.multipleVotesSubtitle : PollsPage.Message.singleVoteSubtitle
        XCTAssertEqual(question, PollsPage.Message.title.wait().waitForText(question).label, file: file, line: line)
        XCTAssertEqual(subtitle, PollsPage.Message.subtitle.wait().waitForText(subtitle).label, file: file, line: line)
        return self
    }

    /// When `isChecked` is given, the option must also have that vote state, so the
    /// assertion waits out the round trip of a vote or its removal.
    @discardableResult
    func assertPollOption(
        _ option: String,
        isChecked: Bool? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let element = PollsPage.Message.option(option).wait()
        XCTAssertTrue(element.exists, "Poll option '\(option)' is not shown", file: file, line: line)
        if let isChecked {
            let checkbox = PollsPage.Message.checkbox(in: element)
            let expectedLabel = isChecked ? Self.checkedPollOptionLabel : Self.uncheckedPollOptionLabel
            XCTAssertEqual(expectedLabel, checkbox.wait().waitForText(expectedLabel).label, file: file, line: line)
        }
        return self
    }

    @discardableResult
    func assertPollOptionVoteCount(
        _ option: String,
        count: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let voteCount = PollsPage.Message.voteCount(in: PollsPage.Message.option(option).wait())
        XCTAssertEqual("\(count)", voteCount.wait().waitForText("\(count)").label, file: file, line: line)
        return self
    }

    @discardableResult
    func assertPollResults(voterName: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertTrue(PollsPage.Results.title.wait().exists, "Poll results are not shown", file: file, line: line)
        XCTAssertTrue(PollsPage.Results.voter(voterName).wait().exists, "Voter '\(voterName)' is not shown", file: file, line: line)
        return self
    }

    @discardableResult
    func assertPollClosed(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let subtitle = PollsPage.Message.closedSubtitle
        XCTAssertEqual(subtitle, PollsPage.Message.subtitle.wait().waitForText(subtitle).label, file: file, line: line)
        XCTAssertFalse(PollsPage.Message.endPollButton.waitForDisappearance().exists, "End poll button is still shown", file: file, line: line)
        return self
    }

    @discardableResult
    func assertPollComments(count: Int, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let expectedTitle = count == 1 ? "View 1 Comment" : "View \(count) Comments"
        let button = PollsPage.Message.commentsButton.wait()
        XCTAssertEqual(expectedTitle, button.waitForText(expectedTitle).label, file: file, line: line)
        return self
    }

    // The vote checkbox exposes no checked state; its label is derived from the SF Symbol it shows.
    private static let checkedPollOptionLabel = "selected"
    private static let uncheckedPollOptionLabel = "circle"
}
