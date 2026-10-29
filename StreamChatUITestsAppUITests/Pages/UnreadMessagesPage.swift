//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

enum UnreadMessagesPage {
    static var unreadSeparator: XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "identifier == 'textLabel' AND label BEGINSWITH 'UNREAD MESSAGE'")).firstMatch
    }

    static var jumpToUnreadButton: XCUIElement { app.buttons["JumpToUnreadMessagesButton"] }

    static var jumpToUnreadButtonText: XCUIElement {
        jumpToUnreadButton.staticTexts.matching(NSPredicate(format: "label != ''")).firstMatch
    }

    static var markUnreadAction: XCUIElement { app.otherElements["MarkUnreadActionItem"] }

    static func channelUnreadCount(in cell: XCUIElement) -> XCUIElement {
        ChannelListPage.Attributes.readCount(in: cell)
    }
}
