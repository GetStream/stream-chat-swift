//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import XCTest

final class AudioPlaybackState_Tests: XCTestCase {
    // MARK: - isEqual

    func test_isEqual_whenBothCasesAreTheSame_returnsTrue() {
        let state1 = AudioPlaybackState.playing
        let state2 = AudioPlaybackState.playing
        XCTAssertEqual(state1, state2)
    }

    func test_isEqual_whenCasesAreNotTheSame_returnsNotEqual() {
        let state1 = AudioPlaybackState.playing
        let state2 = AudioPlaybackState.paused
        XCTAssertNotEqual(state1, state2)
    }
}
