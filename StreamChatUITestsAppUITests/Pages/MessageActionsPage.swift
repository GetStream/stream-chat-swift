//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatCommonUI
import XCTest

extension MessageListPage.Composer {
    static var pasteButton: XCUIElement { app.menuItems.matching(NSPredicate(format: "label LIKE 'Paste'")).firstMatch }
}

extension MessageListPage {
    enum ConfirmationAlert {
        static var alert: XCUIElement { app.alerts.firstMatch }
        static var flagButton: XCUIElement { alert.buttons[L10n.Alert.Actions.flag] }
    }

    static func cell(withText text: String) -> XCUIElement {
        cells.containing(NSPredicate(format: "identifier == 'textView' AND value == %@", text)).firstMatch
    }

    /// Dismisses the message actions popup by tapping outside of the message and its actions.
    static func dismissMessageActions() {
        // A corner is used because message bubbles are inset from the screen edges, so no message length reaches it.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.15)).tap()
        ContextMenu.copy.element.waitForDisappearance()
    }
}
