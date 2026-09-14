//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import UIKit
import XCTest

@MainActor final class GalleryAttachmentViewInjector_Tests: XCTestCase {
    private var contentView: ChatMessageContentView!
    private var subject: GalleryAttachmentViewInjector!

    override func setUp() {
        super.setUp()
        contentView = .init()
        subject = .init(contentView)
        contentView.layoutOptions = [.bubble]
        subject.contentViewDidLayout(options: [.bubble])
        contentView.content = .mock(attachments: [.dummy(type: .image), .dummy(type: .image)])
    }

    override func tearDown() {
        subject = nil
        contentView = nil
        super.tearDown()
    }

    func test_contentViewDidUpdateContent_whenGalleryIsTopMostViewInBubble_masksTopCorners() {
        subject.contentViewDidUpdateContent()

        XCTAssertEqual(
            subject.galleryView.leftPreviewsContainerView.layer.maskedCorners,
            [.layerMinXMinYCorner]
        )
        XCTAssertEqual(
            subject.galleryView.rightPreviewsContainerView.layer.maskedCorners,
            [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        )
    }

    func test_contentViewDidUpdateContent_whenGalleryIsNotTopMostViewInBubble_doesNotMaskTopCorners() {
        insertVoiceRecordingOnTopOfGallery()

        subject.contentViewDidUpdateContent()

        XCTAssertEqual(subject.galleryView.leftPreviewsContainerView.layer.maskedCorners, [])
        XCTAssertEqual(
            subject.galleryView.rightPreviewsContainerView.layer.maskedCorners,
            [.layerMaxXMaxYCorner]
        )
    }

    func test_contentViewDidUpdateContent_whenNoCornersAreMasked_resetsCornerRadius() {
        insertVoiceRecordingOnTopOfGallery()

        subject.contentViewDidUpdateContent()

        // Core Animation ignores an empty corner mask, so the radius needs to be reset.
        XCTAssertEqual(subject.galleryView.leftPreviewsContainerView.layer.cornerRadius, 0)
        XCTAssertEqual(subject.galleryView.rightPreviewsContainerView.layer.cornerRadius, 16)
    }

    private func insertVoiceRecordingOnTopOfGallery() {
        VoiceRecordingAttachmentViewInjector(contentView).contentViewDidLayout(options: [.bubble])
    }
}
