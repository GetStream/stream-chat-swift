//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

enum ThreadListPage {
    static var openButton: XCUIElement { app.buttons["ThreadListButton"] }

    static var emptyView: XCUIElement {
        app.otherElements["ChatThreadListEmptyView"]
    }

    static var cells: XCUIElementQuery {
        app.cells.matching(NSPredicate(format: "identifier LIKE 'ChatThreadListItemCell'"))
    }

    enum Attributes {
        static func parentMessage(in cell: XCUIElement) -> XCUIElement {
            cell.staticTexts["threadDescriptionLabel"]
        }

        static func latestReply(in cell: XCUIElement) -> XCUIElement {
            cell.staticTexts["replyDescriptionLabel"]
        }
    }
}
