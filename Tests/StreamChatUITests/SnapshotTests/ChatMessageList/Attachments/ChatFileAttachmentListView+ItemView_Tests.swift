//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import UIKit
import XCTest

final class ChatFileAttachmentListViewItemView_Tests: XCTestCase {
    private var fileAttachmentView: ChatMessageFileAttachmentListView.ItemView!
    private var vc: UIViewController!

    override func setUp() {
        super.setUp()
        fileAttachmentView = ChatMessageFileAttachmentListView.ItemView().withoutAutoresizingMaskConstraints
    }

    override func tearDown() {
        fileAttachmentView = nil

        super.tearDown()
    }

    func test_appearance_pdf() {
        fileAttachmentView.content = .mock(id: .unique)
        AssertSnapshot(fileAttachmentView, variants: [.defaultLight])
    }
    
    func test_appearance_pdf_whenDownloadedThenShareIcon() throws {
        let oldValue = Components.default.isDownloadFileAttachmentsEnabled
        defer { Components.default.isDownloadFileAttachmentsEnabled = oldValue }
        Components.default.isDownloadFileAttachmentsEnabled = true
        fileAttachmentView.content = .mock(id: .unique, localState: nil, localDownloadState: .downloaded)
        AssertSnapshot(fileAttachmentView, variants: [.defaultLight])
        Components.default.isDownloadFileAttachmentsEnabled = false
    }

    func test_appearance_pdf_whenUploadingStateIsNil() {
        fileAttachmentView.content = .mock(id: .unique, localState: nil)
        AssertSnapshot(fileAttachmentView, variants: [.defaultLight])
    }

    func test_appearance_pdf_whenSizeIsZero() {
        fileAttachmentView.content = .mock(
            id: .unique,
            file: AttachmentFile(type: .pdf, size: 0, mimeType: "application/pdf"),
            localState: nil
        )
        AssertSnapshot(fileAttachmentView, variants: [.defaultLight])
    }

    func test_appearance_whenUnknown() {
        fileAttachmentView.content = .mock(
            id: .unique,
            file: AttachmentFile(type: .unknown, size: 0, mimeType: "weird"),
            localState: nil
        )
        AssertSnapshot(fileAttachmentView, variants: [.defaultLight])
    }

    func test_appearanceCustomization_usingAppearance() {
        var appearance = Appearance()
        appearance.colorPalette.subtitleText = .red
        appearance.fonts.bodyBold = UIFont.preferredFont(forTextStyle: .body).bold
        fileAttachmentView.appearance = appearance
        fileAttachmentView.components = .mock
        fileAttachmentView.content = .mock(id: .unique)

        AssertSnapshot(fileAttachmentView, variants: [.defaultLight])
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatMessageFileAttachmentListView.ItemView {
            override func setUpLayout() {
                super.setUpLayout()
                mainContainerStackView.spacing = 100
            }

            override func setUpAppearance() {
                super.setUpAppearance()
                actionIconImageView.tintColor = .green
            }
        }

        let fileAttachmentView = TestView().withoutAutoresizingMaskConstraints
        fileAttachmentView.content = .mock(id: .unique)

        AssertSnapshot(fileAttachmentView, variants: [.defaultLight])
    }
}
