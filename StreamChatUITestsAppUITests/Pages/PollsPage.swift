//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

// The English copy is used directly so the queries don't depend on resolving the SDK bundle in the test runner.
enum PollsPage {
    static var attachmentMenuPollButton: XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == 'Create Poll'")).firstMatch
    }

    enum Creation {
        static var questionField: XCUIElement {
            app.textFields.matching(NSPredicate(format: "placeholderValue == 'Ask a question'")).firstMatch
        }

        static func optionField(at index: Int) -> XCUIElement {
            app.textFields
                .matching(NSPredicate(format: "placeholderValue == 'Add an option'"))
                .element(boundBy: index)
        }

        static var multipleVotesSwitch: XCUIElement { app.cells["PollCreationMultipleVotesFeatureCell"].switches.firstMatch }

        static var createButton: XCUIElement { app.buttons["createPollButton"] }
    }

    enum Message {
        static let singleVoteSubtitle = "Select one"
        static let multipleVotesSubtitle = "Select one or more"
        static let closedSubtitle = "Vote ended"

        static var title: XCUIElement { app.staticTexts["pollTitleLabel"] }

        static var subtitle: XCUIElement { app.staticTexts["pollSubtitleLabel"] }

        /// The option rows are not exposed as containers, so the row elements are matched by the option label's row.
        static func option(_ text: String) -> XCUIElement {
            app.staticTexts.matching(NSPredicate(format: "identifier == 'optionNameLabel' AND label == %@", text)).firstMatch
        }

        static func checkbox(in option: XCUIElement) -> XCUIElement {
            element(in: app.buttons.matching(identifier: "CheckboxButton"), onRowOf: option)
        }

        static func voteCount(in option: XCUIElement) -> XCUIElement {
            element(in: app.staticTexts.matching(identifier: "votesCountLabel"), onRowOf: option)
        }

        private static func element(in query: XCUIElementQuery, onRowOf option: XCUIElement) -> XCUIElement {
            let rowY = option.frame.minY
            return query.allElementsBoundByIndex.first { abs($0.frame.minY - rowY) < 2 } ?? query.element(boundBy: query.count)
        }

        static var viewResultsButton: XCUIElement { app.buttons["pollResultsButton"] }

        static var endPollButton: XCUIElement { app.buttons["endPollButton"] }

        static var endPollConfirmationButton: XCUIElement {
            app.buttons.matching(NSPredicate(format: "label == 'End'")).firstMatch
        }

        static var commentsButton: XCUIElement { app.buttons["pollCommentsButton"] }
    }

    enum Results {
        static var title: XCUIElement { app.navigationBars["Poll Results"] }

        static func voter(_ name: String) -> XCUIElement {
            app.staticTexts.matching(NSPredicate(format: "label == %@", name)).firstMatch
        }
    }
}
