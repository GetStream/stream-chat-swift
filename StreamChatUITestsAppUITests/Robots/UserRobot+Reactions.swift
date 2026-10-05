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
        attributes.reactionButton(in: messageCell).wait().safeTap()
        return self
    }
}

// MARK: Asserts

extension UserRobot {
    @discardableResult
    func assertReactionAuthor(
        _ authorName: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let author = MessageListPage.Reactions.author(authorName).wait()
        XCTAssertTrue(author.exists, "Reaction author \(authorName) is not shown", file: file, line: line)
        return self
    }
}

extension MessageListPage.Reactions {
    static func author(_ name: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "identifier == 'reactionAuthorNameLabel' AND label == %@", name)).firstMatch
    }
}
