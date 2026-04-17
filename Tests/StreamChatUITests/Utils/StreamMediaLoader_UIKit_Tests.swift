//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
import XCTest

final class StreamMediaLoader_UIKit_Tests: XCTestCase {
    private var cdnRequester: MockCDNRequester!
    private var downloader: MockImageDownloader!
    private var sut: StreamMediaLoader!

    @MainActor
    override func setUp() {
        super.setUp()
        cdnRequester = MockCDNRequester()
        downloader = MockImageDownloader()
        sut = StreamMediaLoader(downloader: downloader)
    }

    override func tearDown() {
        sut = nil
        downloader = nil
        cdnRequester = nil
        super.tearDown()
    }

    // MARK: - loadImage(into:from:with:completion:)

    @MainActor
    func test_loadImageInto_nilURL_setsPlaceholder() {
        let imageView = UIImageView()
        let placeholder = UIImage.make(withColor: .gray)
        let options = ImageLoaderOptions(placeholder: placeholder, cdnRequester: cdnRequester)

        sut.loadImage(into: imageView, from: nil, with: options)

        XCTAssertEqual(imageView.image?.pngData(), placeholder.pngData())
    }

    @MainActor
    func test_loadImageInto_nilURL_noPlaceholder_setsNilImage() {
        let imageView = UIImageView()
        let options = ImageLoaderOptions(cdnRequester: cdnRequester)

        sut.loadImage(into: imageView, from: nil, with: options)

        XCTAssertNil(imageView.image)
    }

    @MainActor
    func test_loadImageInto_success_setsImage() {
        let testImage = UIImage.make(withColor: .red)
        downloader.result = .success(DownloadedImage(image: testImage))
        let imageView = UIImageView()
        let url = URL(string: "https://example.com/image.jpg")!
        let options = ImageLoaderOptions(cdnRequester: cdnRequester)
        let expectation = expectation(description: "Completion called")

        sut.loadImage(into: imageView, from: url, with: options) { result in
            switch result {
            case let .success(image):
                XCTAssertEqual(image.pngData(), testImage.pngData())
            case .failure:
                XCTFail("Should succeed")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
        XCTAssertEqual(imageView.image?.pngData(), testImage.pngData())
    }

    @MainActor
    func test_loadImageInto_failure_callsCompletionWithError() {
        let expectedError = NSError(domain: "test", code: 42)
        downloader.result = .failure(expectedError)
        let imageView = UIImageView()
        let url = URL(string: "https://example.com/image.jpg")!
        let options = ImageLoaderOptions(cdnRequester: cdnRequester)
        let expectation = expectation(description: "Completion called")

        sut.loadImage(into: imageView, from: url, with: options) { result in
            switch result {
            case .success:
                XCTFail("Should fail")
            case let .failure(error):
                XCTAssertEqual((error as NSError).code, 42)
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    @MainActor
    func test_loadImageInto_returnsImageLoadingTask() {
        let testImage = UIImage.make(withColor: .red)
        downloader.result = .success(DownloadedImage(image: testImage))
        let imageView = UIImageView()
        let url = URL(string: "https://example.com/image.jpg")!
        let options = ImageLoaderOptions(cdnRequester: cdnRequester)

        let task = sut.loadImage(into: imageView, from: url, with: options)

        XCTAssertFalse(task.isCancelled)
    }

    @MainActor
    func test_loadImageInto_cancelledTask_doesNotUpdateImageView() {
        let testImage = UIImage.make(withColor: .red)
        downloader.completionDelay = 0.1
        downloader.result = .success(DownloadedImage(image: testImage))
        let imageView = UIImageView()
        let url = URL(string: "https://example.com/image.jpg")!
        let options = ImageLoaderOptions(cdnRequester: cdnRequester)
        let expectation = expectation(description: "Wait for delayed completion")
        expectation.isInverted = true

        let task = sut.loadImage(into: imageView, from: url, with: options) { _ in
            expectation.fulfill()
        }
        task.cancel()

        waitForExpectations(timeout: 0.5)
        XCTAssertNil(imageView.image)
    }

    @MainActor
    func test_loadImageInto_cancels_previousTask() {
        let imageView = UIImageView()
        let url1 = URL(string: "https://example.com/1.jpg")!
        let url2 = URL(string: "https://example.com/2.jpg")!
        let options = ImageLoaderOptions(cdnRequester: cdnRequester)
        downloader.completionDelay = 0.1
        downloader.result = .success(DownloadedImage(image: UIImage.make(withColor: .red)))

        let firstTask = sut.loadImage(into: imageView, from: url1, with: options)
        _ = sut.loadImage(into: imageView, from: url2, with: options)

        XCTAssertTrue(firstTask.isCancelled)
    }

    // MARK: - downloadImage

    func test_downloadImage_success_returnsImage() {
        let testImage = UIImage.make(withColor: .blue)
        downloader.result = .success(DownloadedImage(image: testImage))
        let request = ImageDownloadRequest(
            url: URL(string: "https://example.com/image.jpg")!,
            options: ImageDownloadOptions(cdnRequester: cdnRequester)
        )
        let expectation = expectation(description: "Completion called")

        sut.downloadImage(with: request) { result in
            switch result {
            case let .success(image):
                XCTAssertEqual(image.pngData(), testImage.pngData())
            case .failure:
                XCTFail("Should succeed")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func test_downloadImage_failure_propagatesError() {
        let expectedError = NSError(domain: "test", code: 99)
        downloader.result = .failure(expectedError)
        let request = ImageDownloadRequest(
            url: URL(string: "https://example.com/image.jpg")!,
            options: ImageDownloadOptions(cdnRequester: cdnRequester)
        )
        let expectation = expectation(description: "Completion called")

        sut.downloadImage(with: request) { result in
            switch result {
            case .success:
                XCTFail("Should fail")
            case let .failure(error):
                XCTAssertEqual((error as NSError).code, 99)
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func test_downloadImage_passesResizeOptions() {
        let testImage = UIImage.make(withColor: .blue)
        downloader.result = .success(DownloadedImage(image: testImage))
        let resize = ImageResize(CGSize(width: 200, height: 300))
        let request = ImageDownloadRequest(
            url: URL(string: "https://example.com/image.jpg")!,
            options: ImageDownloadOptions(resize: resize, cdnRequester: cdnRequester)
        )
        let expectation = expectation(description: "Completion called")

        sut.downloadImage(with: request) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
        XCTAssertNotNil(cdnRequester.lastImageRequestOptions?.resize)
    }

    // MARK: - downloadMultipleImages

    func test_downloadMultipleImages_preservesOrder() {
        let image1 = UIImage.make(withColor: .red)
        let image2 = UIImage.make(withColor: .blue)
        let image3 = UIImage.make(withColor: .green)
        downloader.resultsByURL = [
            URL(string: "https://example.com/1.jpg")!: .success(DownloadedImage(image: image1)),
            URL(string: "https://example.com/2.jpg")!: .success(DownloadedImage(image: image2)),
            URL(string: "https://example.com/3.jpg")!: .success(DownloadedImage(image: image3))
        ]
        let requests = [
            ImageDownloadRequest(url: URL(string: "https://example.com/1.jpg")!, options: ImageDownloadOptions(cdnRequester: cdnRequester)),
            ImageDownloadRequest(url: URL(string: "https://example.com/2.jpg")!, options: ImageDownloadOptions(cdnRequester: cdnRequester)),
            ImageDownloadRequest(url: URL(string: "https://example.com/3.jpg")!, options: ImageDownloadOptions(cdnRequester: cdnRequester))
        ]
        let expectation = expectation(description: "Completion called")

        sut.downloadMultipleImages(with: requests) { results in
            XCTAssertEqual(results.count, 3)
            if case let .success(img1) = results[0] {
                XCTAssertEqual(img1.pngData(), image1.pngData())
            } else {
                XCTFail("First result should succeed")
            }
            if case let .success(img2) = results[1] {
                XCTAssertEqual(img2.pngData(), image2.pngData())
            } else {
                XCTFail("Second result should succeed")
            }
            if case let .success(img3) = results[2] {
                XCTAssertEqual(img3.pngData(), image3.pngData())
            } else {
                XCTFail("Third result should succeed")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func test_downloadMultipleImages_mixedResults_preservesOrder() {
        let image1 = UIImage.make(withColor: .red)
        let error2 = NSError(domain: "test", code: 2)
        let image3 = UIImage.make(withColor: .green)
        downloader.resultsByURL = [
            URL(string: "https://example.com/1.jpg")!: .success(DownloadedImage(image: image1)),
            URL(string: "https://example.com/2.jpg")!: .failure(error2),
            URL(string: "https://example.com/3.jpg")!: .success(DownloadedImage(image: image3))
        ]
        let requests = [
            ImageDownloadRequest(url: URL(string: "https://example.com/1.jpg")!, options: ImageDownloadOptions(cdnRequester: cdnRequester)),
            ImageDownloadRequest(url: URL(string: "https://example.com/2.jpg")!, options: ImageDownloadOptions(cdnRequester: cdnRequester)),
            ImageDownloadRequest(url: URL(string: "https://example.com/3.jpg")!, options: ImageDownloadOptions(cdnRequester: cdnRequester))
        ]
        let expectation = expectation(description: "Completion called")

        sut.downloadMultipleImages(with: requests) { results in
            XCTAssertEqual(results.count, 3)
            if case .success = results[0] { } else { XCTFail("First should succeed") }
            if case .failure = results[1] { } else { XCTFail("Second should fail") }
            if case .success = results[2] { } else { XCTFail("Third should succeed") }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func test_downloadMultipleImages_emptyRequests_returnsEmptyArray() {
        let expectation = expectation(description: "Completion called")

        sut.downloadMultipleImages(with: []) { results in
            XCTAssertTrue(results.isEmpty)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    // MARK: - loadImage(into:from:attachmentPayload:)

    @MainActor
    func test_loadImageFromAttachment_withDimensions_passesCalculatedResize() {
        let testImage = UIImage.make(withColor: .red)
        downloader.result = .success(DownloadedImage(image: testImage))
        let imageView = UIImageView()
        let payload = ImageAttachmentPayload(
            title: nil,
            imageRemoteURL: URL(string: "https://example.com/image.jpg")!,
            file: .init(type: .jpeg, size: 1000, mimeType: nil),
            originalWidth: 4000,
            originalHeight: 3000
        )
        let expectation = expectation(description: "Completion called")

        sut.loadImage(
            into: imageView,
            from: payload,
            maxResolutionInPixels: 1_000_000,
            cdnRequester: cdnRequester
        ) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
        XCTAssertNotNil(cdnRequester.lastImageRequestOptions?.resize)
    }

    @MainActor
    func test_loadImageFromAttachment_withoutDimensions_loadsWithoutResize() {
        let testImage = UIImage.make(withColor: .red)
        downloader.result = .success(DownloadedImage(image: testImage))
        let imageView = UIImageView()
        let payload = ImageAttachmentPayload(
            title: nil,
            imageRemoteURL: URL(string: "https://example.com/image.jpg")!,
            file: .init(type: .jpeg, size: 1000, mimeType: nil)
        )
        let expectation = expectation(description: "Completion called")

        sut.loadImage(
            into: imageView,
            from: payload,
            maxResolutionInPixels: 1_000_000,
            cdnRequester: cdnRequester
        ) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
        XCTAssertNil(cdnRequester.lastImageRequestOptions?.resize)
    }

    @MainActor
    func test_loadImageFromAttachment_nilPayload_setsPlaceholderNil() {
        let imageView = UIImageView()

        sut.loadImage(
            into: imageView,
            from: nil,
            maxResolutionInPixels: 1_000_000,
            cdnRequester: cdnRequester
        )

        XCTAssertNil(imageView.image)
    }

    // MARK: - ImageLoadingTask

    func test_imageLoadingTask_defaultIsNotCancelled() {
        let task = ImageLoadingTask()
        XCTAssertFalse(task.isCancelled)
    }

    func test_imageLoadingTask_cancelSetsFlag() {
        let task = ImageLoadingTask()
        task.cancel()
        XCTAssertTrue(task.isCancelled)
    }
}

// MARK: - Mocks

private final class MockCDNRequester: CDNRequester, @unchecked Sendable {
    var imageRequestResult: Result<CDNRequest, Error>?
    var fileRequestResult: Result<CDNRequest, Error>?
    var lastImageRequestOptions: ImageRequestOptions?

    func imageRequest(for url: URL, options: ImageRequestOptions, completion: @escaping (Result<CDNRequest, Error>) -> Void) {
        lastImageRequestOptions = options
        completion(imageRequestResult ?? .success(CDNRequest(url: url)))
    }

    func fileRequest(for url: URL, options: FileRequestOptions, completion: @escaping (Result<CDNRequest, Error>) -> Void) {
        completion(fileRequestResult ?? .success(CDNRequest(url: url)))
    }
}

private final class MockImageDownloader: ImageDownloading, @unchecked Sendable {
    var result: Result<DownloadedImage, Error> = .failure(NSError(domain: "MockImageDownloader", code: 0))
    var resultsByURL: [URL: Result<DownloadedImage, Error>] = [:]
    var completionDelay: TimeInterval = 0

    func downloadImage(
        url: URL,
        options: ImageDownloadingOptions,
        completion: @escaping @Sendable (Result<DownloadedImage, Error>) -> Void
    ) {
        let resolvedResult = resultsByURL[url] ?? result
        if completionDelay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + completionDelay) {
                completion(resolvedResult)
            }
        } else {
            DispatchQueue.main.async {
                completion(resolvedResult)
            }
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
