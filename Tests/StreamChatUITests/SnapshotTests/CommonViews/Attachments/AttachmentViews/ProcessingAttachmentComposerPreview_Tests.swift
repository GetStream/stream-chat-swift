//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
import XCTest

@MainActor final class ProcessingAttachmentComposerPreview_Tests: XCTestCase {
    func test_whenContentIsSet_thenTheOverlayIsVisible() {
        let view = ProcessingAttachmentComposerPreview()
        view.content = .init(previewImage: nil, type: .video)
        UIView().addSubview(view)

        XCTAssertNil(view.imageView.image)
        XCTAssertFalse(view.uploadingOverlay.isHidden)
        XCTAssertEqual(view.uploadingOverlay.accessibilityLabel, L10n.Composer.MediaProcessing.Accessibility.preparingVideo)
        let formattedZero = view.appearance.formatters.uploadingProgress.format(0)
        XCTAssertEqual(view.uploadingOverlay.accessibilityValue, formattedZero)
        XCTAssertFalse(view.uploadingOverlay.loadingIndicator.isHidden)
        XCTAssertEqual(view.uploadingOverlay.uploadingProgressLabel.text, formattedZero)
    }

    func test_whenPreviewImageIsSet_thenTheImageIsShownUnderTheOverlay() {
        let view = ProcessingAttachmentComposerPreview()
        let image = UIImage()
        view.content = .init(previewImage: image, type: .image)
        UIView().addSubview(view)

        XCTAssertEqual(view.imageView.image, image)
        XCTAssertTrue(view.uploadingOverlay.isHidden)
        XCTAssertTrue(view.isAccessibilityElement)
        XCTAssertEqual(view.accessibilityLabel, L10n.Composer.MediaProcessing.Accessibility.preparingPhoto)
    }

    func test_whenContentIsAnImage_thenTheCompressionOverlayIsHidden() {
        let view = ProcessingAttachmentComposerPreview()
        view.content = .init(previewImage: nil, type: .image)
        UIView().addSubview(view)

        XCTAssertTrue(view.uploadingOverlay.isHidden)
        XCTAssertFalse(view.uploadingOverlay.isAccessibilityElement)
    }

    func test_whenProgressChanges_thenThePercentageIsUpdated() {
        let view = ProcessingAttachmentComposerPreview()
        view.content = .init(previewImage: nil, type: .video)
        let parent = UIView()
        parent.addSubview(view)

        view.progress = 0.42

        let formatted = view.appearance.formatters.uploadingProgress.format(0.42)
        XCTAssertEqual(view.uploadingOverlay.uploadingProgressLabel.text, formatted)
        XCTAssertEqual(view.uploadingOverlay.accessibilityValue, formatted)
    }
}
