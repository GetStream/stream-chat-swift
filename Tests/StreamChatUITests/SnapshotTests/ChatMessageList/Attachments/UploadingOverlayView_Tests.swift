//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import UIKit
import XCTest

@MainActor final class UploadingOverlayView_Tests: XCTestCase {
    private var overlayView: UploadingOverlayView!

    override func setUp() {
        super.setUp()

        overlayView = UploadingOverlayView()
            .withoutAutoresizingMaskConstraints
        overlayView.components = .mock
        overlayView.pin(anchors: [.width, .height], to: 200)
    }

    override func tearDown() {
        overlayView = nil

        super.tearDown()
    }

    func test_appearance_whenUploadingFailed() throws {
        overlayView.content = try .mock(state: .uploadingFailed)

        AssertSnapshot(overlayView, variants: [.defaultLight, .defaultDark])
    }

    func test_appearance_whenUploading() throws {
        overlayView.content = try .mock(state: .uploading(progress: 0.42))

        AssertSnapshot(overlayView, variants: [.defaultLight, .defaultDark])
    }
}
