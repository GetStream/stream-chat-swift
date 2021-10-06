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
            message: makeMessage(with: [
                ChatMessageImageAttachment.mock(
                    id: .unique,
                    imageURL: TestImages.yoda.url
                ).asAnyAttachment,
                ChatMessageImageAttachment.mock(
                    id: .unique,
                    imageURL: TestImages.chewbacca.url
                ).asAnyAttachment
            ]),
            currentPage: 0
        )
        
        vc = makeGalleryVC(content: content)
    }
    
    override func tearDown() {
        content = nil
        vc = nil
        
        super.tearDown()
    }
    
    func test_defaultAppearance() {
        AssertSnapshot(vc)
    }
    
    func test_customImageAttachmentCellInjection() {
        // Declare custom image cell type
        class Cell: ImageAttachmentGalleryCell {}
        
        // Create components and inject custom image cell
        var components = Components.mock
        components.imageAttachmentGalleryCell = Cell.self
        
        // Make a gallery controller with custom components injected
        let vc = makeGalleryVC(content: content, components: components)
        vc.viewDidLoad()
        
        // Get the cell
        let cell = vc.collectionView(vc.attachmentsCollectionView, cellForItemAt: .init(item: 0, section: 0))
        
        // Assert cell is of custom type
        XCTAssertTrue(cell is Cell)
    }
    
    func test_customVideoAttachmentCellInjection() {
        // Declare custom video cell type
        class Cell: VideoAttachmentGalleryCell {}
        
        // Create components and inject custom video cell
        var components = Components.mock
        components.videoAttachmentGalleryCell = Cell.self
        
        // Create video attachment
        let videoAttachment = ChatMessageVideoAttachment(
            id: .unique,
            type: .video,
            payload: .init(
                title: .unique,
                videoRemoteURL: TestImages.chewbacca.url,
                file: try! .init(url: TestImages.chewbacca.url),
                extraData: nil
            ),
            uploadingState: nil
        )

        // Make a gallery controller with custom components injected
        let vc = makeGalleryVC(
            content: .init(
                message: makeMessage(with: [
                    videoAttachment.asAnyAttachment,
                    videoAttachment.asAnyAttachment
                ]),
                currentPage: 0
            ),
            components: components
        )
        vc.viewDidLoad()
        
        // Get the cell
        let cell = vc.collectionView(vc.attachmentsCollectionView, cellForItemAt: .init(item: 0, section: 0))
        
        // Assert cell is of custom type
        XCTAssertTrue(cell is Cell)
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
    
    private func makeGalleryVC(content: GalleryVC.Content, components: Components = .mock) -> GalleryVC {
        let vc = GalleryVC()
        vc.components = components
        vc.content = content
        vc.attachmentsCollectionView.reloadData()
        return vc
    }
    
    private func makeMessage(with attachments: [AnyChatMessageAttachment]) -> ChatMessage {
        .mock(
            id: .unique,
            cid: .unique,
            text: "",
            author: .mock(
                id: .unique,
                name: "Author"
            ),
            createdAt: Date(timeIntervalSinceReferenceDate: 0),
            attachments: attachments
        )
    }
}
