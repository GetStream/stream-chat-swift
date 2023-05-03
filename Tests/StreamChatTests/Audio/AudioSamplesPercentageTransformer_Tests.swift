//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

final class AudioSamplesPercentageTransformer_Tests: XCTestCase {
    private let defaultAccuracy: Float = 0.001

    // MARK: - transform

    func test_transform_emptyArray() {
        let transformer = AudioSamplesPercentageTransformer()

        let result = transformer.transform([])

        assertSampleArrays([], result, accuracy: defaultAccuracy)
    }

    func test_transform_singleValueArray() {
        let transformer = AudioSamplesPercentageTransformer()

        let result = transformer.transform([0.5])

        assertSampleArrays([1.0], result, accuracy: defaultAccuracy)
    }

    func test_transform_positiveValues() {
        let transformer = AudioSamplesPercentageTransformer()
        let samples: [Float] = [0.2, 0.4, 0.6, 0.8, 1.0]

        let result = transformer.transform(samples)

        assertSampleArrays([0.0, 0.25, 0.5, 0.75, 1.0], result, accuracy: defaultAccuracy)
    }

    func test_transform_negativeValues() {
        let transformer = AudioSamplesPercentageTransformer()
        let samples: [Float] = [-0.2, -0.4, -0.6, -0.8, -1.0]

        let result = transformer.transform(samples)

        assertSampleArrays([0.0, 0.25, 0.5, 0.75, 1.0], result, accuracy: defaultAccuracy)
    }

    func test_transform_mixedValues() {
        let transformer = AudioSamplesPercentageTransformer()
        let samples: [Float] = [-0.5, 0.2, -0.8, 0.6, -0.2, 0.8, -1.0, 1.0]

        let result = transformer
            .transform(samples)
            .map { ($0 * 100).rounded() / 100 }

        assertSampleArrays([0.38, 0.0, 0.75, 0.5, 0.0, 0.75, 1.0, 1.0], result, accuracy: defaultAccuracy)
    }

    // MARK: - Private Helpers

    private func assertSampleArrays(
        _ expected: @autoclosure () -> [Float],
        _ actual: @autoclosure () -> [Float],
        accuracy: Float,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let actualArray = actual()
        let expectedArray = expected()
        guard expectedArray.count == actualArray.count else {
            XCTFail("Arrays have difference size", file: file, line: line)
            return
        }

        for (offset, actualElement) in actualArray.enumerated() {
            XCTAssertEqual(actualElement, expectedArray[offset], accuracy: accuracy, file: file, line: line)
        }
    }
}
