//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import UIKit
import XCTest

final class ChatMessageVoiceRecordingAttachmentListView_Tests: XCTestCase {
    private var subject: ChatMessageVoiceRecordingAttachmentListView! = .init().withoutAutoresizingMaskConstraints

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - appearance

    func test_appearance_one_attachment() {
        subject.content = [.mock(id: .unique)]
        AssertSnapshot(subject)
    }

    func test_appearance_two_attachments() {
        subject.content = [
            .mock(id: .unique),
            .mock(id: .unique, title: "Test Title")
        ]

        AssertSnapshot(subject)
    }

    func test_appearance_five_attachments() {
        subject.content = [
            .mock(
                id: .unique
            ),
            .mock(
                id: .unique,
                title: "Sample2",
                file: .init(type: .aac, size: 400, mimeType: nil),
                localState: .uploaded
            ),
            .mock(
                id: .unique,
                title: "Sample3",
                file: .init(type: .aac, size: 3600, mimeType: nil),
                localState: .uploaded
            ),
            .mock(
                id: .unique,
                title: "Sample4",
                file: .init(type: .aac, size: 18320, mimeType: nil),
                localState: .uploaded
            ),
            .mock(
                id: .unique,
                title: "Sample5",
                file: .init(type: .aac, size: 500_000, mimeType: nil),
                localState: .uploaded
            )
        ]

        AssertSnapshot(subject)
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatMessageVoiceRecordingAttachmentListView {
            override func setUpLayout() {
                super.setUpLayout()

                containerStackView.axis = .horizontal
                containerStackView.spacing = 20
            }
        }

        let subject = TestView().withoutAutoresizingMaskConstraints

        subject.content = [
            .mock(
                id: .unique
            ),
            .mock(
                id: .unique,
                title: "Sample2",
                file: .init(type: .aac, size: 400, mimeType: nil),
                localState: .uploaded
            ),
            .mock(
                id: .unique,
                title: "Sample3",
                file: .init(type: .aac, size: 3600, mimeType: nil),
                localState: .uploaded
            ),
            .mock(
                id: .unique,
                title: "Sample4",
                file: .init(type: .aac, size: 18320, mimeType: nil),
                localState: .uploaded
            ),
            .mock(
                id: .unique,
                title: "Sample5",
                file: .init(type: .aac, size: 500_000, mimeType: nil),
                localState: .uploaded
            )
        ]

        AssertSnapshot(subject)
    }

    // MARK: - updateContent

    func test_updateContent_arrangedSubviewsHaveTheirDelegateAndIndexProviderSetCorrectly() throws {
        let playbackDelegate = MockVoiceRecordingAttachmentPresentationViewDelegate()
        subject.playbackDelegate = playbackDelegate

        subject.content = [
            .mock(id: .unique),
            .mock(id: .unique, title: "Test Title")
        ]

        let subviews = try XCTUnwrap(subject.containerStackView.arrangedSubviews as? [ChatMessageVoiceRecordingAttachmentListView.ItemView])
        subviews.enumerated().forEach { entry in
            XCTAssertTrue(entry.element.presenter.delegate === playbackDelegate)
            XCTAssertEqual(entry.element.indexProvider?(), entry.offset)
        }
    }
}
