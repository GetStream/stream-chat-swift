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

    func test_updateContent_whenCompressingSingleVideo_thenTitleDoesNotShowThePosition() {
        vc.content = .init(phase: .compressing, currentVideo: 1, numberOfVideos: 1, progress: 0.25)

        XCTAssertEqual(vc.titleLabel.text, L10n.Composer.VideoCompression.compressing)
        XCTAssertEqual(vc.progressView.progress, 0.25)
    }

    func test_updateContent_whenCompressingMultipleVideos_thenTitleShowsThePosition() {
        vc.content = .init(phase: .compressing, currentVideo: 2, numberOfVideos: 3, progress: 0.5)

        XCTAssertEqual(vc.titleLabel.text, L10n.Composer.VideoCompression.compressingMultiple(2, 3))
        XCTAssertEqual(vc.progressView.progress, 0.5)
    }

    func test_updateContent_whenPreparingSingleVideo_thenTitleDescribesThePreparation() {
        vc.content = .init(phase: .preparing, currentVideo: 1, numberOfVideos: 1, progress: 0.3)

        XCTAssertEqual(vc.titleLabel.text, L10n.Composer.VideoCompression.preparing)
        XCTAssertEqual(vc.progressView.progress, 0.3)
    }

    func test_updateContent_whenPreparingMultipleVideos_thenTitleShowsThePosition() {
        vc.content = .init(phase: .preparing, currentVideo: 2, numberOfVideos: 3, progress: 0.1)

        XCTAssertEqual(vc.titleLabel.text, L10n.Composer.VideoCompression.preparingMultiple(2, 3))
    }

    func test_updateContent_whenOnlyThePhaseChanges_thenTheTitleIsUpdated() {
        vc.content = .init(phase: .preparing, currentVideo: 1, numberOfVideos: 1, progress: 1)

        vc.content = .init(phase: .compressing, currentVideo: 1, numberOfVideos: 1, progress: 1)

        XCTAssertEqual(vc.titleLabel.text, L10n.Composer.VideoCompression.compressing)
    }

    func test_updateContent_whenContentDoesNotChange_thenProgressIsNotUpdated() {
        vc.content = .init(phase: .compressing, currentVideo: 1, numberOfVideos: 1, progress: 0.5)
        vc.progressView.setProgress(0, animated: false)

        vc.content = .init(phase: .compressing, currentVideo: 1, numberOfVideos: 1, progress: 0.5)

        XCTAssertEqual(vc.progressView.progress, 0)
    }

    func test_cancelButtonTapped_whenTapped_thenOnCancelIsCalled() {
        var cancelCallCount = 0
        vc.onCancel = { cancelCallCount += 1 }

        vc.cancelButton.simulateEvent(.touchUpInside)

        XCTAssertEqual(cancelCallCount, 1)
    }

    func test_progressView_whenContentIsSet_thenAccessibilityLabelDescribesTheProgress() {
        vc.content = .init(phase: .compressing, currentVideo: 1, numberOfVideos: 2, progress: 0.1)

        XCTAssertEqual(vc.progressView.accessibilityLabel, L10n.Composer.VideoCompression.compressingMultiple(1, 2))
    }
}
