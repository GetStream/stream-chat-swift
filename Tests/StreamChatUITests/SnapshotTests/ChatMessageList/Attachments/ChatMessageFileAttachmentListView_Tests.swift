//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import UIKit
import XCTest

final class ChatFileAttachmentListView_Tests: XCTestCase {
    private var fileAttachmentListView: ChatMessageFileAttachmentListView!
    private var vc: UIViewController!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        fileAttachmentListView = ChatMessageFileAttachmentListView().withoutAutoresizingMaskConstraints
    }

    override func tearDown() {
        fileAttachmentListView = nil
        vc = nil

        super.tearDown()
    }

    // MARK: - appearance

    func test_appearance_one_attachment() {
        fileAttachmentListView.content = [.mock(id: .unique)]
        AssertSnapshot(fileAttachmentListView, variants: [.defaultLight])
    }

    func test_appearance_two_attachments() {
        fileAttachmentListView.content = [
            .mock(
                id: .unique
            ),
            .mock(
                id: .unique,
                title: "Sample2",
                file: .init(type: .csv, size: 180, mimeType: nil),
                localState: .uploaded
            )
        ]
        AssertSnapshot(fileAttachmentListView, variants: [.defaultLight])
    }

    func test_appearance_five_attachments() {
        fileAttachmentListView.content = [
            .mock(
                id: .unique
            ),
            .mock(
                id: .unique,
                title: "Sample2",
                file: .init(type: .csv, size: 400, mimeType: nil),
                localState: .uploaded
            ),
            .mock(
                id: .unique,
                title: "Sample3",
                file: .init(type: .tar, size: 3600, mimeType: nil),
                localState: .uploaded
            ),
            .mock(
                id: .unique,
                title: "Sample4",
                file: .init(type: .mp3, size: 18320, mimeType: nil),
                localState: .uploaded
            ),
            .mock(
                id: .unique,
                title: "Sample5",
                file: .init(type: .xls, size: 500_000, mimeType: nil),
                localState: .uploaded
            )
        ]
        AssertSnapshot(fileAttachmentListView, variants: [.defaultLight])
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatMessageFileAttachmentListView {
            override func setUpLayout() {
                super.setUpLayout()

                containerStackView.axis = .horizontal
                containerStackView.spacing = 20
            }
        }

        let fileAttachmentListView = TestView().withoutAutoresizingMaskConstraints

        fileAttachmentListView.content = [
            .mock(
                id: .unique
            ),
            .mock(
                id: .unique,
                title: "Sample2",
                file: .init(type: .csv, size: 400, mimeType: nil),
                localState: .uploaded
            ),
            .mock(
                id: .unique,
                title: "Sample3",
                file: .init(type: .tar, size: 3600, mimeType: nil),
                localState: .uploaded
            ),
            .mock(
                id: .unique,
                title: "Sample4",
                file: .init(type: .mp3, size: 18320, mimeType: nil),
                localState: .uploaded
            ),
            .mock(
                id: .unique,
                title: "Sample5",
                file: .init(type: .xls, size: 500_000, mimeType: nil),
                localState: .uploaded
            )
        ]

        AssertSnapshot(fileAttachmentListView, variants: [.defaultLight])
    }

    // MARK: - prepareForReuse

    func test_prepareForReuse_callsPrepareForReuseOnSubviews() {
        final class SpyView: _View, Spy {
            var recordedFunctions: [String] = []
            override func prepareForReuse() { recordedFunctions.append(#function) }
        }

        let spyView = SpyView()
        fileAttachmentListView.containerStackView.addSubview(spyView)

        fileAttachmentListView.prepareForReuse()

        XCTAssertEqual(spyView.recordedFunctions, ["prepareForReuse()"])
    }

    // MARK: - contentUpdate

    func test_contentUpdate_defaultItemViewProviderCreatesExpectedResults() {
        let pdfAttachment = ChatMessageFileAttachment.mock(
            id: .unique,
            type: .file,
            file: .mock(type: .pdf)
        )

        let audioAttachment = ChatMessageFileAttachment.mock(
            id: .unique,
            type: .audio,
            file: .mock(type: .mp3)
        )

        fileAttachmentListView.content = [pdfAttachment, audioAttachment]

        AssertSnapshot(fileAttachmentListView)
    }
}
