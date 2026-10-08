//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatCommonUI
import XCTest

final class StreamMediaLoader_Image_Tests: XCTestCase {
    private var downloader: MockImageDownloader!
    private var cdnRequester: MockCDNRequester!
    private var sut: StreamMediaLoader!

    override func setUp() {
        super.setUp()
        downloader = MockImageDownloader()
        cdnRequester = MockCDNRequester()
        sut = StreamMediaLoader(downloader: downloader, cdnRequester: cdnRequester)
    }

    override func tearDown() {
        sut = nil
        cdnRequester = nil
        downloader = nil
        super.tearDown()
    }

    // MARK: - loadImage

    func test_loadImage_nilURL_callsCompletionWithFailure() {
        let expectation = expectation(description: "Completion called")

        sut.loadImage(url: nil, options: ImageLoadOptions()) { result in
            switch result {
            case .failure:
                break
            case .success:
                XCTFail("Should have failed for nil URL")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func test_loadImage_success_returnsMediaLoaderImage() {
        let testImage = UIImage.make(withColor: .red)
        downloader.result = .success(DownloadedImage(image: testImage))
        let url = URL(string: "https://example.com/image.jpg")!
        let expectation = expectation(description: "Completion called")

        sut.loadImage(url: url, options: ImageLoadOptions()) { result in
            switch result {
            case let .success(loaded):
                XCTAssertEqual(loaded.image.pngData(), testImage.pngData())
            case .failure:
                XCTFail("Should have succeeded")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func test_loadImage_cdnRequesterFailure_propagatesError() {
        let expectedError = NSError(domain: "CDN", code: 42)
        cdnRequester.imageRequestResult = .failure(expectedError)
        let url = URL(string: "https://example.com/image.jpg")!
        let expectation = expectation(description: "Completion called")

        sut.loadImage(url: url, options: ImageLoadOptions()) { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case let .failure(error):
                XCTAssertEqual((error as NSError).code, 42)
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func test_loadImage_downloaderFailure_propagatesError() {
        let expectedError = NSError(domain: "Download", code: 99)
        downloader.result = .failure(expectedError)
        let url = URL(string: "https://example.com/image.jpg")!
        let expectation = expectation(description: "Completion called")

        sut.loadImage(url: url, options: ImageLoadOptions()) { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case let .failure(error):
                XCTAssertEqual((error as NSError).code, 99)
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func test_loadImage_passesResizeToDownloader() {
        let testImage = UIImage.make(withColor: .blue)
        downloader.result = .success(DownloadedImage(image: testImage))
        let url = URL(string: "https://example.com/image.jpg")!
        let resize = ImageResize(CGSize(width: 100, height: 200))
        let expectation = expectation(description: "Completion called")

        sut.loadImage(url: url, options: ImageLoadOptions(resize: resize)) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
        XCTAssertEqual(downloader.lastOptions?.resize, CGSize(width: 100, height: 200))
    }

    func test_loadImage_passesHeadersFromCDNRequest() {
        let testImage = UIImage.make(withColor: .green)
        downloader.result = .success(DownloadedImage(image: testImage))
        let headers = ["Authorization": "Bearer token123"]
        cdnRequester.imageRequestResult = .success(CDNRequest(
            url: URL(string: "https://cdn.example.com/image.jpg")!,
            headers: headers
        ))
        let url = URL(string: "https://example.com/image.jpg")!
        let expectation = expectation(description: "Completion called")

        sut.loadImage(url: url, options: ImageLoadOptions()) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
        XCTAssertEqual(downloader.lastOptions?.headers, headers)
    }

    func test_loadImage_passesCachingKeyFromCDNRequest() {
        let testImage = UIImage.make(withColor: .green)
        downloader.result = .success(DownloadedImage(image: testImage))
        cdnRequester.imageRequestResult = .success(CDNRequest(
            url: URL(string: "https://cdn.example.com/image.jpg")!,
            cachingKey: "custom-key"
        ))
        let url = URL(string: "https://example.com/image.jpg")!
        let expectation = expectation(description: "Completion called")

        sut.loadImage(url: url, options: ImageLoadOptions()) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
        XCTAssertEqual(downloader.lastOptions?.cachingKey, "custom-key")
    }

    func test_loadImage_passesTransformedURLToDownloader() {
        let testImage = UIImage.make(withColor: .green)
        downloader.result = .success(DownloadedImage(image: testImage))
        let transformedURL = URL(string: "https://cdn.example.com/transformed.jpg")!
        cdnRequester.imageRequestResult = .success(CDNRequest(url: transformedURL))
        let originalURL = URL(string: "https://example.com/original.jpg")!
        let expectation = expectation(description: "Completion called")

        sut.loadImage(url: originalURL, options: ImageLoadOptions()) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
        XCTAssertEqual(downloader.lastURL, transformedURL)
    }

    // MARK: - init

    func test_init_setsDownloader() {
        XCTAssertTrue(sut.downloader is MockImageDownloader)
    }

    // MARK: - trimImageMemoryCache

    func test_trimImageMemoryCache_forwardsToDownloader() {
        sut.trimImageMemoryCache(toCost: 1024)

        XCTAssertEqual(downloader.trimmedCosts, [1024])
    }

    // MARK: - loadImageTask

    @MainActor
    func test_loadImageTask_whenCancelledDuringCDNRequest_doesNotStartTheDownloadAndCompletesWithCancellationError() async {
        cdnRequester.defersImageRequests = true
        downloader.result = .success(DownloadedImage(image: UIImage.make(withColor: .red)))
        let url = URL(string: "https://example.com/image.jpg")!
        var results: [Result<MediaLoaderImage, Error>] = []

        let task = sut.loadImageTask(url: url, options: ImageLoadOptions()) { results.append($0) }
        task.cancel()
        cdnRequester.resolvePendingImageRequests()
        await drainMainQueue()

        XCTAssertTrue(downloader.downloadTasks.isEmpty)
        XCTAssertNil(downloader.lastURL)
        XCTAssertEqual(results.count, 1)
        XCTAssertThrowsError(try results.first?.get()) { XCTAssertTrue($0 is CancellationError) }
    }

    @MainActor
    func test_loadImageTask_whenCancelledDuringDownload_cancelsTheDownloadAndCompletesWithCancellationError() async {
        downloader.result = .success(DownloadedImage(image: UIImage.make(withColor: .red)))
        let url = URL(string: "https://example.com/image.jpg")!
        var results: [Result<MediaLoaderImage, Error>] = []

        let task = sut.loadImageTask(url: url, options: ImageLoadOptions()) { results.append($0) }
        task.cancel()
        await drainMainQueue()

        XCTAssertEqual(downloader.downloadTasks.map(\.isCancelled), [true])
        XCTAssertEqual(results.count, 1)
        XCTAssertThrowsError(try results.first?.get()) { XCTAssertTrue($0 is CancellationError) }
    }

    @MainActor
    func test_loadImage_async_whenSwiftTaskIsCancelled_throwsCancellationError() async {
        downloader.result = .success(DownloadedImage(image: UIImage.make(withColor: .red)))
        let url = URL(string: "https://example.com/image.jpg")!
        let sut = self.sut!

        let loading = Task { try await sut.loadImage(url: url) }
        loading.cancel()

        do {
            _ = try await loading.value
            XCTFail("Should have thrown")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }

    @MainActor
    func test_loadImageTask_whenSubclassOverridesItAndCallsSuperLoadImage_completes() {
        downloader.result = .success(DownloadedImage(image: UIImage.make(withColor: .red)))
        let sut = SuperLoadImageCallingMediaLoader(downloader: downloader, cdnRequester: cdnRequester)
        let completion = expectation(description: "completion")
        var results: [Result<MediaLoaderImage, Error>] = []

        sut.loadImageTask(url: URL(string: "https://example.com/image.jpg")!, options: ImageLoadOptions()) { result in
            results.append(result)
            completion.fulfill()
        }

        wait(for: [completion], timeout: 5)
        XCTAssertNoThrow(try results.first?.get())
    }

    @MainActor
    func test_loadImageTask_whenSubclassOverridesLoadImage_callsTheOverrideAndCancelsTheDownload() async {
        downloader.result = .success(DownloadedImage(image: UIImage.make(withColor: .red)))
        let sut = LoadImageOverridingMediaLoader(downloader: downloader, cdnRequester: cdnRequester)
        var results: [Result<MediaLoaderImage, Error>] = []

        let task = sut.loadImageTask(url: URL(string: "https://example.com/image.jpg")!, options: ImageLoadOptions()) { results.append($0) }
        task.cancel()
        await drainMainQueue()

        XCTAssertEqual(sut.loadImageCallCount, 1)
        XCTAssertEqual(downloader.downloadTasks.map(\.isCancelled), [true])
        XCTAssertEqual(results.count, 1)
        XCTAssertThrowsError(try results.first?.get()) { XCTAssertTrue($0 is CancellationError) }
    }

    // MARK: - Helpers

    private func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}

// MARK: - Mocks

private final class LoadImageOverridingMediaLoader: StreamMediaLoader, @unchecked Sendable {
    var loadImageCallCount = 0

    override func loadImage(
        url: URL?,
        options: ImageLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderImage, Error>) -> Void
    ) {
        loadImageCallCount += 1
        super.loadImage(url: url, options: options, completion: completion)
    }
}

private final class SuperLoadImageCallingMediaLoader: StreamMediaLoader, @unchecked Sendable {
    @discardableResult
    override func loadImageTask(
        url: URL?,
        options: ImageLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderImage, Error>) -> Void
    ) -> ImageLoadingTask {
        super.loadImage(url: url, options: options, completion: completion)
        return ImageLoadingTask()
    }
}

private final class MockCDNRequester: CDNRequester, @unchecked Sendable {
    var imageRequestResult: Result<CDNRequest, Error>?
    var lastImageRequestOptions: ImageRequestOptions?
    var defersImageRequests = false
    private var pendingImageRequests: [() -> Void] = []

    func imageRequest(for url: URL, options: ImageRequestOptions, completion: @escaping (Result<CDNRequest, Error>) -> Void) {
        lastImageRequestOptions = options
        let result = imageRequestResult ?? .success(CDNRequest(url: url))
        if defersImageRequests {
            pendingImageRequests.append { completion(result) }
        } else {
            completion(result)
        }
    }

    func resolvePendingImageRequests() {
        pendingImageRequests.forEach { $0() }
        pendingImageRequests = []
    }

    func fileRequest(for url: URL, options: FileRequestOptions, completion: @escaping (Result<CDNRequest, Error>) -> Void) {
        completion(.success(CDNRequest(url: url)))
    }
}

private final class MockImageDownloader: ImageDownloading, @unchecked Sendable {
    var result: Result<DownloadedImage, Error> = .failure(NSError(domain: "MockImageDownloader", code: 0))
    var resultsByURL: [URL: Result<DownloadedImage, Error>] = [:]
    var lastURL: URL?
    var lastOptions: ImageDownloadingOptions?
    var trimmedCosts: [Int] = []
    var downloadTasks: [ImageLoadingTask] = []

    func downloadImage(
        url: URL,
        options: ImageDownloadingOptions,
        completion: @escaping @MainActor (Result<DownloadedImage, Error>) -> Void
    ) {
        lastURL = url
        lastOptions = options
        let resolvedResult = resultsByURL[url] ?? result
        DispatchQueue.main.async {
            completion(resolvedResult)
        }
    }

    func downloadImageTask(
        url: URL,
        options: ImageDownloadingOptions,
        completion: @escaping @MainActor (Result<DownloadedImage, Error>) -> Void
    ) -> ImageLoadingTask {
        downloadImage(url: url, options: options, completion: completion)
        let task = ImageLoadingTask()
        downloadTasks.append(task)
        return task
    }

    func trimMemoryCache(toCost limit: Int) {
        trimmedCosts.append(limit)
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
