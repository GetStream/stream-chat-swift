//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

final class ArraySampling_Tests: XCTestCase {
    // MARK: - downsample(to:)

    func test_downsample_resultingSizeWillBeHalf_returnsExpectedResult() {
        let input: [Float] = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
        let expected: [Float] = [1.5, 3.5, 5.5, 7.5, 9.5]

        let downsampled = input.downsample(to: 5)

        downsampled
            .enumerated()
            .forEach { XCTAssertEqual(expected[$0.offset], $0.element, accuracy: 0.001) }
    }

    func test_downsample_resultingSizeWillBeOneThird_returnsExpectedResult() {
        let input: [Float] = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
        let expected: [Float] = [1.8, 4.5, 7.2]

        let downsampled = input.downsample(to: 3)

        downsampled
            .enumerated()
            .forEach { XCTAssertEqual(expected[$0.offset], $0.element, accuracy: 0.001) }
    }

    func test_downsample_resultingSizeWillBeSameAsInput_returnsExpectedResult() {
        let input: [Float] = [1.0, 2.0, 3.0, 4.0, 5.0]

        let downsample = input.downsample(to: input.count)

        XCTAssertEqual(input, downsample)
    }

    func test_downsample_inputSizeIsZero_returnsExpectedResult() {
        let input: [Float] = []

        let downsample = input.downsample(to: 5)

        XCTAssertTrue(downsample.isEmpty)
    }

    func test_downsample_resultingSizeWillBeZero_returnsExpectedResult() {
        let input: [Float] = [1.0, 2.0, 3.0, 4.0, 5.0]

        let downsample = input.downsample(to: 0)

        XCTAssertEqual(downsample, input)
    }

    // MARK: - upsample(to:)

    func test_upsample_resultingSizeWillBeDoubleTheInput_returnsExpectedResult() {
        let input: [Float] = [1.0, 2.0, 3.0, 4.0, 5.0]
        let expected: [Float] = [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.0]

        let upsampled = input.upsample(to: 10)

        print(upsampled)
        upsampled
            .enumerated()
            .forEach { XCTAssertEqual(expected[$0.offset], $0.element, accuracy: 0.001) }
    }

    func test_upsample_resultingSizeWillBeTheSameAsInput_returnsExpectedResult() {
        let input: [Float] = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]

        let upsampled = input.upsample(to: 10)

        XCTAssertEqual(input, upsampled)
    }

    func test_upsample_inputSizeWillBeDoubleZero_returnsExpectedResult() {
        let input: [Float] = []

        let upsampled = input.upsample(to: 5)

        XCTAssertTrue(upsampled.isEmpty)
    }

    func test_upsample_resultingSizeWillBeZero_returnsExpectedResult() {
        let input: [Float] = [1.0, 2.0, 3.0, 4.0, 5.0]

        let upsampled = input.upsample(to: 0)

        XCTAssertEqual(input, upsampled)
    }
}
