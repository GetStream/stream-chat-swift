//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
import XCTest

final class DefaultAudioPlaybackRateFormatter_Tests: XCTestCase {
    private lazy var subject: DefaultAudioPlaybackRateFormatter! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - format(_:)

    func test_format_valueWithoutDecimals_returnsExpectedResult() {
        let value: Float = 5.0
        let expected = "5"

        let actual = subject.format(value)

        XCTAssertEqual(expected, actual)
    }

    func test_format_valueWithDecimals_returnsExpectedResult() {
        let value: Float = 5.4567
        let expected = "5.46"

        let actual = subject.format(value)

        XCTAssertEqual(expected, actual)
    }
}
