//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import UIKit
import XCTest

@MainActor
final class ChatMessageGiphyView_Tests: XCTestCase {
    private var mediaLoader: MediaLoader_Stub!
    private var view: ChatMessageGiphyView!
    private var parent: UIView!

    override func setUp() {
        super.setUp()
        mediaLoader = MediaLoader_Stub()
        var components = Components.mock
        components.mediaLoader = mediaLoader
        view = ChatMessageGiphyView()
        view.components = components
        parent = UIView()
        parent.addSubview(view)
    }

    override func tearDown() {
        mediaLoader = nil
        view = nil
        parent = nil
        super.tearDown()
    }

    func test_content_whenLoadingSucceedsWithAnimatedData_playsTheAnimation() {
        let animatedData = animatedGIFData()
        mediaLoader.result = .success(MediaLoaderImage(image: solidImage(), animatedImageData: animatedData))

        view.content = giphyAttachment()

        XCTAssertEqual(view.imageView.animatedImageData, animatedData)
        XCTAssertFalse(view.hasFailed)
        XCTAssertTrue(view.loadingIndicator.isHidden)
    }

    func test_content_whenLoadingSucceedsWithStaticImage_showsIt() {
        let image = solidImage()
        mediaLoader.result = .success(MediaLoaderImage(image: image))

        view.content = giphyAttachment()

        XCTAssertNil(view.imageView.animatedImageData)
        XCTAssertEqual(view.imageView.image, image)
        XCTAssertFalse(view.hasFailed)
    }

    func test_content_whenLoadingFails_setsHasFailed() {
        mediaLoader.result = .failure(TestError())

        view.content = giphyAttachment()

        XCTAssertTrue(view.hasFailed)
        XCTAssertTrue(view.loadingIndicator.isHidden)
    }

    func test_content_whenPreviewURLIsUnchanged_doesNotLoadAgain() {
        mediaLoader.result = .success(MediaLoaderImage(image: solidImage()))
        let attachment = giphyAttachment()
        view.content = attachment

        view.content = attachment

        XCTAssertEqual(mediaLoader.loadImageCallCount, 1)
    }

    func test_content_whenPreviewURLChanges_cancelsThePreviousLoading() {
        mediaLoader.completesImmediately = false
        view.content = giphyAttachment(previewURL: URL(string: "https://example.com/first.gif")!)

        view.content = giphyAttachment(previewURL: URL(string: "https://example.com/second.gif")!)
        mediaLoader.completePendingRequests(with: .success(MediaLoaderImage(image: solidImage())))

        XCTAssertEqual(mediaLoader.loadImageCallCount, 2)
        XCTAssertFalse(view.hasFailed)
    }

    // MARK: - Helpers

    private func giphyAttachment(previewURL: URL = .localYodaImage) -> ChatMessageGiphyAttachment {
        ChatMessageGiphyAttachment(
            id: .unique,
            type: .giphy,
            payload: GiphyAttachmentPayload(title: "wow", previewURL: previewURL, actions: []),
            downloadingState: nil,
            uploadingState: nil
        )
    }

    private func solidImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4), format: format).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
    }

    private func animatedGIFData() -> Data {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "com.compuserve.gif" as CFString, 2, nil)!
        for _ in 0..<2 {
            let properties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 0.1]]
            CGImageDestinationAddImage(destination, solidImage().cgImage!, properties as CFDictionary)
        }
        CGImageDestinationFinalize(destination)
        return data as Data
    }
}

private final class MediaLoader_Stub: MediaLoader, @unchecked Sendable {
    var result: Result<MediaLoaderImage, Error> = .failure(TestError())
    var completesImmediately = true
    var loadImageCallCount = 0

    private var pendingCompletions: [@MainActor (Result<MediaLoaderImage, Error>) -> Void] = []

    func completePendingRequests(with result: Result<MediaLoaderImage, Error>) {
        let completions = pendingCompletions
        pendingCompletions = []
        MainActor.assumeIsolated {
            completions.forEach { $0(result) }
        }
    }

    func loadImage(
        url: URL?,
        options: ImageLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderImage, Error>) -> Void
    ) {
        loadImageCallCount += 1
        guard completesImmediately else {
            pendingCompletions.append(completion)
            return
        }
        MainActor.assumeIsolated {
            completion(result)
        }
    }

    func loadVideoAsset(
        at url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoAsset, Error>) -> Void
    ) {}

    func loadVideoPreview(
        with attachment: ChatMessageVideoAttachment,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoPreview, Error>) -> Void
    ) {}

    func loadVideoPreview(
        at url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoPreview, Error>) -> Void
    ) {}

    func loadFileRequest(
        for url: URL,
        options: DownloadFileRequestOptions,
        completion: @escaping @MainActor (Result<MediaLoaderFileRequest, Error>) -> Void
    ) {}

    func trimImageMemoryCache(toCost limit: Int) {}
}
