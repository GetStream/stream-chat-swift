//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

final class StreamCDNRequester_Tests: XCTestCase {
    let baseUrl = "https://www.\(StreamCDNRequester.streamCDNURL)"
    var sut: StreamCDNRequester!

    override func setUp() {
        super.setUp()
        sut = StreamCDNRequester()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Image Request

    func test_imageRequest_whenHostIsNotStreamCDNRequester_returnsUnchangedURL() {
        let url = URL(string: "https://www.google.com/image.jpg?someStuff=20")!
        let expectation = expectation(description: "Completion called")

        sut.imageRequest(for: url, options: .init(resize: CDNImageResize(width: 40, height: 40, resizeMode: "clip"))) { result in
            let request = try! result.get()
            XCTAssertEqual(request.url, url)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_imageRequest_whenNoResize_returnsUnchangedURL() {
        let url = URL(string: "\(baseUrl)/image.jpg")!
        let expectation = expectation(description: "Completion called")

        sut.imageRequest(for: url, options: .init()) { result in
            let request = try! result.get()
            XCTAssertEqual(request.url, url)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_imageRequest_addsResizeQueryParameters() {
        let url = URL(string: "\(baseUrl)/image.jpg")!
        let expectation = expectation(description: "Completion called")

        sut.imageRequest(for: url, options: .init(resize: CDNImageResize(width: 40, height: 60, resizeMode: "crop", crop: "center"))) { result in
            let request = try! result.get()
            let components = URLComponents(url: request.url, resolvingAgainstBaseURL: true)!
            let queryItems = components.queryItems ?? []
            let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

            XCTAssertNotNil(params["w"])
            XCTAssertNotNil(params["h"])
            XCTAssertEqual(params["crop"], "center")
            XCTAssertEqual(params["resize"], "crop")
            XCTAssertEqual(params["ro"], "0")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_imageRequest_fillMode_noCropParameter() {
        let url = URL(string: "\(baseUrl)/image.jpg")!
        let expectation = expectation(description: "Completion called")

        sut.imageRequest(for: url, options: .init(resize: CDNImageResize(width: 40, height: 60, resizeMode: "fill"))) { result in
            let request = try! result.get()
            let components = URLComponents(url: request.url, resolvingAgainstBaseURL: true)!
            let queryItems = components.queryItems ?? []
            let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

            XCTAssertEqual(params["resize"], "fill")
            XCTAssertNil(params["crop"])
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    // MARK: - Caching Key

    func test_imageRequest_cachingKey_stripsNonResizeParams() {
        let url = URL(string: "\(baseUrl)/image.jpg?name=Luke&w=128&h=128&crop=center&resize=crop&ro=0")!
        let expectation = expectation(description: "Completion called")

        sut.imageRequest(for: url, options: .init()) { result in
            let request = try! result.get()
            XCTAssertNotNil(request.cachingKey)
            let key = request.cachingKey!

            XCTAssertTrue(key.contains("w=128"))
            XCTAssertTrue(key.contains("h=128"))
            XCTAssertTrue(key.contains("crop=center"))
            XCTAssertTrue(key.contains("resize=crop"))
            XCTAssertFalse(key.contains("name=Luke"))
            XCTAssertFalse(key.contains("ro=0"))
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_imageRequest_cachingKey_includesResizeParamsFromOptions() {
        let url = URL(string: "\(baseUrl)/image.jpg")!
        let expectation = expectation(description: "Completion called")

        sut.imageRequest(for: url, options: .init(resize: CDNImageResize(width: 40, height: 60, resizeMode: "clip"))) { result in
            let request = try! result.get()
            let key = request.cachingKey!

            XCTAssertTrue(key.contains("w="), "Caching key should contain width from resize options")
            XCTAssertTrue(key.contains("h="), "Caching key should contain height from resize options")
            XCTAssertTrue(key.contains("resize=clip"), "Caching key should contain resize mode")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_imageRequest_cachingKey_differentResizeProducesDifferentKeys() {
        let url = URL(string: "\(baseUrl)/image.jpg")!
        let smallResize = CDNImageResize(width: 40, height: 40, resizeMode: "clip")
        let largeResize = CDNImageResize(width: 200, height: 200, resizeMode: "clip")

        let expectation1 = expectation(description: "Small resize")
        let expectation2 = expectation(description: "Large resize")
        var smallKey: String?
        var largeKey: String?

        sut.imageRequest(for: url, options: .init(resize: smallResize)) { result in
            smallKey = try! result.get().cachingKey
            expectation1.fulfill()
        }
        sut.imageRequest(for: url, options: .init(resize: largeResize)) { result in
            largeKey = try! result.get().cachingKey
            expectation2.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertNotEqual(smallKey, largeKey, "Different resize dimensions must produce different caching keys")
    }

    func test_imageRequest_cachingKey_noResize_hasNoResizeParams() {
        let url = URL(string: "\(baseUrl)/image.jpg")!
        let expectation = expectation(description: "Completion called")

        sut.imageRequest(for: url, options: .init()) { result in
            let request = try! result.get()
            let key = request.cachingKey!
            XCTAssertFalse(key.contains("w="), "Caching key without resize should not contain width")
            XCTAssertFalse(key.contains("h="), "Caching key without resize should not contain height")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_imageRequest_cachingKey_nonStreamCDNRequester_returnsFullURL() {
        let url = URL(string: "https://www.google.com/image.jpg?token=abc")!
        let expectation = expectation(description: "Completion called")

        sut.imageRequest(for: url, options: .init()) { result in
            let request = try! result.get()
            XCTAssertEqual(request.cachingKey, url.absoluteString)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    // MARK: - File Request

    func test_fileRequest_returnsUnchangedURL() {
        let url = URL(string: "https://example.com/video.mp4")!
        let expectation = expectation(description: "Completion called")

        sut.fileRequest(for: url, options: .init()) { result in
            let request = try! result.get()
            XCTAssertEqual(request.url, url)
            XCTAssertNil(request.headers)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    // MARK: - Async

    func test_imageRequest_asyncWrapper() async throws {
        let url = URL(string: "\(baseUrl)/image.jpg")!
        let request = try await sut.imageRequest(for: url)
        XCTAssertEqual(request.url, url)
    }

    func test_fileRequest_asyncWrapper() async throws {
        let url = URL(string: "https://example.com/file.pdf")!
        let request = try await sut.fileRequest(for: url)
        XCTAssertEqual(request.url, url)
    }
}
