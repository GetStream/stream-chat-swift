//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreGraphics
import simd

enum VoiceVisualizationStyle: CaseIterable, Hashable, Sendable {
    case glow
    case wave

    // The wave's height tracks the level directly, so it follows it smoothly; per-syllable jumps
    // would make it jitter. The glow follows it closely.
    var levelResponse: VoiceVisualizationDriver.LevelResponse {
        switch self {
        case .glow: .steady
        case .wave: .smooth
        }
    }

    var fragmentFunction: String {
        switch self {
        case .glow: "voiceGlowFragment"
        case .wave: "voiceWaveFragment"
        }
    }

    // The densest the shader renders. The glow is soft all over, so it stays at 2x as on the
    // web; the wave's thin line is drawn at the screen's own scale to stay crisp.
    var maximumScale: CGFloat {
        switch self {
        case .glow: 2
        case .wave: 3
        }
    }

    // Whether a point, centred and normalized to the shorter side with y up, is on the shape
    // rather than the empty space around it.
    func contains(_ point: SIMD2<Float>) -> Bool {
        switch self {
        case .glow:
            simd_length(point) < 0.32
        case .wave:
            abs(point.x) < 0.5 && abs(point.y) < 0.14
        }
    }
}
