//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import simd

// The layout matches `VoiceUniforms` in `VoiceVisualizationShaders.source` field for field, so
// keep the two in step.
struct VoiceVisualizationUniforms {
    // The palette as HSV, hue a fraction of a turn. Slots past the palette repeat its first
    // color.
    var col0: SIMD4<Float>
    var col1: SIMD4<Float>
    var col2: SIMD4<Float>
    var col3: SIMD4<Float>
    var col4: SIMD4<Float>
    // The render target, in pixels.
    var resolution: SIMD2<Float>
    // The last tap and the hovering pointer, centred and normalized to the shorter side, y up.
    var tap: SIMD2<Float>
    var hover: SIMD2<Float>
    var time: Float
    var count: Float
    var bright: Float
    var sat: Float
    var load: Float
    var flow: Float
    var flowSpin: Float
    var orbSpin: Float
    var react: Float
    var expressivity: Float
    var dark: Float
    var tapTime: Float
    var hoverAmt: Float
    var mic: Float
    var voice: Float
    var scale: Float
}
