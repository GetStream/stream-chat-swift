//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

class ThreadPage: MessageListPage {
    
    static var alsoSendInChannelCheckbox: XCUIElement { app.otherElements["CheckboxControl"] }
    
    enum NavigationBar {
        
        static var header: XCUIElement { app.otherElements["ChatThreadHeaderView"] }
        
        static var channelName: XCUIElement {
            header.staticTexts.lastMatch!
        }
    }
    
}
