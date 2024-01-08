//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

final class AudioSamplesPercentageNormaliser_Tests: XCTestCase {
    private let defaultAccuracy: Float = 0.01

    private lazy var subject: AudioValuePercentageNormaliser! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - normalise

    func test_normalise_emptyArray() {
        let result = subject.normalise([])

        assertSampleArrays([], result, accuracy: defaultAccuracy)
    }

    func test_normalise_singleValueArray() {
        let transformer = AudioValuePercentageNormaliser()

        let result = transformer.normalise([-25])

        assertSampleArrays([0.5], result, accuracy: defaultAccuracy)
    }

    func test_normalise_returnsExpectedResult() {
        let samples: [Float] = [-40, -30, -20, -10, 0]

        let result = subject.normalise(samples)

        assertSampleArrays([0.2, 0.4, 0.6, 0.8, 1.0], result, accuracy: defaultAccuracy)
    }

    func test_normalise_manyValues_returnsExpectedResult() {
        let samples: [Float] = [
            -50, -50, -50, -50, -50, -50, -50, -50, -50, -50,
            -15, -20, -25, -30, -35, -40, -45, -50, -50, -50,
            -50, -50, -50, -50, -50, -50, -50, -50, -50, -50,
            -30, -35, -40, -45, -50, -50, -50, -50, -50, -50
        ]

        let result = subject.normalise(samples)

        assertSampleArrays([
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0.4, 0.3, 0.2, 0.1, 0, 0, 0, 0, 0, 0
        ], result, accuracy: defaultAccuracy)
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
