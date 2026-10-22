//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import simd

// The web reference eases each value by a fixed fraction per frame, which settles twice as
// fast at 120 Hz as at 60 Hz. Here each fraction is converted to time, so the motion is the
// reference's at 60 Hz on any display.
struct VoiceVisualizationDriver {
    struct Input: Equatable {
        var state: AIVoiceAgentState
        // One to five colors as HSV, hue a fraction of a turn.
        var colors: [SIMD3<Float>]
        // From 0 to 2.
        var expressivity: Float
        // From 0 to 1, or nil when no live audio drives the motion.
        var audioLevel: Float?
        var reduceMotion: Bool
    }

    // The share of the way `micLevel` moves each frame at 60 Hz, toward a louder or a quieter
    // level.
    struct LevelResponse: Equatable {
        var rise: Float
        var fall: Float

        // Follows the level closely, both ways.
        static let steady = LevelResponse(rise: 0.35, fall: 0.35)
        // Follows the level like a VU meter: about 0.1 s up to a louder reading, about 0.3 s down
        // from it, so a meter's per-syllable jumps swell with the phrase instead.
        static let smooth = LevelResponse(rise: 0.16, fall: 0.05)
    }

    var input: Input {
        didSet {
            if input.reduceMotion { isHovering = false }
        }
    }

    private var speed: Float
    private var bright: Float
    private var sat: Float
    private var load: Float
    private var flow: Float
    private var react: Float
    private var expressivity: Float
    private(set) var time: Float = 0
    private(set) var flowSpin: Float = 0
    private(set) var orbSpin: Float = 0
    private var colors: [SIMD3<Float>]
    private var count: Float
    private var tapPoint: SIMD2<Float> = .zero
    private var tapAge: Float = 100
    private var hoverPoint: SIMD2<Float> = .zero
    private var isHovering = false
    private var hoverAmount: Float = 0
    private var micLevel: Float = 0
    private var voiceAmount: Float = 0
    private var bounce = VoiceVisualizationBounce()

    private let levelResponse: LevelResponse

    // Starts settled on the input, so the first frame shows it rather than easing into it.
    init(input: Input, levelResponse: LevelResponse = .steady) {
        self.input = input
        self.levelResponse = levelResponse
        let motion = input.state.motion
        let scales = Self.scales(for: input.expressivity)
        speed = motion.speed * scales.speed
        bright = motion.bright
        sat = motion.sat
        load = motion.load * scales.amplitude
        flow = motion.flow * scales.amplitude
        react = motion.react * scales.amplitude
        expressivity = input.expressivity
        colors = Self.slots(for: input.colors)
        count = Float(input.colors.count)
    }

    mutating func tap(at point: SIMD2<Float>) {
        guard !input.reduceMotion else { return }
        tapPoint = point
        tapAge = 0
        bounce.start()
    }

    mutating func hover(at point: SIMD2<Float>?) {
        guard let point, !input.reduceMotion else {
            isHovering = false
            return
        }
        hoverPoint = point
        isHovering = true
    }

    mutating func advance(by seconds: TimeInterval) {
        // Clamped so a frame after a stall cannot leap the motion.
        let dt = Float(min(max(seconds, 0), 0.05))
        let motion = input.state.motion
        let scales = Self.scales(for: input.expressivity)
        let drivers = Self.ease(0.08, over: dt)
        speed += (motion.speed * scales.speed - speed) * drivers
        bright += (motion.bright - bright) * drivers
        sat += (motion.sat - sat) * drivers
        load += (motion.load * scales.amplitude - load) * drivers
        flow += (motion.flow * scales.amplitude - flow) * drivers
        react += (motion.react * scales.amplitude - react) * drivers
        expressivity += (input.expressivity - expressivity) * drivers

        // Integrated rather than computed as time times a weight, so a change of state eases
        // the turns instead of jumping their angles.
        let step = dt * (input.reduceMotion ? 0.07 : 1) * speed
        time += step
        flowSpin += step * flow
        orbSpin += step * (1 + 0.5 * flow + 0.1 * react)

        tapAge += dt
        bounce.advance(by: dt)

        let gentle = Self.ease(0.12, over: dt)
        hoverAmount += ((isHovering ? 1 : 0) - hoverAmount) * gentle
        voiceAmount += ((input.audioLevel == nil ? 0 : 1) - voiceAmount) * Self.ease(0.1, over: dt)
        let level = input.audioLevel ?? 0
        let response = level > micLevel ? levelResponse.rise : levelResponse.fall
        micLevel += (level - micLevel) * Self.ease(response, over: dt)

        let targets = Self.slots(for: input.colors)
        for index in colors.indices {
            colors[index] = Self.ease(colors[index], toward: targets[index], by: gentle)
        }
        count += (Float(input.colors.count) - count) * gentle
    }

    func uniforms(resolution: SIMD2<Float>, dark: Bool) -> VoiceVisualizationUniforms {
        VoiceVisualizationUniforms(
            col0: SIMD4(colors[0], 0),
            col1: SIMD4(colors[1], 0),
            col2: SIMD4(colors[2], 0),
            col3: SIMD4(colors[3], 0),
            col4: SIMD4(colors[4], 0),
            resolution: resolution,
            tap: tapPoint,
            hover: hoverPoint,
            time: time,
            count: count,
            bright: bright,
            sat: sat,
            load: load,
            flow: flow,
            flowSpin: flowSpin,
            orbSpin: orbSpin,
            // Live audio lifts the motion to its level, whatever the state.
            react: react + (max(react, micLevel) - react) * voiceAmount,
            expressivity: expressivity,
            dark: dark ? 1 : 0,
            tapTime: tapAge,
            hoverAmt: hoverAmount,
            mic: micLevel,
            voice: voiceAmount,
            scale: bounce.scale
        )
    }

    // Expressivity scales amplitude and speed, each with a floor so the motion still breathes
    // at 0.
    static func scales(for expressivity: Float) -> (amplitude: Float, speed: Float) {
        (0.15 + 0.85 * expressivity, 0.6 + 0.4 * expressivity)
    }

    // The share of the way to its target a value moves in `dt`, for a value that moves
    // `perFrame` of the way each frame at 60 Hz.
    static func ease(_ perFrame: Float, over dt: Float) -> Float {
        1 - pow(1 - perFrame, dt * 60)
    }

    // Eases an HSV color, its hue taking the shorter way round the wheel.
    static func ease(_ color: SIMD3<Float>, toward target: SIMD3<Float>, by fraction: Float) -> SIMD3<Float> {
        let hueStep = ((target.x - color.x + 1.5).truncatingRemainder(dividingBy: 1) - 0.5) * fraction
        return SIMD3(
            (color.x + hueStep + 1).truncatingRemainder(dividingBy: 1),
            color.y + (target.y - color.y) * fraction,
            color.z + (target.z - color.z) * fraction
        )
    }

    // The five color slots the shaders read; past the palette they repeat its first color.
    static func slots(for colors: [SIMD3<Float>]) -> [SIMD3<Float>] {
        let first = colors.first ?? SIMD3(0, 0, 0)
        return (0..<VoiceVisualizationPalette.maximumCount).map { index in
            index < colors.count ? colors[index] : first
        }
    }
}
