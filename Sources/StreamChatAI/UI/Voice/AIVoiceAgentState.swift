//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// What a voice agent is doing, which ``AIVoiceGlowView`` and ``AIVoiceWaveView`` show as
/// motion.
///
/// The states differ only in how a visualization moves, never in its colors, and changing the
/// state eases from one motion into the next.
public enum AIVoiceAgentState: String, CaseIterable, Sendable {
    /// Waiting to be spoken to: a calm, barely-there shimmer.
    case idle
    /// Not ready yet: a loader sweep with a pulsing breath.
    case connecting
    /// Hearing somebody: a gentle expand and contract.
    case listening
    /// Working on an answer: a slow turn or a travelling wave.
    case thinking
    /// Talking: strong motion that ebbs and pauses like speech.
    case speaking
}

extension AIVoiceAgentState {
    // `load`, `flow` and `react` each select a motion pattern, one per state, so easing between
    // states crossfades the patterns.
    struct Motion: Equatable {
        var speed: Float
        var bright: Float
        var sat: Float
        var load: Float
        var flow: Float
        var react: Float
    }

    var motion: Motion {
        switch self {
        case .idle:
            Motion(speed: 0.4, bright: 1, sat: 1, load: 0, flow: 0, react: 0.12)
        case .connecting:
            Motion(speed: 1, bright: 1, sat: 1, load: 1, flow: 0, react: 0)
        case .listening:
            Motion(speed: 0.9, bright: 1, sat: 1, load: 0, flow: 0, react: 0.45)
        case .thinking:
            Motion(speed: 1.25, bright: 1, sat: 1, load: 0, flow: 1, react: 0)
        case .speaking:
            Motion(speed: 1.25, bright: 1, sat: 1, load: 0, flow: 0, react: 1)
        }
    }

    var accessibilityValue: String {
        switch self {
        case .idle: L10n.Voice.idle
        case .connecting: L10n.Voice.connecting
        case .listening: L10n.Voice.listening
        case .thinking: L10n.Voice.thinking
        case .speaking: L10n.Voice.speaking
        }
    }
}
