//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

enum SearchPage {
    static var field: XCUIElement { app.searchFields.firstMatch }

    static var results: XCUIElementQuery {
        app.collectionViews
            .matching(NSPredicate(format: "label == 'Search results'"))
            .cells
            .matching(identifier: "ChatChannelListCollectionViewCell")
    }

    static func channelName(in result: XCUIElement) -> XCUIElement {
        result.staticTexts["titleLabel"]
    }

    static func message(in result: XCUIElement) -> XCUIElement {
        result.staticTexts["subtitleLabel"]
    }
}
