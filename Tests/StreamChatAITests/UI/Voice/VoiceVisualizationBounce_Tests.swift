//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class VoiceVisualizationBounce_Tests: XCTestCase {
    func test_scale_followsTheKeyframes() {
        XCTAssertEqual(VoiceVisualizationBounce.scale(at: 0), 1)
        XCTAssertEqual(VoiceVisualizationBounce.scale(at: 0.15), 0.965, accuracy: 1e-5)
        XCTAssertEqual(VoiceVisualizationBounce.scale(at: 0.3), 0.93, accuracy: 1e-5)
        XCTAssertEqual(VoiceVisualizationBounce.scale(at: 0.62), 1.03, accuracy: 1e-5)
        XCTAssertEqual(VoiceVisualizationBounce.scale(at: 1), 1, accuracy: 1e-5)
    }

    func test_easeOut_matchesCSS() {
        XCTAssertEqual(VoiceVisualizationBounce.easeOut(0), 0, accuracy: 1e-4)
        XCTAssertEqual(VoiceVisualizationBounce.easeOut(0.5), 0.684, accuracy: 2e-3)
        XCTAssertEqual(VoiceVisualizationBounce.easeOut(1), 1, accuracy: 1e-4)
    }

    func test_bounce_dipsOvershootsAndSettles() {
        var bounce = VoiceVisualizationBounce()
        XCTAssertEqual(bounce.scale, 1)

        bounce.start()
        var scales: [Float] = []
        for _ in 0..<21 {
            scales.append(bounce.scale)
            bounce.advance(by: 1 / 60)
        }

        XCTAssertEqual(scales.first, 1)
        XCTAssertEqual(scales.min() ?? 1, 0.93, accuracy: 0.01)
        XCTAssertEqual(scales.max() ?? 1, 1.03, accuracy: 0.01)
        XCTAssertLessThan(scales.firstIndex(of: scales.min() ?? 1) ?? 0, scales.firstIndex(of: scales.max() ?? 1) ?? 0)
        XCTAssertEqual(bounce.scale, 1)
    }
}
