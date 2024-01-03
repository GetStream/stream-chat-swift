//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import XCTest

final class AudioPlaybackRate_Tests: XCTestCase {
    // MARK: - init

    func test_initWithRawValue_returnsExpectedValues() {
        XCTAssertEqual(AudioPlaybackRate(rawValue: 0), .zero)
        XCTAssertEqual(AudioPlaybackRate(rawValue: 0.5), .half)
        XCTAssertEqual(AudioPlaybackRate(rawValue: 1), .normal)
        XCTAssertEqual(AudioPlaybackRate(rawValue: 2), .double)
    }
}
