//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
import UIKit
import XCTest

final class ChatFileAttachmentListView_Tests: XCTestCase {
    private var fileAttachmentListView: ChatMessageFileAttachmentListView!
    private var vc: UIViewController!
    
    override func setUp() {
        super.setUp()
        fileAttachmentListView = ChatMessageFileAttachmentListView().withoutAutoresizingMaskConstraints
    }
    
    override func tearDown() {
        fileAttachmentListView = nil

        super.tearDown()
    }

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
}
