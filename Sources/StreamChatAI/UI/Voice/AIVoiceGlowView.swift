//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// A soft, airy globe of drifting color that shows what a voice agent is doing.
///
/// Masses of color orbit inside the globe and the background shows through between them. It
/// shimmers while idle, breathes while listening, turns slowly while thinking and swells with
/// speech. Tapping the globe bounces it and ripples its color from the touch, and a hovering
/// pointer ripples it too. With Reduce Motion on it barely moves.
///
/// The view has no size of its own: it fills the space it is given, with the globe about half
/// as wide as the shorter side.
///
/// ```swift
/// AIVoiceGlowView(state: .speaking)
///     .frame(width: 320, height: 320)
/// ```
public struct AIVoiceGlowView: View {
    private let state: AIVoiceAgentState
    private let colors: [Color]?
    private let expressivity: Double
    private let audioLevel: Double?

    /// Creates a glow.
    ///
    /// - Parameters:
    ///   - state: What the agent is doing.
    ///   - colors: One to five colors to paint it with, or nil for
    ///     ``AIAppearance/Colors/voiceVisualization``.
    ///   - expressivity: How lively the motion is, from 0, nearly still, through 1, the
    ///     default, to 2, twice as animated. It never changes the colors.
    ///   - audioLevel: The live level of the voice being heard, from 0 to 1, such as a call
    ///     participant's audio level, fed at 15 Hz or more. Nil animates speech on its own.
    public init(
        state: AIVoiceAgentState,
        colors: [Color]? = nil,
        expressivity: Double = 1,
        audioLevel: Double? = nil
    ) {
        self.state = state
        self.colors = colors
        self.expressivity = expressivity
        self.audioLevel = audioLevel
    }

    public var body: some View {
        VoiceVisualizationView(
            style: .glow,
            state: state,
            colors: colors,
            expressivity: expressivity,
            audioLevel: audioLevel
        )
        .accessibilityElement()
        .accessibilityLabel(Text(L10n.Voice.agent))
        .accessibilityValue(Text(state.accessibilityValue))
    }
}
