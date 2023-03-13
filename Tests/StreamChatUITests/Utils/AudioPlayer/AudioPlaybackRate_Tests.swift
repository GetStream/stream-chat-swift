//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatUI
import XCTest

final class AudioPlaybackRate_Tests: XCTestCase {
    // MARK: - init

    func test_initWithRawValue_returnsExpectedValues() {
        XCTAssertEqual(AudioPlaybackRate(rawValue: 0), .zero)
        XCTAssertEqual(AudioPlaybackRate(rawValue: 0.5), .half)
        XCTAssertEqual(AudioPlaybackRate(rawValue: 1), .normal)
        XCTAssertEqual(AudioPlaybackRate(rawValue: 2), .double)
        XCTAssertEqual(AudioPlaybackRate(rawValue: 3), .normal)
    }

    // MARK: - description

    func test_description_returnsExpectedValues() {
        XCTAssertEqual(AudioPlaybackRate.zero.description, "x0")
        XCTAssertEqual(AudioPlaybackRate.half.description, "x0.5")
        XCTAssertEqual(AudioPlaybackRate.normal.description, "x1")
        XCTAssertEqual(AudioPlaybackRate.double.description, "x2")
    }

    // MARK: - next

    func test_next_returnsExpectedValues() {
        XCTAssertEqual(AudioPlaybackRate.zero.next, .half)
        XCTAssertEqual(AudioPlaybackRate.half.next, .normal)
        XCTAssertEqual(AudioPlaybackRate.normal.next, .double)
        XCTAssertEqual(AudioPlaybackRate.double.next, .half)
    }
}
