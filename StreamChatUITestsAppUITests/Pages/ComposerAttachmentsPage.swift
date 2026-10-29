//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

enum ComposerAttachmentsPage {
    static var container: XCUIElement { app.otherElements["attachmentsViewContainer"] }
    static var images: XCUIElementQuery { container.otherElements.matching(identifier: "ImageAttachmentComposerPreview") }
    static var files: XCUIElementQuery { container.otherElements.matching(identifier: "FileAttachmentView") }
    static var removeButtons: XCUIElementQuery {
        container.otherElements.matching(identifier: "AttachmentPreviewContainer").buttons
    }
}
