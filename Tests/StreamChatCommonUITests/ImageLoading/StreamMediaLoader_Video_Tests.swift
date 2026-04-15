//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
@testable import StreamChatCommonUI
import XCTest

final class StreamMediaLoader_Video_Tests: XCTestCase {
    private var downloader: MockImageDownloader!
    private var cdnRequester: MockCDNRequester!
    private var sut: StreamMediaLoader!

    override func setUp() {
        super.setUp()
        downloader = MockImageDownloader()
        cdnRequester = MockCDNRequester()
        sut = StreamMediaLoader(downloader: downloader)
    }

    override func tearDown() {
        sut = nil
        cdnRequester = nil
        downloader = nil
        super.tearDown()
    }

    // MARK: - loadVideoAsset

    func test_loadVideoAsset_success_createsAssetWithTransformedURL() {
        let transformedURL = URL(string: "https://cdn.example.com/signed-video.mp4")!
        cdnRequester.fileRequestResult = .success(CDNRequest(url: transformedURL))
        let originalURL = URL(string: "https://example.com/video.mp4")!
        let expectation = expectation(description: "Completion called")

        sut.loadVideoAsset(at: originalURL, options: VideoLoadOptions(cdnRequester: cdnRequester)) { result in
            switch result {
            case let .success(videoAsset):
                XCTAssertEqual(videoAsset.asset.url, transformedURL)
            case .failure:
                XCTFail("Should have succeeded")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func test_loadVideoAsset_withHeaders_includesHeadersInAssetOptions() {
        let headers = ["Authorization": "Bearer abc", "X-Custom": "value"]
        let url = URL(string: "https://cdn.example.com/video.mp4")!
        cdnRequester.fileRequestResult = .success(CDNRequest(url: url, headers: headers))
        let expectation = expectation(description: "Completion called")

        sut.loadVideoAsset(at: url, options: VideoLoadOptions(cdnRequester: cdnRequester)) { result in
            switch result {
            case let .success(videoAsset):
                XCTAssertEqual(videoAsset.asset.url, url)
            case .failure:
                XCTFail("Should have succeeded")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func test_loadVideoAsset_withEmptyHeaders_createsAssetWithoutOptions() {
        let url = URL(string: "https://cdn.example.com/video.mp4")!
        cdnRequester.fileRequestResult = .success(CDNRequest(url: url, headers: [:]))
        let expectation = expectation(description: "Completion called")

        sut.loadVideoAsset(at: url, options: VideoLoadOptions(cdnRequester: cdnRequester)) { result in
            switch result {
            case let .success(videoAsset):
                XCTAssertEqual(videoAsset.asset.url, url)
            case .failure:
                XCTFail("Should have succeeded")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func test_loadVideoAsset_withNilHeaders_createsAssetWithoutOptions() {
        let url = URL(string: "https://cdn.example.com/video.mp4")!
        cdnRequester.fileRequestResult = .success(CDNRequest(url: url))
        let expectation = expectation(description: "Completion called")

        sut.loadVideoAsset(at: url, options: VideoLoadOptions(cdnRequester: cdnRequester)) { result in
            switch result {
            case let .success(videoAsset):
                XCTAssertEqual(videoAsset.asset.url, url)
            case .failure:
                XCTFail("Should have succeeded")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func test_loadVideoAsset_cdnFailure_propagatesError() {
        let expectedError = NSError(domain: "CDN", code: 500)
        cdnRequester.fileRequestResult = .failure(expectedError)
        let url = URL(string: "https://example.com/video.mp4")!
        let expectation = expectation(description: "Completion called")

        sut.loadVideoAsset(at: url, options: VideoLoadOptions(cdnRequester: cdnRequester)) { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case let .failure(error):
                XCTAssertEqual((error as NSError).code, 500)
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    // MARK: - loadVideoPreview (URL variant)

    func test_loadVideoPreview_callsCDNRequesterFileRequest() {
        let url = URL(string: "https://example.com/video.mp4")!
        cdnRequester.fileRequestResult = .failure(NSError(domain: "test", code: 0))
        let expectation = expectation(description: "Completion called")

        sut.loadVideoPreview(at: url, options: VideoLoadOptions(cdnRequester: cdnRequester)) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
        XCTAssertEqual(cdnRequester.fileRequestCallCount, 1)
        XCTAssertEqual(cdnRequester.lastFileRequestURL, url)
    }

    func test_loadVideoPreview_cdnFailure_propagatesError() {
        let expectedError = NSError(domain: "CDN", code: 404)
        cdnRequester.fileRequestResult = .failure(expectedError)
        let url = URL(string: "https://example.com/video.mp4")!
        let expectation = expectation(description: "Completion called")

        sut.loadVideoPreview(at: url, options: VideoLoadOptions(cdnRequester: cdnRequester)) { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case let .failure(error):
                XCTAssertEqual((error as NSError).code, 404)
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    // MARK: - Video preview caching

    func test_loadVideoPreview_secondCall_usesCacheAndSkipsCDN() {
        let url = URL(string: "https://example.com/video.mp4")!
        let cachedImage = UIImage.make(withColor: .purple)

        // Simulate caching via the attachment variant with a thumbnail URL
        let thumbnailURL = URL(string: "https://example.com/thumb.jpg")!
        downloader.result = .success(DownloadedImage(image: cachedImage))
        let attachment = makeVideoAttachment(videoURL: url, thumbnailURL: thumbnailURL)

        let firstExpectation = expectation(description: "First load")
        sut.loadVideoPreview(with: attachment, options: VideoLoadOptions(cdnRequester: cdnRequester)) { result in
            if case let .success(preview) = result {
                XCTAssertEqual(preview.image.pngData(), cachedImage.pngData())
            } else {
                XCTFail("First load should succeed")
            }
            firstExpectation.fulfill()
        }
        waitForExpectations(timeout: 2)

        // Reset CDN requester counters
        cdnRequester.fileRequestCallCount = 0
        cdnRequester.imageRequestCallCount = 0

        // Second load should hit cache and NOT call CDN requester
        let secondExpectation = expectation(description: "Second load from cache")
        sut.loadVideoPreview(with: attachment, options: VideoLoadOptions(cdnRequester: cdnRequester)) { result in
            if case let .success(preview) = result {
                XCTAssertEqual(preview.image.pngData(), cachedImage.pngData())
            } else {
                XCTFail("Second load should succeed from cache")
            }
            secondExpectation.fulfill()
        }
        waitForExpectations(timeout: 2)

        XCTAssertEqual(cdnRequester.fileRequestCallCount, 0, "Should not call CDN requester when cached")
        XCTAssertEqual(cdnRequester.imageRequestCallCount, 0, "Should not call CDN requester when cached")
    }

    func test_loadVideoPreview_cachedDirectURL_returnsFromCache() {
        let url = URL(string: "https://example.com/video.mp4")!
        let cachedImage = UIImage.make(withColor: .orange)

        // First, populate cache via attachment with thumbnail
        let thumbnailURL = URL(string: "https://example.com/thumb.jpg")!
        downloader.result = .success(DownloadedImage(image: cachedImage))
        let attachment = makeVideoAttachment(videoURL: url, thumbnailURL: thumbnailURL)

        let firstExpectation = expectation(description: "First load")
        sut.loadVideoPreview(with: attachment, options: VideoLoadOptions(cdnRequester: cdnRequester)) { _ in
            firstExpectation.fulfill()
        }
        waitForExpectations(timeout: 2)

        // Now call the direct URL variant — should hit the same cache
        cdnRequester.fileRequestCallCount = 0
        let secondExpectation = expectation(description: "Direct URL cache hit")
        sut.loadVideoPreview(at: url, options: VideoLoadOptions(cdnRequester: cdnRequester)) { result in
            if case let .success(preview) = result {
                XCTAssertEqual(preview.image.pngData(), cachedImage.pngData())
            } else {
                XCTFail("Should return cached preview")
            }
            secondExpectation.fulfill()
        }
        waitForExpectations(timeout: 2)

        XCTAssertEqual(cdnRequester.fileRequestCallCount, 0, "Should not call CDN when cached")
    }

    // MARK: - loadVideoPreview (attachment variant)

    func test_loadVideoPreview_attachment_withThumbnailURL_loadsImage() {
        let videoURL = URL(string: "https://example.com/video.mp4")!
        let thumbnailURL = URL(string: "https://example.com/thumb.jpg")!
        let thumbnailImage = UIImage.make(withColor: .cyan)
        downloader.result = .success(DownloadedImage(image: thumbnailImage))
        let attachment = makeVideoAttachment(videoURL: videoURL, thumbnailURL: thumbnailURL)
        let expectation = expectation(description: "Completion called")

        sut.loadVideoPreview(with: attachment, options: VideoLoadOptions(cdnRequester: cdnRequester)) { result in
            switch result {
            case let .success(preview):
                XCTAssertEqual(preview.image.pngData(), thumbnailImage.pngData())
            case .failure:
                XCTFail("Should have succeeded with thumbnail")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func test_loadVideoPreview_attachment_thumbnailLoadFails_fallsBackToVideoPreview() {
        let videoURL = URL(string: "https://example.com/video.mp4")!
        let thumbnailURL = URL(string: "https://example.com/thumb.jpg")!
        downloader.result = .failure(NSError(domain: "test", code: 0))
        cdnRequester.fileRequestResult = .failure(NSError(domain: "CDN", code: 0))
        let attachment = makeVideoAttachment(videoURL: videoURL, thumbnailURL: thumbnailURL)
        let expectation = expectation(description: "Completion called")

        sut.loadVideoPreview(with: attachment, options: VideoLoadOptions(cdnRequester: cdnRequester)) { result in
            switch result {
            case .success:
                XCTFail("Should have failed since both thumbnail and video preview fail")
            case .failure:
                break
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
        XCTAssertEqual(cdnRequester.fileRequestCallCount, 1, "Should fall back to generating video preview")
    }

    func test_loadVideoPreview_attachment_withoutThumbnailURL_generatesPreview() {
        let videoURL = URL(string: "https://example.com/video.mp4")!
        cdnRequester.fileRequestResult = .failure(NSError(domain: "CDN", code: 0))
        let attachment = makeVideoAttachment(videoURL: videoURL, thumbnailURL: nil)
        let expectation = expectation(description: "Completion called")

        sut.loadVideoPreview(with: attachment, options: VideoLoadOptions(cdnRequester: cdnRequester)) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
        XCTAssertEqual(cdnRequester.fileRequestCallCount, 1, "Should call CDN for video preview generation")
    }

    // MARK: - Completion always called

    func test_loadVideoPreview_deallocatedLoader_callsCompletionWithError() {
        var loader: StreamMediaLoader? = StreamMediaLoader(downloader: MockImageDownloader())
        let asyncCDN = AsyncMockCDNRequester()
        let url = URL(string: "https://example.com/video.mp4")!
        let expectation = expectation(description: "Completion called")

        loader?.loadVideoPreview(at: url, options: VideoLoadOptions(cdnRequester: asyncCDN)) { result in
            if case .failure = result {
                expectation.fulfill()
            } else {
                XCTFail("Should have failed when loader was deallocated")
            }
        }

        loader = nil
        asyncCDN.triggerFileCompletion(.success(CDNRequest(url: url)))

        waitForExpectations(timeout: 2)
    }

    func test_loadVideoPreview_attachment_deallocatedLoader_callsCompletionWithError() {
        let mockDownloader = AsyncMockImageDownloader()
        var loader: StreamMediaLoader? = StreamMediaLoader(downloader: mockDownloader)
        let attachment = makeVideoAttachment(
            videoURL: URL(string: "https://example.com/video.mp4")!,
            thumbnailURL: URL(string: "https://example.com/thumb.jpg")!
        )
        let expectation = expectation(description: "Completion called")

        loader?.loadVideoPreview(with: attachment, options: VideoLoadOptions(cdnRequester: cdnRequester)) { result in
            if case .failure = result {
                expectation.fulfill()
            } else {
                XCTFail("Should have failed when loader was deallocated")
            }
        }

        loader = nil
        mockDownloader.triggerCompletion(.success(DownloadedImage(image: UIImage())))

        waitForExpectations(timeout: 2)
    }

    // MARK: - Memory Warning

    func test_memoryWarning_clearsCache_subsequentLoadCallsCDN() {
        let url = URL(string: "https://example.com/video.mp4")!
        let cachedImage = UIImage.make(withColor: .purple)

        // Populate cache via attachment thumbnail
        let thumbnailURL = URL(string: "https://example.com/thumb.jpg")!
        downloader.result = .success(DownloadedImage(image: cachedImage))
        let attachment = makeVideoAttachment(videoURL: url, thumbnailURL: thumbnailURL)

        let firstExpectation = expectation(description: "First load")
        sut.loadVideoPreview(with: attachment, options: VideoLoadOptions(cdnRequester: cdnRequester)) { _ in
            firstExpectation.fulfill()
        }
        waitForExpectations(timeout: 2)

        // Post memory warning
        NotificationCenter.default.post(
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )

        // Reset counters
        cdnRequester.imageRequestCallCount = 0

        // Load again — should NOT hit cache (it was cleared)
        let secondExpectation = expectation(description: "Second load after memory warning")
        sut.loadVideoPreview(with: attachment, options: VideoLoadOptions(cdnRequester: cdnRequester)) { _ in
            secondExpectation.fulfill()
        }
        waitForExpectations(timeout: 2)

        XCTAssertEqual(cdnRequester.imageRequestCallCount, 1, "Should re-fetch after cache cleared by memory warning")
    }

    // MARK: - Helpers

    private func makeVideoAttachment(
        videoURL: URL,
        thumbnailURL: URL?
    ) -> ChatMessageVideoAttachment {
        let payload = VideoAttachmentPayload(
            title: "test",
            videoRemoteURL: videoURL,
            thumbnailURL: thumbnailURL,
            file: .init(type: .mp4, size: 1000, mimeType: nil),
            extraData: nil
        )
        return ChatMessageVideoAttachment(
            id: .init(cid: .init(type: .messaging, id: "test"), messageId: "msg1", index: 0),
            type: .video,
            payload: payload,
            downloadingState: nil,
            uploadingState: nil
        )
    }
}

// MARK: - Mocks

private final class MockCDNRequester: CDNRequester, @unchecked Sendable {
    var imageRequestResult: Result<CDNRequest, Error>?
    var fileRequestResult: Result<CDNRequest, Error>?
    var fileRequestCallCount = 0
    var imageRequestCallCount = 0
    var lastFileRequestURL: URL?
    var lastImageRequestOptions: ImageRequestOptions?

    func imageRequest(for url: URL, options: ImageRequestOptions, completion: @escaping (Result<CDNRequest, Error>) -> Void) {
        imageRequestCallCount += 1
        lastImageRequestOptions = options
        completion(imageRequestResult ?? .success(CDNRequest(url: url)))
    }

    func fileRequest(for url: URL, options: FileRequestOptions, completion: @escaping (Result<CDNRequest, Error>) -> Void) {
        fileRequestCallCount += 1
        lastFileRequestURL = url
        completion(fileRequestResult ?? .success(CDNRequest(url: url)))
    }
}

private final class MockImageDownloader: ImageDownloading, @unchecked Sendable {
    var result: Result<DownloadedImage, Error> = .failure(NSError(domain: "MockImageDownloader", code: 0))

    func downloadImage(
        url: URL,
        options: ImageDownloadingOptions,
        completion: @escaping @MainActor (Result<DownloadedImage, Error>) -> Void
    ) {
        let result = self.result
        DispatchQueue.main.async {
            completion(result)
        }
    }
}

private final class AsyncMockCDNRequester: CDNRequester, @unchecked Sendable {
    private var fileCompletion: ((Result<CDNRequest, Error>) -> Void)?

    func imageRequest(for url: URL, options: ImageRequestOptions, completion: @escaping (Result<CDNRequest, Error>) -> Void) {
        completion(.success(CDNRequest(url: url)))
    }

    func fileRequest(for url: URL, options: FileRequestOptions, completion: @escaping (Result<CDNRequest, Error>) -> Void) {
        fileCompletion = completion
    }

    func triggerFileCompletion(_ result: Result<CDNRequest, Error>) {
        fileCompletion?(result)
    }
}

private final class AsyncMockImageDownloader: ImageDownloading, @unchecked Sendable {
    private var storedCompletion: (@MainActor (Result<DownloadedImage, Error>) -> Void)?

    func downloadImage(
        url: URL,
        options: ImageDownloadingOptions,
        completion: @escaping @MainActor (Result<DownloadedImage, Error>) -> Void
    ) {
        storedCompletion = completion
    }

    func triggerCompletion(_ result: Result<DownloadedImage, Error>) {
        let completion = storedCompletion
        DispatchQueue.main.async {
            completion?(result)
        }
    }
}

private extension UIImage {
    static func make(withColor color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        UIGraphicsBeginImageContext(size)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
