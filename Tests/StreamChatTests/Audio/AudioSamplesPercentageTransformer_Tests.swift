//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import XCTest

final class AudioSamplesPercentageTransformer_Tests: XCTestCase {
    func testTransformEmptyArray() {
        // Given
        let transformer = AudioSamplesPercentageTransformer()

        // When
        let result = transformer.transform([])

        // Then
        XCTAssertEqual(result, [])
    }

    func testTransformSingleValueArray() {
        // Given
        let transformer = AudioSamplesPercentageTransformer()

        // When
        let result = transformer.transform([0.5])

        // Then
        XCTAssertEqual([1.0], result)
    }

    func testTransformPositiveValues() {
        // Given
        let transformer = AudioSamplesPercentageTransformer()
        let samples: [Float] = [0.2, 0.4, 0.6, 0.8, 1.0]

        // When
        let result = transformer
            .transform(samples)
            .map { ($0 * 100).rounded() / 100 }

        // Then
        XCTAssertEqual([0.0, 0.25, 0.5, 0.75, 1.0], result)
    }

    func testTransformNegativeValues() {
        // Given
        let transformer = AudioSamplesPercentageTransformer()
        let samples: [Float] = [-0.2, -0.4, -0.6, -0.8, -1.0]

        // When
        let result = transformer
            .transform(samples)
            .map { ($0 * 100).rounded() / 100 }

        // Then
        XCTAssertEqual([0.0, 0.25, 0.5, 0.75, 1.0], result)
    }

    func testTransformMixedValues() {
        // Given
        let transformer = AudioSamplesPercentageTransformer()
        let samples: [Float] = [-0.5, 0.2, -0.8, 0.6, -0.2, 0.8, -1.0, 1.0]

        // When
        let result = transformer
            .transform(samples)
            .map { ($0 * 100).rounded() / 100 }

        // Then
        XCTAssertEqual([0.38, 0.0, 0.75, 0.5, 0.0, 0.75, 1.0, 1.0], result)
    }
}
