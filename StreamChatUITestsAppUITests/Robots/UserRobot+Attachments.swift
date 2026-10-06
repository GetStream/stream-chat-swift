//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

extension UserRobot {
    @discardableResult
    func attachImages(count: Int = 1) -> Self {
        uploadImage(count: count, send: false)
    }

    @discardableResult
    func attachFiles(count: Int = 1) -> Self {
        LocalFiles.seed()
        MessageListPage.Composer.attachmentButton.wait(timeout: XCUIElement.longWaitTimeout).safeTap()
        MessageListPage.AttachmentMenu.fileButton.wait(timeout: XCUIElement.longWaitTimeout).safeTap()
        openLocalFilesInDocumentPicker()
        for name in LocalFiles.pdfNames.prefix(count) {
            DocumentPickerPage.file(named: name).wait().safeTap()
        }
        let openButton = DocumentPickerPage.openButton
        if openButton.waitForExistence(timeout: XCUIElement.probeTimeout) {
            openButton.safeTap()
        }
        _ = composer.inputField.waitForHitPoint(timeout: XCUIElement.longWaitTimeout)
        return self
    }

    @discardableResult
    func assertMediaAttachmentInPreview(
        isDisplayed: Bool,
        count: Int = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        assertComposerAttachments(ComposerAttachmentsPage.images, isDisplayed: isDisplayed, count: count, file: file, line: line)
    }

    @discardableResult
    func assertFileAttachmentInPreview(
        isDisplayed: Bool,
        count: Int = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        assertComposerAttachments(ComposerAttachmentsPage.files, isDisplayed: isDisplayed, count: count, file: file, line: line)
    }

    private func assertComposerAttachments(
        _ attachments: XCUIElementQuery,
        isDisplayed: Bool,
        count: Int,
        file: StaticString,
        line: UInt
    ) -> Self {
        if isDisplayed {
            XCTAssertEqual(count, attachments.waitCount(count).count, "Wrong number of attachments in composer", file: file, line: line)
            XCTAssertEqual(count, ComposerAttachmentsPage.removeButtons.count, "Wrong number of remove buttons in composer", file: file, line: line)
        } else {
            XCTAssertFalse(attachments.firstMatch.waitForDisappearance().exists, "Attachments are displayed in composer", file: file, line: line)
            XCTAssertEqual(0, ComposerAttachmentsPage.removeButtons.count, "Remove buttons are displayed in composer", file: file, line: line)
        }
        return self
    }

    @discardableResult
    func assertImages(
        isDisplayed: Bool,
        count: Int = 1,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let images = attributes.images(in: messageCell)
        if isDisplayed {
            XCTAssertEqual(count, images.waitCount(count).count, "Wrong number of images", file: file, line: line)
            let uploadingProgress = attributes.uploadingProgressLabel(in: messageCell).waitForDisappearance()
            XCTAssertFalse(uploadingProgress.exists, "Image uploading has not finished", file: file, line: line)
        } else {
            XCTAssertFalse(images.firstMatch.waitForDisappearance().exists, "Images are displayed", file: file, line: line)
        }
        return self
    }

    /// The document picker reopens the last visited location, so it may already show the local files.
    private func openLocalFilesInDocumentPicker() {
        let firstFile = DocumentPickerPage.file(named: LocalFiles.pdfNames[0])
        if firstFile.waitForExistence(timeout: XCUIElement.waitTimeout) { return }
        if DocumentPickerPage.browseTab.exists {
            DocumentPickerPage.browseTab.safeTap()
            if firstFile.waitForExistence(timeout: XCUIElement.probeTimeout) { return }
        }
        DocumentPickerPage.onMyDeviceLocation.wait().safeTap()
    }

    /// Opens the image at the given position (from the left) of the message in the full-screen gallery.
    @discardableResult
    func openImageInGallery(imageIndex: Int = 0, messageCellIndex: Int? = nil) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex)
        let images = attributes.images(in: messageCell).waitCount(imageIndex + 1).allElementsBoundByIndex
        let sortedImages = images.sorted { $0.frame.minX < $1.frame.minX }
        sortedImages[imageIndex].waitForHitPoint().safeTap()
        return self
    }

    @discardableResult
    func swipeToNextImageInGallery() -> Self {
        app.swipeLeft()
        return self
    }

    @discardableResult
    func assertGalleryPosition(
        _ position: Int,
        of count: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let expected = "\(position) of \(count)"
        let counter = app.staticTexts["currentPhotoLabel"]
        XCTAssertEqual(expected, counter.wait().waitForText(expected).text, file: file, line: line)
        return self
    }
}
