//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

class ThreadPage: MessageListPage {

    static var alsoSendInChannelCheckbox: XCUIElement { app.otherElements["CheckboxControl"] }
    static var repliesCountLabel: XCUIElement { app.staticTexts["textLabel"] }

    enum NavigationBar {

        static var header: XCUIElement { app.otherElements["ChatThreadHeaderView"] }

        static var channelName: XCUIElement {
            header.staticTexts.lastMatch!
        }
    }

}
