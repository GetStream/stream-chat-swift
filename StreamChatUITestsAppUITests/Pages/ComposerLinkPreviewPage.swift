//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

enum ComposerLinkPreviewPage {
    static var view: XCUIElement { app.otherElements["ComposerLinkPreviewView"] }
    static var image: XCUIElement { view.images["imagePreviewView"] }
    static var title: XCUIElement { view.staticTexts["titleLabel"] }
    static var description: XCUIElement { view.staticTexts["descriptionLabel"] }
    static var closeButton: XCUIElement { view.buttons["closeButton"] }
}
