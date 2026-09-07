//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

@MainActor final class VideoAttachmentComposerPreview_Tests: XCTestCase {
    func test_whenContentIsSet_videoLoadingComponentIsInvoked() throws {
        // Create mock components
        let components: Components = .mock

        // Create a view and inject components
        let view = VideoAttachmentComposerPreview()
        view.components = components

        // Set the content
        let url = URL.unique()
        view.content = url

        // Add view to view heirarchy to trigger lifecycle methods
        UIView().addSubview(view)

        // Assert injected loader is invoked with correct values
        XCTAssertEqual(components.mockMediaLoader.loadVideoPreviewAtURLMockFunc.calls.map(\.0), [url])
        XCTAssertEqual(components.mockMediaLoader.videoAssetMockFunc.calls.map(\.0), [url])
    }

    func test_whenIsProcessing_thenTheOverlayIsVisible() {
        let view = VideoAttachmentComposerPreview()
        view.isProcessing = true
        view.progress = 0.42
        UIView().addSubview(view)

        XCTAssertFalse(view.uploadingOverlay.isHidden)
        XCTAssertFalse(view.uploadingOverlay.loadingIndicator.isHidden)
        let formatted = view.appearance.formatters.uploadingProgress.format(0.42)
        XCTAssertEqual(view.uploadingOverlay.uploadingProgressLabel.text, formatted)
        XCTAssertEqual(view.uploadingOverlay.accessibilityLabel, L10n.Composer.VideoCompression.compressing)
        XCTAssertEqual(view.uploadingOverlay.accessibilityValue, formatted)
    }
}
