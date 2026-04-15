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
        sut = StreamMediaLoader(downloader: downloader)
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

        sut.loadImage(url: nil, options: ImageLoadOptions(cdnRequester: cdnRequester)) { result in
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

        sut.loadImage(url: url, options: ImageLoadOptions(cdnRequester: cdnRequester)) { result in
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

        sut.loadImage(url: url, options: ImageLoadOptions(cdnRequester: cdnRequester)) { result in
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

        sut.loadImage(url: url, options: ImageLoadOptions(cdnRequester: cdnRequester)) { result in
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

        sut.loadImage(url: url, options: ImageLoadOptions(resize: resize, cdnRequester: cdnRequester)) { _ in
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

        sut.loadImage(url: url, options: ImageLoadOptions(cdnRequester: cdnRequester)) { _ in
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

        sut.loadImage(url: url, options: ImageLoadOptions(cdnRequester: cdnRequester)) { _ in
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

        sut.loadImage(url: originalURL, options: ImageLoadOptions(cdnRequester: cdnRequester)) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
        XCTAssertEqual(downloader.lastURL, transformedURL)
    }

    // MARK: - init

    func test_init_setsDownloader() {
        XCTAssertTrue(sut.downloader is MockImageDownloader)
    }
}

// MARK: - Mocks

private final class MockCDNRequester: CDNRequester, @unchecked Sendable {
    var imageRequestResult: Result<CDNRequest, Error>?
    var lastImageRequestOptions: ImageRequestOptions?

    func imageRequest(for url: URL, options: ImageRequestOptions, completion: @escaping (Result<CDNRequest, Error>) -> Void) {
        lastImageRequestOptions = options
        completion(imageRequestResult ?? .success(CDNRequest(url: url)))
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
