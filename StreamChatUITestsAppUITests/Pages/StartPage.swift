//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

enum StartPage {
    static var startButton: XCUIElement { app.buttons["TestApp.Start"] }
    static var startAsSecondUserButton: XCUIElement { app.buttons["TestApp.StartAsSecondUser"] }
}
