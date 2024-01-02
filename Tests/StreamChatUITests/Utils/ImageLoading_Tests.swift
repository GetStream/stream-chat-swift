//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatUI
import XCTest

final class ImageLoading_Tests: XCTestCase {
    var sut: ImageLoading!
    var spy: ImageLoaderSpy!

    override func setUp() {
        super.setUp()
        spy = ImageLoaderSpy()
        sut = spy
    }

    override func tearDown() {
        sut = nil
        spy = nil
        super.tearDown()
    }

    func test_loadImageIntoWithOptions_isCalled() {
        sut.loadImage(into: .init(image: nil), from: nil, with: .init(), completion: nil)

        XCTAssertEqual(spy.loadImageIntoWithOptionsCallCount, 1)
    }

    func test_loadImageIntoWithOptions_whenDefaultArgumentsUsed_isCalled() {
        sut.loadImage(into: .init(image: nil), from: nil, with: .init(), completion: nil)
        sut.loadImage(into: .init(image: nil), from: nil, with: .init())

        XCTAssertEqual(spy.loadImageIntoWithOptionsCallCount, 2)
    }

    func test_downloadImage_isCalled() {
        sut.downloadImage(with: .init(url: .localYodaImage, options: .init()), completion: { _ in })

        XCTAssertEqual(spy.downloadImageCallCount, 1)
    }

    func test_downloadMultipleImages_isCalled() {
        sut.downloadMultipleImages(with: [.init(url: .localYodaImage, options: .init())], completion: { _ in })

        XCTAssertEqual(spy.downloadMultipleImagesCallCount, 1)
    }

    class ImageLoaderSpy: ImageLoading {
        var loadImageIntoWithOptionsCallCount = 0
        var loadImageIntoWithAttachmentPayloadCallCount = 0
        var downloadImageCallCount = 0
        var downloadMultipleImagesCallCount = 0

        @discardableResult
        func loadImage(
            into imageView: UIImageView,
            from url: URL?,
            with options: ImageLoaderOptions,
            completion: ((_ result: Result<UIImage, Error>) -> Void)?
        ) -> Cancellable? {
            loadImageIntoWithOptionsCallCount += 1
            return nil
        }

        @discardableResult
        func loadImage(
            into imageView: UIImageView,
            from attachmentPayload: ImageAttachmentPayload?,
            maxResolutionInPixels: Double,
            completion: ((_ result: Result<UIImage, Error>) -> Void)?
        ) -> Cancellable? {
            loadImageIntoWithAttachmentPayloadCallCount += 1
            return nil
        }

        @discardableResult
        func downloadImage(
            with request: ImageDownloadRequest,
            completion: @escaping ((_ result: Result<UIImage, Error>) -> Void)
        ) -> Cancellable? {
            downloadImageCallCount += 1
            return nil
        }

        func downloadMultipleImages(
            with requests: [ImageDownloadRequest],
            completion: @escaping (([Result<UIImage, Error>]) -> Void)
        ) {
            downloadMultipleImagesCallCount += 1
        }
    }
}
