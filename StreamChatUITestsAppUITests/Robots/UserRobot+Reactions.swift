//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

// MARK: Actions

extension UserRobot {
    @discardableResult
    func tapOnMessageReactions(at messageCellIndex: Int? = nil) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex)
        attributes.reactionButton(in: messageCell).firstMatch.wait().safeTap()
        return self
    }

    @discardableResult
    func closeReactionAuthors() -> Self {
        // A corner is used because message bubbles are inset from the screen edges, so no message length reaches it.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.15)).tap()
        MessageListPage.Reactions.authors.firstMatch.waitForDisappearance()
        return self
    }
}

// MARK: Asserts

extension UserRobot {
    @discardableResult
    func assertReactionAuthor(
        _ authorName: String,
        isPresent: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let author = MessageListPage.Reactions.author(authorName)
        _ = isPresent ? author.wait() : author.waitForDisappearance()
        let errMessage = isPresent ? "Reaction author \(authorName) is not shown" : "Reaction author \(authorName) is shown"
        XCTAssertEqual(isPresent, author.exists, errMessage, file: file, line: line)
        return self
    }
}

extension MessageListPage.Reactions {
    static var authors: XCUIElementQuery { app.cells.matching(identifier: "ChatMessageReactionAuthorViewCell") }

    static func author(_ name: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "identifier == 'reactionAuthorNameLabel' AND label == %@", name)).firstMatch
    }
}
