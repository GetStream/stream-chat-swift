//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
import XCTest

@MainActor final class VideoCompressionProgressVC_Tests: XCTestCase {
    private var vc: VideoCompressionProgressVC!

    override func setUp() {
        super.setUp()
        vc = VideoCompressionProgressVC()
        vc.loadViewIfNeeded()
    }

    override func tearDown() {
        vc = nil
        super.tearDown()
    }

    func test_updateContent_whenProgressIsSet_thenTheProgressViewIsUpdated() {
        vc.content = .init(progress: 0.25)

        XCTAssertEqual(vc.progressView.progress, 0.25)
    }

    func test_setUp_thenTheTitleDescribesThePreparation() {
        XCTAssertEqual(vc.titleLabel.text, L10n.Composer.VideoCompression.preparing)
    }

    func test_updateContent_whenContentDoesNotChange_thenProgressIsNotUpdated() {
        vc.content = .init(progress: 0.5)
        vc.progressView.setProgress(0, animated: false)

        vc.content = .init(progress: 0.5)

        XCTAssertEqual(vc.progressView.progress, 0)
    }

    func test_cancelButtonTapped_whenTapped_thenOnCancelIsCalled() {
        var cancelCallCount = 0
        vc.onCancel = { cancelCallCount += 1 }

        vc.cancelButton.simulateEvent(.touchUpInside)

        XCTAssertEqual(cancelCallCount, 1)
    }

    func test_progressView_thenAccessibilityLabelDescribesTheProgress() {
        XCTAssertEqual(vc.progressView.accessibilityLabel, L10n.Composer.VideoCompression.preparing)
    }
}
