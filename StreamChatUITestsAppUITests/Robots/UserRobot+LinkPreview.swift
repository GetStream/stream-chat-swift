//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

extension UserRobot {
    @discardableResult
    func tapOnLinkPreviewCancelButton() -> Self {
        ComposerLinkPreviewPage.closeButton.wait().safeTap()
        return self
    }

    @discardableResult
    func tapOnSendButton() -> Self {
        composer.sendButton.wait().safeTap()
        return self
    }

    @discardableResult
    func assertLinkPreviewInComposer(
        isDisplayed: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let preview = ComposerLinkPreviewPage.self
        if isDisplayed {
            XCTAssertTrue(preview.title.wait().isHittable, "Link preview title is not displayed in composer", file: file, line: line)
            XCTAssertTrue(preview.description.isHittable, "Link preview description is not displayed in composer", file: file, line: line)
            XCTAssertTrue(preview.image.isHittable, "Link preview image is not displayed in composer", file: file, line: line)
        } else {
            XCTAssertFalse(preview.title.waitForDisappearance().exists, "Link preview title is displayed in composer", file: file, line: line)
            XCTAssertFalse(preview.description.exists, "Link preview description is displayed in composer", file: file, line: line)
            XCTAssertFalse(preview.image.exists, "Link preview image is displayed in composer", file: file, line: line)
        }
        return self
    }

    @discardableResult
    func assertLinkPreviewInMessageList(
        isDisplayed: Bool,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        if isDisplayed {
            return assertLinkPreview(at: messageCellIndex, file: file, line: line)
        }
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let link = attributes.LinkPreview.self
        XCTAssertTrue(link.link(in: messageCell).wait().isHittable, "Link itself is not clickable", file: file, line: line)
        XCTAssertFalse(link.title(in: messageCell).exists, "Link preview title is displayed", file: file, line: line)
        XCTAssertFalse(link.description(in: messageCell).exists, "Link preview description is displayed", file: file, line: line)
        XCTAssertFalse(link.image(in: messageCell).exists, "Link preview image is displayed", file: file, line: line)
        return self
    }
}
