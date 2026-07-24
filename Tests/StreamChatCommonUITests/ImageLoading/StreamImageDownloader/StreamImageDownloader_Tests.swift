//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CryptoKit
@testable import StreamChatCommonUI
import StreamCore
import UIKit
import XCTest

final class StreamImageDownloader_Tests: XCTestCase {
    private var diskDirectory: URL!
    private var sut: StreamImageDownloader!

    override func setUpWithError() throws {
        try super.setUpWithError()
        StreamImageDownloaderStubURLProtocol.reset()
        diskDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("StreamImageDownloader_Tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        sut = makeLoader()
    }

    override func tearDownWithError() throws {
        sut = nil
        try? FileManager.default.removeItem(at: diskDirectory)
        diskDirectory = nil
        StreamImageDownloaderStubURLProtocol.reset()
        try super.tearDownWithError()
    }

    func test_init_acceptsDiskCacheSizeWithoutOtherConfiguration() {
        let loader = StreamImageDownloader(diskCacheSize: 0)

        XCTAssertNotNil(loader)
    }

    func test_downloadImage_downloadsAndDecodesImage() {
        let url = URL(string: "https://example.com/a.png")!
        StreamImageDownloaderStubURLProtocol.stub(url, data: pngData(width: 40, height: 40))

        let received = downloadSynchronously(url: url, options: ImageDownloadingOptions())

        XCTAssertNotNil(try? received?.get())
        XCTAssertEqual(StreamImageDownloaderStubURLProtocol.requestCount(for: url), 1)
    }

    @MainActor
    func test_downloadImage_memoryCacheHitCompletesSynchronously() {
        let url = URL(string: "https://example.com/b.png")!
        sut.store(DownloadedImage(image: renderedImage(width: 20, height: 20)), for: url, options: ImageDownloadingOptions())

        var result: Result<DownloadedImage, Error>?
        sut.downloadImage(url: url, options: ImageDownloadingOptions()) { result = $0 }

        XCTAssertNotNil(result, "A cached image must complete synchronously")
        XCTAssertEqual(StreamImageDownloaderStubURLProtocol.requestCount(for: url), 0)
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
        XCTAssertEqual(StreamImageDownloaderStubURLProtocol.requestCount(for: reloadedURL), 0)
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
        StreamImageDownloaderStubURLProtocol.stub(url, data: pngData(width: 40, height: 40), delay: 0.05)

        let expectation = expectation(description: "all completions")
        expectation.expectedFulfillmentCount = 10
        for _ in 0..<10 {
            sut.downloadImage(url: url, options: ImageDownloadingOptions()) { _ in expectation.fulfill() }
        }
        wait(for: [expectation], timeout: 5)

        XCTAssertEqual(StreamImageDownloaderStubURLProtocol.requestCount(for: url), 1, "Concurrent requests should share a single download")
    }

    func test_downloadImage_differentResizeVariants_shareSourceDownload() {
        let url = URL(string: "https://example.com/variants.png")!
        StreamImageDownloaderStubURLProtocol.stub(url, data: pngData(width: 400, height: 400), delay: 0.05)
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
        XCTAssertEqual(StreamImageDownloaderStubURLProtocol.requestCount(for: url), 1)
    }

    func test_downloadImage_servedFromDiskCacheWithoutNetwork() throws {
        let url = URL(string: "https://example.com/disk.png")!
        // Pre-seed the disk cache with the file the loader would look up (no stub → network would fail).
        try FileManager.default.createDirectory(at: diskDirectory, withIntermediateDirectories: true)
        try pngData(width: 40, height: 40).write(to: diskDirectory.appendingPathComponent(sha256Hex(url.absoluteString)))

        let received = downloadSynchronously(url: url, options: ImageDownloadingOptions())

        XCTAssertNotNil(try? received?.get())
        XCTAssertEqual(StreamImageDownloaderStubURLProtocol.requestCount(for: url), 0)
    }

    func test_downloadImage_afterLoaderIsRecreated_usesOriginalDataForNewResizeVariant() async throws {
        let url = URL(string: "https://example.com/persisted.png")!
        StreamImageDownloaderStubURLProtocol.stub(url, data: pngData(width: 400, height: 400))
        _ = await download(
            url: url,
            options: ImageDownloadingOptions(resize: CGSize(width: 50, height: 50))
        )
        let reloaded = makeLoader()

        let result = await download(
            using: reloaded,
            url: url,
            options: ImageDownloadingOptions(resize: CGSize(width: 100, height: 100))
        )

        XCTAssertEqual(try result.get().image.cgImage?.width, Int((100 * StreamImageDownloader.displayScale).rounded()))
        XCTAssertEqual(StreamImageDownloaderStubURLProtocol.requestCount(for: url), 1)
    }

    func test_downloadImage_whenDiskEntryIsCorrupt_removesItAndRefetches() async throws {
        let url = URL(string: "https://example.com/corrupt.png")!
        try FileManager.default.createDirectory(at: diskDirectory, withIntermediateDirectories: true)
        try Data([0x00]).write(to: diskDirectory.appendingPathComponent(sha256Hex(url.absoluteString)))
        StreamImageDownloaderStubURLProtocol.stub(url, data: pngData(width: 40, height: 40))

        let result = await download(url: url, options: ImageDownloadingOptions())

        XCTAssertNotNil(try result.get().image.cgImage)
        XCTAssertEqual(StreamImageDownloaderStubURLProtocol.requestCount(for: url), 1)
    }

    func test_downloadImage_whenDownloadedDataIsInvalid_doesNotPersistIt() async {
        let url = URL(string: "https://example.com/invalid.png")!
        StreamImageDownloaderStubURLProtocol.stub(url, data: Data([0x00]))

        let result = await download(url: url, options: ImageDownloadingOptions())

        XCTAssertThrowsError(try result.get())
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: diskDirectory.appendingPathComponent(sha256Hex(url.absoluteString)).path
        ))
    }

    func test_removeAllImagesFromDiskCache_forcesNetworkAfterMemoryClear() async {
        let url = URL(string: "https://example.com/clear-disk.png")!
        StreamImageDownloaderStubURLProtocol.stub(url, data: pngData(width: 40, height: 40))
        _ = await download(url: url, options: ImageDownloadingOptions())

        sut.removeAllImagesFromMemoryCache()
        await withCheckedContinuation { continuation in
            sut.removeAllImagesFromDiskCache { continuation.resume() }
        }
        _ = await download(url: url, options: ImageDownloadingOptions())

        XCTAssertEqual(StreamImageDownloaderStubURLProtocol.requestCount(for: url), 2)
    }

    func test_downloadImage_passesThroughGIFData() {
        let url = URL(string: "https://example.com/anim.gif")!
        let gif = gifData()
        StreamImageDownloaderStubURLProtocol.stub(url, data: gif)

        let received = try? downloadSynchronously(url: url, options: ImageDownloadingOptions())?.get()

        XCTAssertEqual(received?.animatedImageData, gif)
    }

    func test_downloadImage_appliesResize() {
        let url = URL(string: "https://example.com/big.png")!
        StreamImageDownloaderStubURLProtocol.stub(url, data: pngData(width: 400, height: 400))

        let received = try? downloadSynchronously(url: url, options: ImageDownloadingOptions(resize: CGSize(width: 50, height: 50)))?.get()

        XCTAssertEqual(received?.image.cgImage?.width, Int((50 * StreamImageDownloader.displayScale).rounded()))
    }

    func test_downloadImage_forwardsHeaders() {
        let url = URL(string: "https://example.com/headers.png")!
        StreamImageDownloaderStubURLProtocol.stub(url, data: pngData(width: 20, height: 20))

        _ = downloadSynchronously(url: url, options: ImageDownloadingOptions(headers: ["Authorization": "Bearer token"]))

        XCTAssertEqual(StreamImageDownloaderStubURLProtocol.headers(for: url)?["Authorization"], "Bearer token")
    }

    func test_downloadImage_failsOnHTTPError() {
        let url = URL(string: "https://example.com/error.png")!
        StreamImageDownloaderStubURLProtocol.stub(url, statusCode: 500, data: nil)

        let received = downloadSynchronously(url: url, options: ImageDownloadingOptions())

        XCTAssertThrowsError(try received?.get())
    }

    // MARK: - Helpers

    private func downloadSynchronously(url: URL, options: ImageDownloadingOptions) -> Result<DownloadedImage, Error>? {
        let expectation = expectation(description: "download \(url)")
        let result = AllocatedUnfairLock<Result<DownloadedImage, Error>?>(nil)
        sut.downloadImage(url: url, options: options) {
            result.value = $0
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
        return result.value
    }

    private func download(url: URL, options: ImageDownloadingOptions) async -> Result<DownloadedImage, Error> {
        await download(using: sut, url: url, options: options)
    }

    private func download(
        using loader: StreamImageDownloader,
        url: URL,
        options: ImageDownloadingOptions
    ) async -> Result<DownloadedImage, Error> {
        await withCheckedContinuation { continuation in
            loader.downloadImage(url: url, options: options) {
                continuation.resume(returning: $0)
            }
        }
    }

    private func makeLoader() -> StreamImageDownloader {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StreamImageDownloaderStubURLProtocol.self]
        return StreamImageDownloader(
            memoryCostLimit: 50 * 1024 * 1024,
            diskSizeLimit: 50 * 1024 * 1024,
            diskDirectory: diskDirectory,
            urlSession: URLSession(configuration: configuration)
        )
    }

    private func sha256Hex(_ string: String) -> String {
        SHA256.hash(data: Data(string.utf8)).map { String(format: "%02x", $0) }.joined()
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

// MARK: - URLProtocol stub

private final class StreamImageDownloaderStubURLProtocol: URLProtocol {
    private struct Stub {
        let statusCode: Int
        let data: Data?
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

    static func stub(_ url: URL, statusCode: Int = 200, data: Data?, delay: TimeInterval = 0) {
        lock.lock()
        stubs[url] = Stub(statusCode: statusCode, data: data, delay: delay)
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
        if let response = HTTPURLResponse(url: url, statusCode: stub.statusCode, httpVersion: nil, headerFields: nil) {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
