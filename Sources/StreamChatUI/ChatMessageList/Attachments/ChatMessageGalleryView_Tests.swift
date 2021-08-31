//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
import UIKit
import XCTest

final class ChatMessageGalleryView_Tests: XCTestCase {
    private var galleryView: ChatMessageGalleryView!
    
    override func setUp() {
        super.setUp()
        
        galleryView = ChatMessageGalleryView()
            .withoutAutoresizingMaskConstraints
        galleryView.components = .mock
        galleryView.pin(anchors: [.width, .height], to: 200)
    }
    
    override func tearDown() {
        galleryView = nil

        super.tearDown()
    }

    func test_appearance_whenOneImage() {
        let attachments: [ChatMessageImageAttachment] = [
            .mock(id: .unique, imageURL: TestImages.yoda.url)
        ]
        
        galleryView.content = attachments.map(preview)

        AssertSnapshot(galleryView, variants: [.defaultLight])
    }
    
    func test_appearance_whenTwoImages() {
        let attachments: [ChatMessageImageAttachment] = [
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url)
        ]
        
        galleryView.content = attachments.map(preview)

        AssertSnapshot(galleryView, variants: [.defaultLight])
    }
    
    func test_appearance_whenThreeImages() {
        let attachments: [ChatMessageImageAttachment] = [
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url)
        ]
        
        galleryView.content = attachments.map(preview)

        AssertSnapshot(galleryView, variants: [.defaultLight])
    }
    
    func test_appearance_whenFourImages() {
        let attachments: [ChatMessageImageAttachment] = [
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url)
        ]
        
        galleryView.content = attachments.map(preview)

        AssertSnapshot(galleryView, variants: [.defaultLight])
    }
    
    func test_appearance_whenMoreThanFourImages() {
        let attachments: [ChatMessageImageAttachment] = [
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url)
        ]
        
        galleryView.content = attachments.map(preview)

        AssertSnapshot(galleryView, variants: [.defaultDark, .defaultLight])
    }
    
    func test_appearanceCustomization_usingAppearance() {
        var appearance = Appearance()
        appearance.colorPalette.background5 = UIColor.purple.withAlphaComponent(0.5)
        galleryView = ChatMessageGalleryView()
            .withoutAutoresizingMaskConstraints
        galleryView.components = .mock
        galleryView.appearance = appearance
        galleryView.pin(anchors: [.width, .height], to: 200)
        
        let attachments: [ChatMessageImageAttachment] = [
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url)
        ]
        
        galleryView.content = attachments.map(preview)

        AssertSnapshot(galleryView, variants: [.defaultLight])
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatMessageGalleryView {
            override func setUpLayout() {
                super.setUpLayout()
                
                previewsContainerView.spacing = 10
            }
        }
    
        let galleryView = TestView()
            .withoutAutoresizingMaskConstraints
        galleryView.pin(anchors: [.width, .height], to: 200)
        galleryView.components = .mock
        
        let attachments: [ChatMessageImageAttachment] = [
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url)
        ]
        
        galleryView.content = attachments.map(preview)
        
        AssertSnapshot(galleryView, variants: [.defaultLight])
    }
    
    private func preview(for attachment: ChatMessageImageAttachment) -> UIView {
        let preview = ChatMessageGalleryView.ImagePreview().withoutAutoresizingMaskConstraints
        preview.content = attachment
        return preview
    }
}
