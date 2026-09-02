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
        XCTAssertFalse(view.processingOverlayView.isOpaque)
        XCTAssertEqual(view.processingOverlayView.backgroundColor, .clear)
        XCTAssertEqual(view.processingOverlayView.accessibilityLabel, L10n.Composer.VideoCompression.preparing)
        XCTAssertTrue(view.processingIndicator.isAnimating)
    }

    func test_whenPreviewImageIsSet_thenTheImageIsShownUnderTheOverlay() {
        let view = ProcessingAttachmentComposerPreview()
        let image = UIImage()
        view.content = .init(previewImage: image, type: .image)
        UIView().addSubview(view)

        XCTAssertEqual(view.imageView.image, image)
        XCTAssertFalse(view.processingOverlayView.isHidden)
        XCTAssertFalse(view.processingOverlayView.isOpaque)
    }
}