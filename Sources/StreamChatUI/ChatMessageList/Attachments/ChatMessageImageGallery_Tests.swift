//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
import UIKit
import XCTest

final class ChatMessageImageGallery_Tests: XCTestCase {
    private var imageGallery: ChatMessageImageGallery!
    
    override func setUp() {
        super.setUp()
        
        imageGallery = ChatMessageImageGallery()
            .withoutAutoresizingMaskConstraints
        imageGallery.pin(anchors: [.width, .height], to: 200)
    }
    
    override func tearDown() {
        imageGallery = nil

        super.tearDown()
    }

    func test_appearance_whenOneImage() {
        imageGallery.content = [
            .mock(id: .unique, imageURL: TestImages.yoda.url)
        ]

        AssertSnapshot(imageGallery, variants: [.defaultLight])
    }
    
    func test_appearance_whenTwoImages() {
        imageGallery.content = [
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url)
        ]

        AssertSnapshot(imageGallery, variants: [.defaultLight])
    }
    
    func test_appearance_whenThreeImages() {
        imageGallery.content = [
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url)
        ]

        AssertSnapshot(imageGallery, variants: [.defaultLight])
    }
    
    func test_appearance_whenFourImages() {
        imageGallery.content = [
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url)
        ]

        AssertSnapshot(imageGallery, variants: [.defaultLight])
    }
    
    func test_appearance_whenMoreThanFourImages() {
        imageGallery.content = [
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url)
        ]

        AssertSnapshot(imageGallery, variants: [.defaultDark, .defaultLight])
    }
    
    func test_appearanceCustomization_usingAppearance() {
        var appearance = Appearance()
        appearance.colorPalette.background5 = UIColor.purple.withAlphaComponent(0.5)
        imageGallery = ChatMessageImageGallery()
            .withoutAutoresizingMaskConstraints
        imageGallery.appearance = appearance
        imageGallery.pin(anchors: [.width, .height], to: 200)
        
        imageGallery.content = [
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url)
        ]

        AssertSnapshot(imageGallery, variants: [.defaultLight])
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatMessageImageGallery {
            override func setUpLayout() {
                super.setUpLayout()
                
                previewsContainerView.spacing = 10
            }
        }
    
        let imageGallery = TestView()
            .withoutAutoresizingMaskConstraints
        imageGallery.pin(anchors: [.width, .height], to: 200)
        
        imageGallery.content = [
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.vader.url)
        ]
        
        AssertSnapshot(imageGallery, variants: [.defaultLight])
    }
}
