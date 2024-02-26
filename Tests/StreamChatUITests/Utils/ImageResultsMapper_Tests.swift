//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
import XCTest

@available(iOS 13.0, *)
final class ImageResultsMapper_Tests: XCTestCase {
    lazy var fakePlaceholderImage1 = UIImage(systemName: "square.and.arrow.up.circle")!
    lazy var fakePlaceholderImage2 = UIImage(systemName: "square.and.arrow.up.circle.fill")!
    lazy var fakePlaceholderImage3 = UIImage(systemName: "square.and.arrow.down.fill")!
    lazy var fakePlaceholderImage4 = UIImage(systemName: "square.and.arrow.down")!

    struct MockError: Error {}

    func test_mapErrorsWithPlaceholders_whenWithoutErrors() {
        let results: [Result<UIImage, Error>] = [
            .success(TestImages.chewbacca.image),
            .success(TestImages.r2.image),
            .success(TestImages.vader.image),
            .success(TestImages.yoda.image)
        ]

        let mapper = ImageResultsMapper(results: results)
        let images = mapper.mapErrors(with: [fakePlaceholderImage1])

        XCTAssertEqual(images, [
            TestImages.chewbacca.image,
            TestImages.r2.image,
            TestImages.vader.image,
            TestImages.yoda.image
        ])
    }

    func test_mapErrorsWithPlaceholders_whenThereIs1Errors() {
        let results: [Result<UIImage, Error>] = [
            .success(TestImages.chewbacca.image),
            .success(TestImages.r2.image),
            .failure(MockError()),
            .success(TestImages.yoda.image)
        ]

        let mapper = ImageResultsMapper(results: results)
        let images = mapper.mapErrors(with: [
            fakePlaceholderImage1,
            fakePlaceholderImage2,
            fakePlaceholderImage3,
            fakePlaceholderImage4
        ])

        XCTAssertEqual(images, [
            TestImages.chewbacca.image,
            TestImages.r2.image,
            fakePlaceholderImage1,
            TestImages.yoda.image
        ])
    }

    func test_mapErrorsWithPlaceholders_whenThereIs2Errors() {
        let results: [Result<UIImage, Error>] = [
            .success(TestImages.chewbacca.image),
            .failure(MockError()),
            .failure(MockError()),
            .success(TestImages.yoda.image)
        ]

        let mapper = ImageResultsMapper(results: results)
        let images = mapper.mapErrors(with: [
            fakePlaceholderImage1,
            fakePlaceholderImage2,
            fakePlaceholderImage3,
            fakePlaceholderImage4
        ])

        XCTAssertEqual(images, [
            TestImages.chewbacca.image,
            fakePlaceholderImage1,
            fakePlaceholderImage2,
            TestImages.yoda.image
        ])
    }

    func test_mapErrorsWithPlaceholders_whenThereIs3Errors() {
        let results: [Result<UIImage, Error>] = [
            .failure(MockError()),
            .success(TestImages.r2.image),
            .failure(MockError()),
            .failure(MockError())
        ]

        let mapper = ImageResultsMapper(results: results)
        let images = mapper.mapErrors(with: [
            fakePlaceholderImage1,
            fakePlaceholderImage2,
            fakePlaceholderImage3,
            fakePlaceholderImage4
        ])

        XCTAssertEqual(images, [
            fakePlaceholderImage1,
            TestImages.r2.image,
            fakePlaceholderImage2,
            fakePlaceholderImage3
        ])
    }

    func test_mapErrorsWithPlaceholders_whenThereIs4Errors() {
        let results: [Result<UIImage, Error>] = [
            .failure(MockError()),
            .failure(MockError()),
            .failure(MockError()),
            .failure(MockError())
        ]

        let mapper = ImageResultsMapper(results: results)
        let images = mapper.mapErrors(with: [
            fakePlaceholderImage1,
            fakePlaceholderImage2,
            fakePlaceholderImage3,
            fakePlaceholderImage4
        ])

        XCTAssertEqual(images, [
            fakePlaceholderImage1,
            fakePlaceholderImage2,
            fakePlaceholderImage3,
            fakePlaceholderImage4
        ])
    }
    
    func test_mapErrorsWithPlaceholders_when2ErrorsBut1Placeholder_then1FailingResultIsDropped() {
        let results: [Result<UIImage, Error>] = [
            .success(TestImages.chewbacca.image),
            .failure(MockError()),
            .failure(MockError()),
            .success(TestImages.yoda.image)
        ]

        let mapper = ImageResultsMapper(results: results)
        let images = mapper.mapErrors(with: [
            fakePlaceholderImage1
        ])

        XCTAssertEqual(images, [
            TestImages.chewbacca.image,
            fakePlaceholderImage1,
            TestImages.yoda.image
        ])
    }
}
