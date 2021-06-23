//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ImageGalleryVC_Tests: XCTestCase {
    private var vc: ImageGalleryVC!
    private var content: ChatMessage!
    
    override func setUp() {
        super.setUp()
        
        content = .mock(
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
        )
        
        vc = ImageGalleryVC()
        vc.initialAttachment = content.imageAttachments[0]
        vc.content = content
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
        class TestView: ImageGalleryVC {
            override var closeButton: CloseButton {
                let button = CloseButton()
                button.setTitle("Test title", for: .normal)
                return button
            }
        }

        let vc = TestView()
        vc.initialAttachment = content.imageAttachments[0]
        vc.content = content

        AssertSnapshot(vc)
    }
}
