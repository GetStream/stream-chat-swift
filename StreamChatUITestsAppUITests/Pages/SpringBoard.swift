//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

enum SpringBoard {
    static var bundleId = "com.apple.springboard"

    static var app: XCUIApplication {
        XCUIApplication(bundleIdentifier: bundleId)
    }

    static var notificationBanner: XCUIElement {
        app.otherElements["Notification"]
           .descendants(matching: .any)
           .matching(NSPredicate(format: "label CONTAINS[c] ', now,'"))
           .firstMatch
    }

    static var testAppIcon: XCUIElement {
        app.icons["Chat UI Tests"]
    }
}
