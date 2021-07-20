//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
import UIKit
import XCTest

final class ChatMessageLinkPreviewView_Tests: XCTestCase {
    private var linkPreviewView: ChatMessageLinkPreviewView!
    
    override func setUp() {
        super.setUp()
        
        linkPreviewView = ChatMessageLinkPreviewView()
            .withoutAutoresizingMaskConstraints
        linkPreviewView.pin(anchors: [.width], to: 200)
        linkPreviewView.content = .mock(
            id: .unique,
            originalURL: .unique(),
            title: "Title",
            text: "Text",
            author: "Youtube",
            assetURL: TestImages.yoda.url,
            previewURL: TestImages.yoda.url
        )
    }
    
    override func tearDown() {
        linkPreviewView = nil

        super.tearDown()
    }
    
    func test_appearance() {
        AssertSnapshot(linkPreviewView)
    }
    
    func test_appearance_whenNoAuthor() {
        linkPreviewView.content = .mock(
            id: .unique,
            originalURL: .unique(),
            title: "Title",
            text: "Text",
            assetURL: TestImages.yoda.url,
            previewURL: TestImages.yoda.url
        )

        AssertSnapshot(linkPreviewView)
    }
    
    func test_appearance_whenNoTitle() {
        linkPreviewView.content = .mock(
            id: .unique,
            originalURL: .unique(),
            text: "Text",
            author: "Youtube",
            assetURL: TestImages.yoda.url,
            previewURL: TestImages.yoda.url
        )

        AssertSnapshot(linkPreviewView)
    }
    
    func test_appearance_whenNoTitleAndText() {
        linkPreviewView.content = .mock(
            id: .unique,
            originalURL: .unique(),
            author: "Youtube",
            assetURL: TestImages.yoda.url,
            previewURL: TestImages.yoda.url
        )

        AssertSnapshot(linkPreviewView)
    }
    
    func test_appearance_whenNoImagePreview() {
        linkPreviewView.content = .mock(
            id: .unique,
            originalURL: .unique(),
            title: "Title",
            text: "Text",
            author: "Youtube",
            assetURL: nil,
            previewURL: nil
        )

        AssertSnapshot(linkPreviewView)
    }
    
    func test_appearance_whenLongTexts() {
        let mockContent = repeatElement("Text", count: 5)
            .joined(separator: "\n")
        linkPreviewView.content = .mock(
            id: .unique,
            originalURL: .unique(),
            title: mockContent,
            text: mockContent,
            author: mockContent,
            assetURL: TestImages.yoda.url,
            previewURL: TestImages.yoda.url
        )

        AssertSnapshot(linkPreviewView)
    }
    
    func test_appearanceCustomization_usingAppearance() {
        var appearance = Appearance()
        appearance.fonts.subheadline = appearance.fonts.subheadlineBold
        linkPreviewView.appearance = appearance
        
        AssertSnapshot(linkPreviewView)
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatMessageLinkPreviewView {
            override func setUpLayout() {
                super.setUpLayout()

                textStack.spacing = 20
            }
        }
        
        let linkPreviewView = TestView()
            .withoutAutoresizingMaskConstraints
        linkPreviewView.pin(anchors: [.width], to: 200)
        linkPreviewView.content = .mock(
            id: .unique,
            originalURL: .unique(),
            title: "Title",
            text: "Text",
            author: "Youtube",
            assetURL: TestImages.yoda.url,
            previewURL: TestImages.yoda.url
        )

        AssertSnapshot(linkPreviewView)
    }
}
