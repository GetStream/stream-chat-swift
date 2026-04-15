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

    // MARK: - loadImages

    func test_loadImages_success_returnsImagesInInputOrder() {
        let image1 = UIImage.make(withColor: .red)
        let image2 = UIImage.make(withColor: .blue)
        let image3 = UIImage.make(withColor: .green)
        downloader.resultsByURL = [
            URL(string: "https://example.com/1.jpg")!: .success(DownloadedImage(image: image1)),
            URL(string: "https://example.com/2.jpg")!: .success(DownloadedImage(image: image2)),
            URL(string: "https://example.com/3.jpg")!: .success(DownloadedImage(image: image3))
        ]
        let urls = [
            URL(string: "https://example.com/1.jpg")!,
            URL(string: "https://example.com/2.jpg")!,
            URL(string: "https://example.com/3.jpg")!
        ]
        let expectation = expectation(description: "Completion called")

        sut.loadImages(from: urls, options: ImageBatchLoadOptions(cdnRequester: cdnRequester)) { images in
            XCTAssertEqual(images.count, 3)
            XCTAssertEqual(images[0].image.pngData(), image1.pngData())
            XCTAssertEqual(images[1].image.pngData(), image2.pngData())
            XCTAssertEqual(images[2].image.pngData(), image3.pngData())
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func test_loadImages_emptyURLs_returnsEmptyArray() {
        let expectation = expectation(description: "Completion called")

        sut.loadImages(from: [], options: ImageBatchLoadOptions(cdnRequester: cdnRequester)) { images in
            XCTAssertTrue(images.isEmpty)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func test_loadImages_failedWithPlaceholders_usesPlaceholder() {
        let placeholder = UIImage.make(withColor: .gray)
        downloader.result = .failure(NSError(domain: "test", code: 0))
        let urls = [URL(string: "https://example.com/1.jpg")!]
        let options = ImageBatchLoadOptions(
            placeholders: [placeholder],
            cdnRequester: cdnRequester
        )
        let expectation = expectation(description: "Completion called")

        sut.loadImages(from: urls, options: options) { images in
            XCTAssertEqual(images.count, 1)
            XCTAssertEqual(images[0].image.pngData(), placeholder.pngData())
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func test_loadImages_failedWithoutPlaceholders_excludesFromResults() {
        downloader.result = .failure(NSError(domain: "test", code: 0))
        let urls = [URL(string: "https://example.com/1.jpg")!]
        let options = ImageBatchLoadOptions(cdnRequester: cdnRequester)
        let expectation = expectation(description: "Completion called")

        sut.loadImages(from: urls, options: options) { images in
            XCTAssertTrue(images.isEmpty)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func test_loadImages_placeholderBoundsCheck_outOfBoundsPlaceholderSkipped() {
        let placeholder = UIImage.make(withColor: .gray)
        let image1 = UIImage.make(withColor: .red)
        downloader.resultsByURL = [
            URL(string: "https://example.com/1.jpg")!: .success(DownloadedImage(image: image1)),
            URL(string: "https://example.com/2.jpg")!: .failure(NSError(domain: "test", code: 0))
        ]
        let urls = [
            URL(string: "https://example.com/1.jpg")!,
            URL(string: "https://example.com/2.jpg")!
        ]
        // Only 1 placeholder for 2 URLs — index 1 is out of bounds
        let options = ImageBatchLoadOptions(
            placeholders: [placeholder],
            cdnRequester: cdnRequester
        )
        let expectation = expectation(description: "Completion called")

        sut.loadImages(from: urls, options: options) { images in
            XCTAssertEqual(images.count, 1)
            XCTAssertEqual(images[0].image.pngData(), image1.pngData())
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func test_loadImages_withThumbnails_passesResizeOptions() {
        let testImage = UIImage.make(withColor: .red)
        downloader.result = .success(DownloadedImage(image: testImage))
        let urls = [URL(string: "https://example.com/1.jpg")!]
        let thumbnailSize = CGSize(width: 50, height: 50)
        let options = ImageBatchLoadOptions(
            loadThumbnails: true,
            thumbnailSize: thumbnailSize,
            cdnRequester: cdnRequester
        )
        let expectation = expectation(description: "Completion called")

        sut.loadImages(from: urls, options: options) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
        XCTAssertNotNil(cdnRequester.lastImageRequestOptions?.resize)
    }

    func test_loadImages_withoutThumbnails_passesNilResize() {
        let testImage = UIImage.make(withColor: .red)
        downloader.result = .success(DownloadedImage(image: testImage))
        let urls = [URL(string: "https://example.com/1.jpg")!]
        let options = ImageBatchLoadOptions(
            loadThumbnails: false,
            cdnRequester: cdnRequester
        )
        let expectation = expectation(description: "Completion called")

        sut.loadImages(from: urls, options: options) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
        XCTAssertNil(cdnRequester.lastImageRequestOptions?.resize)
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
