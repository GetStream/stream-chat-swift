//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatCommonUI
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import UIKit
import XCTest

@MainActor final class ChatMessageGalleryView_Tests: XCTestCase {
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
        appearance.colorPalette.backgroundCoreScrim = UIColor.purple.withAlphaComponent(0.5)
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

    func test_imagePreview_whenImageIsCached_hidesLoadingIndicatorSynchronously() throws {
        let url = TestImages.yoda.url
        let cachingKey = "cached-yoda"
        let image = try XCTUnwrap(UIImage(data: Data(contentsOf: url)))
        let request = ImageRequest(
            urlRequest: URLRequest(url: url),
            processors: [],
            userInfo: [.imageIdKey: cachingKey]
        )
        ImagePipeline.shared.cache[request] = ImageContainer(image: image)
        defer { ImagePipeline.shared.cache[request] = nil }

        var components = Components.mock
        components.mediaLoader = StreamMediaLoader(
            downloader: StreamImageDownloader(),
            cdnRequester: StaticCachingKeyCDNRequester(cachingKey: cachingKey)
        )
        let preview = ChatMessageGalleryView.ImagePreview().withoutAutoresizingMaskConstraints
        preview.components = components
        preview.content = .mock(id: .unique, imageURL: url)

        UIView().addSubview(preview)

        XCTAssertFalse(preview.loadingIndicator.isVisible)
    }

    private func preview(for attachment: ChatMessageImageAttachment) -> UIView {
        let preview = ChatMessageGalleryView.ImagePreview().withoutAutoresizingMaskConstraints
        preview.content = attachment
        return preview
    }
}

private final class StaticCachingKeyCDNRequester: CDNRequester, @unchecked Sendable {
    let cachingKey: String

    init(cachingKey: String) {
        self.cachingKey = cachingKey
    }

    func imageRequest(
        for url: URL,
        options: ImageRequestOptions,
        completion: @escaping (Result<CDNRequest, Error>) -> Void
    ) {
        completion(.success(CDNRequest(url: url, cachingKey: cachingKey)))
    }

    func fileRequest(
        for url: URL,
        options: FileRequestOptions,
        completion: @escaping (Result<CDNRequest, Error>) -> Void
    ) {
        completion(.success(CDNRequest(url: url)))
    }
}
