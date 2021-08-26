//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class GalleryVC_Tests: XCTestCase {
    private var vc: GalleryVC!
    private var content: GalleryVC.Content!
    
    override func setUp() {
        super.setUp()
        
        content = .init(
            message: .mock(
                id: .unique,
                cid: .unique,
                text: "",
                author: .mock(
                    id: .unique,
                    name: "Author"
                ),
                createdAt: Date(timeIntervalSinceReferenceDate: 0),
                attachments: [
                    ChatMessageImageAttachment.mock(
                        id: .unique,
                        imageURL: TestImages.yoda.url
                    ).asAnyAttachment,
                    ChatMessageImageAttachment.mock(
                        id: .unique,
                        imageURL: TestImages.chewbacca.url
                    ).asAnyAttachment
                ]
            ),
            currentPage: 0
        )
        
        vc = GalleryVC()
        vc.components = .mock
        vc.content = content
        vc.attachmentsCollectionView.reloadData()
    }
    
    override func tearDown() {
        content = nil
        vc = nil
        
        super.tearDown()
    }
    
    func test_defaultAppearance() {
        AssertSnapshot(vc)
    }
    
    func test_appearanceCustomization_usingUIConfig() {
        var appearance = Appearance()
        appearance.colorPalette.popoverBackground = .cyan

        vc.appearance = appearance

        AssertSnapshot(vc)
    }
    
    func test_appearanceCustomization_usingSubclassing() {
        class TestView: GalleryVC {
            override var closeButton: UIButton {
                let button = CloseButton()
                button.setTitle("Test title", for: .normal)
                return button
            }
        }

        let vc = TestView()
        vc.components = .mock
        vc.content = content

        AssertSnapshot(vc)
    }
}
