//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

enum SpringBoard {
    static var bundleId = "com.apple.springboard"
    
    static var notificationBanner: XCUIElement {
        XCUIApplication(bundleIdentifier: bundleId)
            .otherElements["Notification"]
            .descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] ', now,'"))
            .firstMatch
    }
    
    static var appIcon: XCUIElement {
        return XCUIApplication(bundleIdentifier: bundleId).icons["Chat UI Tests"]
    }
}
