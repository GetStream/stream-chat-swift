//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class VoiceVisualizationDriver_Tests: XCTestCase {
    private let blue = SIMD3<Float>(218 / 360, 1, 1)
    private let frame: TimeInterval = 1 / 60

    func test_init_settlesOnTheState() {
        let uniforms = uniforms(of: VoiceVisualizationDriver(input: input(.speaking)))

        XCTAssertEqual(uniforms.react, 1)
        XCTAssertEqual(uniforms.load, 0)
        XCTAssertEqual(uniforms.flow, 0)
        XCTAssertEqual(uniforms.bright, 1)
        XCTAssertEqual(uniforms.time, 0)
        XCTAssertEqual(uniforms.count, 1)
        XCTAssertEqual(uniforms.scale, 1)
        XCTAssertEqual(uniforms.tapTime, 100)
        XCTAssertEqual(uniforms.col0, SIMD4(blue, 0))
        XCTAssertEqual(uniforms.col4, SIMD4(blue, 0))
    }

    func test_changingState_easesTowardItsMotion() {
        var driver = VoiceVisualizationDriver(input: input(.idle))

        driver.input.state = .connecting
        driver.advance(by: frame)
        XCTAssertEqual(uniforms(of: driver).load, 0.08, accuracy: 1e-4)

        advance(&driver, for: 2)
        XCTAssertEqual(uniforms(of: driver).load, 1, accuracy: 1e-3)
        XCTAssertEqual(uniforms(of: driver).react, 0, accuracy: 1e-3)
    }

    func test_easing_doesNotDependOnTheFrameRate() {
        var at60 = VoiceVisualizationDriver(input: input(.idle))
        var at120 = VoiceVisualizationDriver(input: input(.idle))
        at60.input.state = .speaking
        at120.input.state = .speaking

        for _ in 0..<30 { at60.advance(by: 1 / 60) }
        for _ in 0..<60 { at120.advance(by: 1 / 120) }

        XCTAssertEqual(uniforms(of: at60).react, uniforms(of: at120).react, accuracy: 1e-4)
        XCTAssertEqual(uniforms(of: at60).time, uniforms(of: at120).time, accuracy: 1e-2)
    }

    func test_advance_clampsLongFrames() {
        var driver = VoiceVisualizationDriver(input: input(.idle))

        driver.advance(by: 5)

        XCTAssertEqual(driver.time, 0.05 * 0.4, accuracy: 1e-5)
    }

    func test_flowSpin_runsOnlyWhileThinking() {
        var driver = VoiceVisualizationDriver(input: input(.speaking))
        advance(&driver, for: 1)
        XCTAssertEqual(driver.flowSpin, 0)

        driver.input.state = .thinking
        advance(&driver, for: 1)
        XCTAssertGreaterThan(driver.flowSpin, 0)
    }

    func test_orbSpin_keepsTurningInEveryState() {
        var driver = VoiceVisualizationDriver(input: input(.idle))

        advance(&driver, for: 1)

        XCTAssertGreaterThan(driver.orbSpin, 0)
    }

    func test_expressivity_scalesAmplitudeAndSpeed() {
        var lively = VoiceVisualizationDriver(input: input(.speaking, expressivity: 2))
        let still = VoiceVisualizationDriver(input: input(.speaking, expressivity: 0))

        XCTAssertEqual(uniforms(of: lively).react, 1.85, accuracy: 1e-5)
        XCTAssertEqual(uniforms(of: still).react, 0.15, accuracy: 1e-5)

        lively.advance(by: 0.05)
        XCTAssertEqual(lively.time, 0.05 * 1.25 * 1.4, accuracy: 1e-5)
    }

    func test_reduceMotion_slowsTimeAndIgnoresPointers() {
        var driver = VoiceVisualizationDriver(input: input(.idle, reduceMotion: true))

        driver.tap(at: [0.1, 0.1])
        driver.hover(at: [0.1, 0.1])
        driver.advance(by: 0.05)

        XCTAssertEqual(driver.time, 0.05 * 0.07 * 0.4, accuracy: 1e-6)
        XCTAssertGreaterThan(uniforms(of: driver).tapTime, 100)
        XCTAssertEqual(uniforms(of: driver).scale, 1)
        XCTAssertEqual(uniforms(of: driver).hoverAmt, 0)
    }

    func test_tap_ripplesFromThePointAndBounces() {
        var driver = VoiceVisualizationDriver(input: input(.idle))

        driver.tap(at: [0.1, -0.2])
        XCTAssertEqual(uniforms(of: driver).tap, [0.1, -0.2])
        XCTAssertEqual(uniforms(of: driver).tapTime, 0)

        driver.advance(by: 0.05)
        XCTAssertEqual(uniforms(of: driver).tapTime, 0.05, accuracy: 1e-6)
        XCTAssertLessThan(uniforms(of: driver).scale, 1)

        advance(&driver, for: 0.5)
        XCTAssertEqual(uniforms(of: driver).scale, 1)
    }

    func test_hover_easesInAndOut() {
        var driver = VoiceVisualizationDriver(input: input(.idle))

        driver.hover(at: [0.2, 0.1])
        advance(&driver, for: 1)
        XCTAssertEqual(uniforms(of: driver).hoverAmt, 1, accuracy: 1e-3)
        XCTAssertEqual(uniforms(of: driver).hover, [0.2, 0.1])

        driver.hover(at: nil)
        advance(&driver, for: 1)
        XCTAssertEqual(uniforms(of: driver).hoverAmt, 0, accuracy: 1e-3)
        XCTAssertEqual(uniforms(of: driver).hover, [0.2, 0.1])
    }

    func test_audioLevel_liftsTheMotionToItsLevel() {
        var driver = VoiceVisualizationDriver(input: input(.idle, audioLevel: 0.8))

        advance(&driver, for: 2)
        XCTAssertEqual(uniforms(of: driver).mic, 0.8, accuracy: 1e-3)
        XCTAssertEqual(uniforms(of: driver).voice, 1, accuracy: 1e-3)
        XCTAssertEqual(uniforms(of: driver).react, 0.8, accuracy: 1e-3)

        driver.input.audioLevel = nil
        advance(&driver, for: 2)
        XCTAssertEqual(uniforms(of: driver).voice, 0, accuracy: 1e-3)
        XCTAssertEqual(uniforms(of: driver).react, 0.12, accuracy: 1e-3)
    }

    func test_audioLevel_catchesUpWithALouderLevelWithinAWord() {
        var driver = VoiceVisualizationDriver(input: input(.idle, audioLevel: 0))
        advance(&driver, for: 1)

        driver.input.audioLevel = 1
        advance(&driver, for: 0.1)
        XCTAssertTrue((0.5...0.8).contains(uniforms(of: driver).mic), "mic was \(uniforms(of: driver).mic)")
        advance(&driver, for: 0.3)
        XCTAssertGreaterThan(uniforms(of: driver).mic, 0.95)
    }

    func test_audioLevel_fallsAwayOverAPauseNotASyllable() {
        var driver = VoiceVisualizationDriver(input: input(.idle, audioLevel: 1))
        advance(&driver, for: 1)

        driver.input.audioLevel = 0
        advance(&driver, for: 0.1)
        XCTAssertGreaterThan(uniforms(of: driver).mic, 0.7)
        advance(&driver, for: 0.9)
        XCTAssertLessThan(uniforms(of: driver).mic, 0.1)
    }

    func test_colors_easeTheirHueTheShortWayRound() {
        var driver = VoiceVisualizationDriver(input: input(.idle, colors: [[0.95, 1, 1]]))

        driver.input.colors = [[0.05, 1, 1]]
        driver.advance(by: frame)
        XCTAssertEqual(uniforms(of: driver).col0.x, 0.962, accuracy: 1e-4)

        advance(&driver, for: 2)
        XCTAssertEqual(uniforms(of: driver).col0.x, 0.05, accuracy: 1e-3)
    }

    func test_colors_fillTheEmptySlotsWithTheFirstAndCrossfadeTheCount() {
        let red = SIMD3<Float>(0, 1, 1)
        var driver = VoiceVisualizationDriver(input: input(.idle, colors: [blue, red]))
        XCTAssertEqual(uniforms(of: driver).col1, SIMD4(red, 0))
        XCTAssertEqual(uniforms(of: driver).col2, SIMD4(blue, 0))

        driver.input.colors = [blue, red, red]
        driver.advance(by: frame)
        XCTAssertEqual(uniforms(of: driver).count, 2.12, accuracy: 1e-4)
    }

    func test_ease_movesTheReferenceShareOfTheWayAt60Hz() {
        XCTAssertEqual(VoiceVisualizationDriver.ease(0.08, over: 1 / 60), 0.08, accuracy: 1e-5)
        XCTAssertEqual(VoiceVisualizationDriver.ease(0.08, over: 0), 0)
    }

    // MARK: - Helpers

    private func input(
        _ state: AIVoiceAgentState,
        colors: [SIMD3<Float>]? = nil,
        expressivity: Float = 1,
        audioLevel: Float? = nil,
        reduceMotion: Bool = false
    ) -> VoiceVisualizationDriver.Input {
        VoiceVisualizationDriver.Input(
            state: state,
            colors: colors ?? [blue],
            expressivity: expressivity,
            audioLevel: audioLevel,
            reduceMotion: reduceMotion
        )
    }

    private func uniforms(of driver: VoiceVisualizationDriver) -> VoiceVisualizationUniforms {
        driver.uniforms(resolution: [100, 100], dark: false)
    }

    private func advance(_ driver: inout VoiceVisualizationDriver, for seconds: TimeInterval) {
        for _ in 0..<Int(seconds / frame) {
            driver.advance(by: frame)
        }
    }
}
