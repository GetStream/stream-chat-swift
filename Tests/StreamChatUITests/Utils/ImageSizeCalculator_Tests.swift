//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
import XCTest

final class ImageSizeCalculator_Tests: XCTestCase {
    func test_calculateSize_whenOriginalResolutionBiggerThanMax() {
        let calculator = ImageSizeCalculator()
        let size = calculator.calculateSize(
            originalWidthInPixels: 2000,
            originalHeightInPixels: 4000,
            maxResolutionTotalPixels: 1_000_000
        )

        let expectedSize = CGSize(
            width: 235,
            height: 471
        )

        XCTAssertEqual(size.width, expectedSize.width, accuracy: 1)
        XCTAssertEqual(size.height, expectedSize.height, accuracy: 1)
    }

    func test_calculateSize_whenOriginalResolutionBelowThanMax() {
        let calculator = ImageSizeCalculator()
        let size = calculator.calculateSize(
            originalWidthInPixels: 900,
            originalHeightInPixels: 1600,
            maxResolutionTotalPixels: 5_000_000
        )

        // It will be the original size in points
        let expectedSize = CGSize(
            width: 300,
            height: 533
        )

        XCTAssertEqual(size.width, expectedSize.width, accuracy: 1)
        XCTAssertEqual(size.height, expectedSize.height, accuracy: 1)
    }

    func test_calculateSize_whenOriginalResolutionEqualMax() {
        let calculator = ImageSizeCalculator()
        let size = calculator.calculateSize(
            originalWidthInPixels: 600,
            originalHeightInPixels: 600,
            maxResolutionTotalPixels: 360_000
        )

        // It will be the original size in points
        let expectedSize = CGSize(
            width: 200,
            height: 200
        )

        XCTAssertEqual(size.width, expectedSize.width, accuracy: 1)
        XCTAssertEqual(size.height, expectedSize.height, accuracy: 1)
    }
}
