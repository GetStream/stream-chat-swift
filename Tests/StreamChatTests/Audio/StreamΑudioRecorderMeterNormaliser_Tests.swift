//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

final class StreamΑudioRecorderMeterNormaliser_Tests: XCTestCase {
    private lazy var subject: AudioValuePercentageNormaliser! = AudioValuePercentageNormaliser()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init_minimumLevelThresholdIsCorrectlySet() {
        XCTAssertEqual(subject.valueRange.lowerBound, -50)
        XCTAssertEqual(subject.valueRange.upperBound, 0)
        XCTAssertEqual(subject.delta, 50)
    }

    // MARK: - normalise(_:)

    func test_normalise_valueIsBelowMinimumLevelThreshold_returnsExpectedValue() {
        XCTAssertEqual(subject.normalise(-70), 0)
    }

    func test_normalise_valueIsEqualToMinimumLevelThreshold_returnsExpectedValue() {
        XCTAssertEqual(subject.normalise(subject.valueRange.lowerBound), 0)
    }

    func test_normalise_valueIsAboveToMinimumLevelThreshold_returnsExpectedValue() {
        XCTAssertEqual(subject.normalise(-37.5), 0.25)
        XCTAssertEqual(subject.normalise(-25), 0.5)
        XCTAssertEqual(subject.normalise(-12.5), 0.75)
    }
}
