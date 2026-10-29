//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class DurationFormatting_Tests: XCTestCase {
    private let locale = Locale(identifier: "en_US")

    func test_minutesAndSeconds_usesNarrowUnits() {
        XCTAssertEqual(DurationFormatting.minutesAndSeconds(0, locale: locale), "0s")
        XCTAssertEqual(DurationFormatting.minutesAndSeconds(7, locale: locale), "7s")
        XCTAssertEqual(DurationFormatting.minutesAndSeconds(65, locale: locale), "1m 5s")
        XCTAssertEqual(DurationFormatting.minutesAndSeconds(600, locale: locale), "10m")
    }

    @MainActor
    func test_toolCallDuration_underASecond_showsTenths() {
        XCTAssertEqual(AIToolCallView.format(0.42), "0.4s")
    }

    @MainActor
    func test_toolCallDuration_fromASecond_roundsToWholeSeconds() {
        XCTAssertEqual(AIToolCallView.format(12.6), DurationFormatting.minutesAndSeconds(13))
        XCTAssertEqual(AIToolCallView.format(65), DurationFormatting.minutesAndSeconds(65))
    }
}
