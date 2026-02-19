//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatCommonUI
import XCTest

final class DefaultMediaBadgeDurationFormatter_Tests: XCTestCase {
    private lazy var subject: DefaultMediaBadgeDurationFormatter! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - longFormat(_:)

    func test_longFormat_zeroDuration_returnsZeroMinutesAndSeconds() {
        XCTAssertEqual(subject.longFormat(0), "0:00")
    }

    func test_longFormat_singleDigitSeconds_returnsPaddedSeconds() {
        XCTAssertEqual(subject.longFormat(8), "0:08")
    }

    func test_longFormat_doubleDigitSeconds_returnsExpectedResult() {
        XCTAssertEqual(subject.longFormat(45), "0:45")
    }

    func test_longFormat_exactlyOneMinute_returnsExpectedResult() {
        XCTAssertEqual(subject.longFormat(60), "1:00")
    }

    func test_longFormat_minutesAndSeconds_returnsExpectedResult() {
        XCTAssertEqual(subject.longFormat(83), "1:23")
    }

    func test_longFormat_doubleDigitMinutes_returnsPaddedSeconds() {
        XCTAssertEqual(subject.longFormat(725), "12:05")
    }

    func test_longFormat_fractionalSeconds_truncatesToInteger() {
        XCTAssertEqual(subject.longFormat(8.9), "0:08")
    }

    func test_longFormat_largeValue_returnsExpectedResult() {
        XCTAssertEqual(subject.longFormat(3661), "61:01")
    }

    // MARK: - shortFormat(_:)

    func test_shortFormat_zeroDuration_returnsZeroSeconds() {
        XCTAssertEqual(subject.shortFormat(0), "0s")
    }

    func test_shortFormat_underOneMinute_returnsSeconds() {
        XCTAssertEqual(subject.shortFormat(8), "8s")
    }

    func test_shortFormat_fiftyNineSeconds_returnsSeconds() {
        XCTAssertEqual(subject.shortFormat(59), "59s")
    }

    func test_shortFormat_exactlyOneMinute_returnsOneMinute() {
        XCTAssertEqual(subject.shortFormat(60), "1m")
    }

    func test_shortFormat_multipleMinutes_returnsMinutes() {
        XCTAssertEqual(subject.shortFormat(600), "10m")
    }

    func test_shortFormat_justUnderOneHour_returnsMinutes() {
        XCTAssertEqual(subject.shortFormat(3599), "59m")
    }

    func test_shortFormat_exactlyOneHour_returnsOneHour() {
        XCTAssertEqual(subject.shortFormat(3600), "1h")
    }

    func test_shortFormat_multipleHours_returnsHours() {
        XCTAssertEqual(subject.shortFormat(7200), "2h")
    }

    func test_shortFormat_fractionalSeconds_truncatesToInteger() {
        XCTAssertEqual(subject.shortFormat(59.9), "59s")
    }

    func test_shortFormat_minutesPlusFractionalSeconds_returnsMinutes() {
        XCTAssertEqual(subject.shortFormat(119.5), "1m")
    }
}
