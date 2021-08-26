//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
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

    func test_appearanceCustomization_usingAppearance() {
        var appearance = Appearance()
        appearance.colorPalette.subtitleText = .brown
        appearance.fonts.bodyBold = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .heavy)
        appearance.colorPalette.popoverBackground = UIColor.blue.withAlphaComponent(0.5)
        fileAttachmentView = ChatMessageFileAttachmentListView.ItemView()
            .withoutAutoresizingMaskConstraints
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
