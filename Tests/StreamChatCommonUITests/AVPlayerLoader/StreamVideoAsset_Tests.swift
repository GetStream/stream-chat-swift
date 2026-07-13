//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamChatCommonUI
import UniformTypeIdentifiers
import XCTest

@available(iOS 14.0, *)
final class StreamVideoAsset_Tests: XCTestCase {
    private static let originalURL = URL(string: "https://example.com/video.mp4")!

    private var root: URL!
    private var cacheDirectory: URL!
    private let fileManager = FileManager.default
    private var throwawaySession: URLSession!
    private var throwawayTask: URLSessionDataTask!

    private var delegate: StreamVideoResourceLoaderDelegate!
    private var cache: StreamVideoCache!

    override func setUpWithError() throws {
        try super.setUpWithError()
        root = fileManager.temporaryDirectory
            .appendingPathComponent("StreamVideoAsset_Tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        cacheDirectory = root.appendingPathComponent("cache", isDirectory: true)
        throwawaySession = URLSession(configuration: .ephemeral)
        throwawayTask = throwawaySession.dataTask(with: Self.originalURL)
    }

    override func tearDownWithError() throws {
        if let delegate {
            delegate.invalidate()
            delegate.queue.sync {}
        }
        delegate = nil
        cache = nil
        throwawaySession.invalidateAndCancel()
        throwawaySession = nil
        throwawayTask = nil
        try? fileManager.removeItem(at: root)
        root = nil
        cacheDirectory = nil
        try super.tearDownWithError()
    }

    func test_successfulResponseAndData_fillsContentInfo_respondsWithBytes_andStores() async throws {
        let body = Data(repeating: 0xab, count: 4096)
        makeDelegate()
        let info = MockContentInformationRequest()
        let infoRequest = MockLoadingRequest(contentInformationRequest: info)
        let data = MockDataRequest()
        let dataRequest = MockLoadingRequest(dataRequest: data)

        handle(infoRequest)
        deliverResponse(status: 200, headers: ["Content-Length": "\(body.count)", "Content-Type": "video/mp4"])
        handle(dataRequest)
        deliverData(body)
        await complete()

        XCTAssertTrue(infoRequest.didFinishLoading)
        XCTAssertEqual(info.contentLength, Int64(body.count))
        XCTAssertEqual(info.contentType, UTType(mimeType: "video/mp4")?.identifier)
        XCTAssertFalse(info.isByteRangeAccessSupported)
        XCTAssertTrue(dataRequest.didFinishLoading)
        XCTAssertEqual(data.respondedData, body)
        let cached = await cachedURL()
        let cachedFile = try XCTUnwrap(cached)
        XCTAssertEqual(try Data(contentsOf: cachedFile), body)
    }

    func test_response206WithContentRange_parsesTotalLength() async throws {
        makeDelegate()
        let info = MockContentInformationRequest()
        let request = MockLoadingRequest(contentInformationRequest: info)

        handle(request)
        deliverResponse(status: 206, headers: ["Content-Range": "bytes 0-2047/2048", "Content-Type": "video/mp4"])

        XCTAssertEqual(info.contentLength, 2048)
        XCTAssertTrue(request.didFinishLoading)
    }

    func test_responseWithoutContentType_usesFallbackFromExtension() async throws {
        makeDelegate()
        let info = MockContentInformationRequest()
        let request = MockLoadingRequest(contentInformationRequest: info)

        handle(request)
        deliverResponse(status: 200, headers: ["Content-Length": "2048"])

        XCTAssertEqual(info.contentType, UTType(filenameExtension: "mp4")?.identifier)
    }

    func test_responseWithoutContentLength_redirectsRequestsToOrigin() async throws {
        makeDelegate()
        let request = MockLoadingRequest(contentInformationRequest: MockContentInformationRequest())

        handle(request)
        deliverResponse(status: 200, headers: ["Content-Type": "video/mp4"])

        XCTAssertEqual(request.redirect?.url, Self.originalURL)
        XCTAssertEqual((request.response as? HTTPURLResponse)?.statusCode, 302)
        XCTAssertTrue(request.didFinishLoading)
        let cached = await cachedURL()
        XCTAssertNil(cached)
    }

    func test_non2xxResponse_finishesRequestsWithError() async throws {
        makeDelegate()
        let request = MockLoadingRequest(contentInformationRequest: MockContentInformationRequest())

        handle(request)
        deliverResponse(status: 404, headers: [:])
        await complete(with: URLError(.cancelled))

        XCTAssertTrue(request.didFinishLoading)
        XCTAssertNotNil(request.finishError)
        let cached = await cachedURL()
        XCTAssertNil(cached)
    }

    func test_handleWhenInvalidated_finishesRequestWithCancelled() async throws {
        makeDelegate()
        delegate.invalidate()
        delegate.queue.sync {}
        let request = MockLoadingRequest(contentInformationRequest: MockContentInformationRequest())

        handle(request)

        XCTAssertTrue(request.didFinishLoading)
        XCTAssertEqual((request.finishError as? URLError)?.code, .cancelled)
    }

    func test_cancel_removesPendingRequest() async throws {
        makeDelegate()
        let request = MockLoadingRequest(contentInformationRequest: MockContentInformationRequest())

        handle(request)
        delegate.queue.sync { delegate.cancel(request) }
        deliverResponse(status: 200, headers: ["Content-Length": "2048", "Content-Type": "video/mp4"])

        XCTAssertFalse(request.didFinishLoading)
    }

    // MARK: - Helpers

    private func makeDelegate() {
        let cache = StreamVideoCache(directory: cacheDirectory, maxSizeInBytes: 10_000_000)
        self.cache = cache
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        delegate = StreamVideoResourceLoaderDelegate(
            originalURL: Self.originalURL,
            origin: URLRequest(url: Self.originalURL),
            fileExtension: "mp4",
            cache: cache,
            sessionConfiguration: configuration
        )
    }

    private func handle(_ request: any StreamVideoLoadingRequest) {
        delegate.queue.sync { delegate.handle(request) }
    }

    private func deliverResponse(status: Int, headers: [String: String]) {
        let response = HTTPURLResponse(
            url: Self.originalURL,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )!
        delegate.urlSession(throwawaySession, dataTask: throwawayTask, didReceive: response) { _ in }
        delegate.queue.sync {}
    }

    private func deliverData(_ data: Data) {
        delegate.urlSession(throwawaySession, dataTask: throwawayTask, didReceive: data)
        delegate.queue.sync {}
    }

    private func complete(with error: Error? = nil) async {
        delegate.urlSession(throwawaySession, task: throwawayTask, didCompleteWithError: error)
        delegate.queue.sync {}
        _ = await cachedURL()
        delegate.queue.sync {}
    }

    private func cachedURL() async -> URL? {
        await cache.completedFileURL(forKey: Self.originalURL.path, fileExtension: "mp4")
    }
}

private final class MockLoadingRequest: StreamVideoLoadingRequest {
    let streamContentInformationRequest: StreamVideoContentInformationRequest?
    let streamDataRequest: StreamVideoDataRequest?
    var redirect: URLRequest?
    var response: URLResponse?
    private(set) var didFinishLoading = false
    private(set) var finishError: Error?

    init(
        contentInformationRequest: MockContentInformationRequest? = nil,
        dataRequest: MockDataRequest? = nil
    ) {
        streamContentInformationRequest = contentInformationRequest
        streamDataRequest = dataRequest
    }

    func finishLoading() {
        didFinishLoading = true
    }

    func finishLoading(with error: Error?) {
        didFinishLoading = true
        finishError = error
    }
}

private final class MockContentInformationRequest: StreamVideoContentInformationRequest {
    var contentLength: Int64 = 0
    var contentType: String?
    var isByteRangeAccessSupported = false
}

private final class MockDataRequest: StreamVideoDataRequest {
    let requestedOffset: Int64
    private(set) var currentOffset: Int64
    let requestedLength: Int
    let requestsAllDataToEndOfResource: Bool
    private(set) var respondedData = Data()

    init(requestedOffset: Int64 = 0, requestedLength: Int = 0, requestsAllDataToEndOfResource: Bool = true) {
        self.requestedOffset = requestedOffset
        currentOffset = requestedOffset
        self.requestedLength = requestedLength
        self.requestsAllDataToEndOfResource = requestsAllDataToEndOfResource
    }

    func respond(with data: Data) {
        respondedData.append(data)
        currentOffset += Int64(data.count)
    }
}

private final class MockURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {}
    override func stopLoading() {}
}
