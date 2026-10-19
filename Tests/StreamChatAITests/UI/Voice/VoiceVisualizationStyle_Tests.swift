//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class VoiceVisualizationStyle_Tests: XCTestCase {
    func test_glow_answersTapsOnTheGlobeOnly() {
        XCTAssertTrue(VoiceVisualizationStyle.glow.contains([0, 0]))
        XCTAssertTrue(VoiceVisualizationStyle.glow.contains([0.2, -0.2]))
        XCTAssertFalse(VoiceVisualizationStyle.glow.contains([0.3, 0.3]))
        XCTAssertFalse(VoiceVisualizationStyle.glow.contains([0, 0.45]))
    }

    func test_wave_answersTapsOnTheLineBandOnly() {
        XCTAssertTrue(VoiceVisualizationStyle.wave.contains([0, 0]))
        XCTAssertTrue(VoiceVisualizationStyle.wave.contains([-0.45, 0.1]))
        XCTAssertFalse(VoiceVisualizationStyle.wave.contains([0, 0.2]))
        XCTAssertFalse(VoiceVisualizationStyle.wave.contains([0.55, 0]))
    }
}
