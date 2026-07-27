//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatCommonUI
import UIKit
import XCTest

final class StreamImageDownloader_Tests: XCTestCase {
    private var cacheDirectory: URL!
    private var urlCache: RecordingURLCache!
    private var sut: StreamImageDownloader!

    override func setUpWithError() throws {
        try super.setUpWithError()
        StreamImageDownloaderURLProtocolMock.reset()
        cacheDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("StreamImageDownloader_Tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        urlCache = RecordingURLCache(memoryCapacity: 0, diskCapacity: 50 * 1024 * 1024, directory: cacheDirectory)

        sut = makeLoader()
    }

    override func tearDownWithError() throws {
        sut = nil
        urlCache.removeAllCachedResponses()
        urlCache = nil
        try? FileManager.default.removeItem(at: cacheDirectory)
        cacheDirectory = nil
        StreamImageDownloaderURLProtocolMock.reset()
        try super.tearDownWithError()
    }

    func test_init_withZeroDiskCacheSize_disablesTheURLCache() {
        let loader = StreamImageDownloader(diskCacheSize: 0)

        XCTAssertNil(loader.urlSession.configuration.urlCache)
    }

    func test_init_configuresAnHTTPDiskCacheHonouringCacheHeaders() {
        let loader = StreamImageDownloader(diskCacheSize: 4 * 1024 * 1024)

        let configuration = loader.urlSession.configuration
        // The default policy is what makes URLSession honour max-age and revalidate with ETags.
        XCTAssertEqual(configuration.requestCachePolicy, .useProtocolCachePolicy)
        XCTAssertEqual(configuration.urlCache?.memoryCapacity, 0)
        XCTAssertEqual(configuration.urlCache?.diskCapacity, 4 * 1024 * 1024)
    }

    func test_downloadImage_downloadsAndDecodesImage() async throws {
        let url = URL(string: "https://example.com/a.png")!
        StreamImageDownloaderURLProtocolMock.stub(url, data: pngData(width: 40, height: 40))

        let received = try await download(url: url, options: ImageDownloadingOptions())

        XCTAssertNotNil(received.image.cgImage)
        XCTAssertEqual(StreamImageDownloaderURLProtocolMock.requestCount(for: url), 1)
    }

    @MainActor
    func test_downloadImage_memoryCacheHitCompletesSynchronously() {
        let url = URL(string: "https://example.com/b.png")!
        sut.store(DownloadedImage(image: renderedImage(width: 20, height: 20)), for: url, options: ImageDownloadingOptions())

        var result: Result<DownloadedImage, Error>?
        sut.downloadImage(url: url, options: ImageDownloadingOptions()) { result = $0 }

        XCTAssertNotNil(result, "A cached image must complete synchronously")
        XCTAssertEqual(StreamImageDownloaderURLProtocolMock.requestCount(for: url), 0)
    }

    @MainActor
    func test_downloadImage_usesCachingKeyAcrossDifferentURLs() {
        let seededURL = URL(string: "https://cdn.example.com/x.png?sig=old")!
        let reloadedURL = URL(string: "https://cdn.example.com/x.png?sig=new")!
        let cachingKey = "https://cdn.example.com/x.png"
        sut.store(
            DownloadedImage(image: renderedImage(width: 20, height: 20)),
            for: seededURL,
            options: ImageDownloadingOptions(cachingKey: cachingKey)
        )

        var result: Result<DownloadedImage, Error>?
        sut.downloadImage(url: reloadedURL, options: ImageDownloadingOptions(cachingKey: cachingKey)) { result = $0 }

        XCTAssertNotNil(try? result?.get(), "A re-signed URL should hit the cache seeded under the caching key")
        XCTAssertEqual(StreamImageDownloaderURLProtocolMock.requestCount(for: reloadedURL), 0)
    }

    func test_memoryCache_distinguishesFractionalResizeDimensions() {
        let url = URL(string: "https://example.com/fractional.png")!
        sut.store(
            DownloadedImage(image: renderedImage(width: 20, height: 20)),
            for: url,
            options: ImageDownloadingOptions(resize: CGSize(width: 10.1, height: 10.1))
        )

        let cached = sut.cachedImage(
            for: url,
            options: ImageDownloadingOptions(resize: CGSize(width: 10.4, height: 10.4))
        )

        XCTAssertNil(cached)
    }

    func test_memoryCache_withoutExplicitCachingKey_distinguishesRequestHeaders() {
        let url = URL(string: "https://example.com/protected.png")!
        sut.store(
            DownloadedImage(image: renderedImage(width: 20, height: 20)),
            for: url,
            options: ImageDownloadingOptions(headers: ["Authorization": "Bearer one"])
        )

        let cached = sut.cachedImage(
            for: url,
            options: ImageDownloadingOptions(headers: ["authorization": "Bearer two"])
        )

        XCTAssertNil(cached)
    }

    func test_downloadImage_coalescesConcurrentRequests() {
        let url = URL(string: "https://example.com/dedup.png")!
        StreamImageDownloaderURLProtocolMock.stub(url, data: pngData(width: 40, height: 40), delay: 0.05)

        let expectation = expectation(description: "all completions")
        expectation.expectedFulfillmentCount = 10
        for _ in 0..<10 {
            sut.downloadImage(url: url, options: ImageDownloadingOptions()) { _ in expectation.fulfill() }
        }
        wait(for: [expectation], timeout: 5)

        XCTAssertEqual(StreamImageDownloaderURLProtocolMock.requestCount(for: url), 1, "Concurrent requests should share a single download")
    }

    func test_downloadImage_differentResizeVariants_shareSourceDownload() {
        let url = URL(string: "https://example.com/variants.png")!
        StreamImageDownloaderURLProtocolMock.stub(url, data: pngData(width: 400, height: 400), delay: 0.05)
        let expectation = expectation(description: "both variants")
        expectation.expectedFulfillmentCount = 2

        sut.downloadImage(
            url: url,
            options: ImageDownloadingOptions(cachingKey: "stable-source", resize: CGSize(width: 50, height: 50))
        ) { _ in expectation.fulfill() }
        sut.downloadImage(
            url: url,
            options: ImageDownloadingOptions(cachingKey: "stable-source", resize: CGSize(width: 100, height: 100))
        ) { _ in expectation.fulfill() }

        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(StreamImageDownloaderURLProtocolMock.requestCount(for: url), 1)
    }

    func test_downloadImage_storesTheResponseInTheURLCacheWithItsCacheHeaders() async throws {
        let url = URL(string: "https://example.com/cacheable.png")!
        let data = pngData(width: 40, height: 40)
        StreamImageDownloaderURLProtocolMock.stub(url, data: data, headers: ["Cache-Control": "max-age=3600"])

        _ = try await download(url: url, options: ImageDownloadingOptions())

        let cached = urlCache.cachedResponse(for: URLRequest(url: url))
        XCTAssertEqual(cached?.data, data)
        XCTAssertEqual(
            (cached?.response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Cache-Control"),
            "max-age=3600"
        )
    }

    func test_downloadImage_whenDownloadedDataIsInvalid_fails() async {
        let url = URL(string: "https://example.com/invalid.png")!
        StreamImageDownloaderURLProtocolMock.stub(url, data: Data([0x00]))

        do {
            _ = try await download(url: url, options: ImageDownloadingOptions())
            XCTFail("Expected invalid image data to throw")
        } catch {}
    }

    func test_removeAllImagesFromDiskCache_clearsTheURLCache() {
        sut.removeAllImagesFromDiskCache()

        XCTAssertEqual(urlCache.removeAllCachedResponsesCallCount, 1)
    }

    func test_downloadImage_passesThroughGIFData() async throws {
        let url = URL(string: "https://example.com/anim.gif")!
        let gif = gifData()
        StreamImageDownloaderURLProtocolMock.stub(url, data: gif)

        let received = try await download(url: url, options: ImageDownloadingOptions())

        XCTAssertEqual(received.animatedImageData, gif)
    }

    func test_downloadImage_appliesResize() async throws {
        let url = URL(string: "https://example.com/big.png")!
        StreamImageDownloaderURLProtocolMock.stub(url, data: pngData(width: 400, height: 400))

        let received = try await download(url: url, options: ImageDownloadingOptions(resize: CGSize(width: 50, height: 50)))

        XCTAssertEqual(received.image.cgImage?.width, Int((50 * StreamImageDownloader.displayScale).rounded()))
    }

    func test_downloadImage_forwardsHeaders() async throws {
        let url = URL(string: "https://example.com/headers.png")!
        StreamImageDownloaderURLProtocolMock.stub(url, data: pngData(width: 20, height: 20))

        _ = try await download(url: url, options: ImageDownloadingOptions(headers: ["Authorization": "Bearer token"]))

        XCTAssertEqual(StreamImageDownloaderURLProtocolMock.headers(for: url)?["Authorization"], "Bearer token")
    }

    func test_downloadImage_failsOnHTTPError() async {
        let url = URL(string: "https://example.com/error.png")!
        StreamImageDownloaderURLProtocolMock.stub(url, statusCode: 500, data: nil)

        do {
            _ = try await download(url: url, options: ImageDownloadingOptions())
            XCTFail("Expected the download to fail")
        } catch {}
    }

    // MARK: - Helpers

    private func download(url: URL, options: ImageDownloadingOptions) async throws -> DownloadedImage {
        try await withCheckedThrowingContinuation { continuation in
            sut.downloadImage(url: url, options: options) {
                continuation.resume(with: $0)
            }
        }
    }

    private func makeLoader() -> StreamImageDownloader {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [StreamImageDownloaderURLProtocolMock.self]
        configuration.urlCache = urlCache
        return StreamImageDownloader(
            memoryCostLimit: 50 * 1024 * 1024,
            urlSession: URLSession(configuration: configuration)
        )
    }

    private func renderedImage(width: Int, height: Int) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let size = CGSize(width: width, height: height)
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.systemIndigo.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func pngData(width: Int, height: Int) -> Data {
        renderedImage(width: width, height: height).pngData()!
    }

    private func gifData() -> Data {
        let cgImage = renderedImage(width: 4, height: 4).cgImage!
        let output = NSMutableData()
        let destination = CGImageDestinationCreateWithData(output, "com.compuserve.gif" as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, cgImage, nil)
        CGImageDestinationFinalize(destination)
        return output as Data
    }
}

// MARK: - URLCache spy

/// `URLCache` clears its storage on its own queue, so a lookup right after
/// `removeAllCachedResponses()` can still report the entry. Recording the call keeps the
/// assertion about what the downloader does rather than about Foundation's timing.
private final class RecordingURLCache: URLCache, @unchecked Sendable {
    private(set) var removeAllCachedResponsesCallCount = 0

    override func removeAllCachedResponses() {
        removeAllCachedResponsesCallCount += 1
        super.removeAllCachedResponses()
    }
}

// MARK: - URLProtocol mock

private final class StreamImageDownloaderURLProtocolMock: URLProtocol {
    private struct Stub {
        let statusCode: Int
        let data: Data?
        let headers: [String: String]?
        let delay: TimeInterval
    }

    private static let lock = NSLock()
    private nonisolated(unsafe) static var stubs: [URL: Stub] = [:]
    private nonisolated(unsafe) static var counts: [URL: Int] = [:]
    private nonisolated(unsafe) static var recordedHeaders: [URL: [String: String]] = [:]

    static func reset() {
        lock.lock()
        stubs = [:]
        counts = [:]
        recordedHeaders = [:]
        lock.unlock()
    }

    static func stub(
        _ url: URL,
        statusCode: Int = 200,
        data: Data?,
        headers: [String: String]? = nil,
        delay: TimeInterval = 0
    ) {
        lock.lock()
        stubs[url] = Stub(statusCode: statusCode, data: data, headers: headers, delay: delay)
        lock.unlock()
    }

    static func requestCount(for url: URL) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return counts[url] ?? 0
    }

    static func headers(for url: URL) -> [String: String]? {
        lock.lock()
        defer { lock.unlock() }
        return recordedHeaders[url]
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        Self.lock.lock()
        Self.counts[url, default: 0] += 1
        Self.recordedHeaders[url] = request.allHTTPHeaderFields
        let stub = Self.stubs[url]
        Self.lock.unlock()

        if let delay = stub?.delay, delay > 0 {
            Thread.sleep(forTimeInterval: delay)
        }

        guard let stub else {
            client?.urlProtocol(self, didFailWithError: URLError(.fileDoesNotExist))
            return
        }
        if let response = HTTPURLResponse(url: url, statusCode: stub.statusCode, httpVersion: "HTTP/1.1", headerFields: stub.headers) {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
        }
        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
