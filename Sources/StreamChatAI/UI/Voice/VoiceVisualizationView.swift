//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

struct VoiceVisualizationView: UIViewRepresentable {
    let style: VoiceVisualizationStyle
    let state: AIVoiceAgentState
    let colors: [Color]?
    let expressivity: Double
    let audioLevel: Double?

    @Injected(\.aiAppearance.colors) private var appearanceColors

    func makeUIView(context: Context) -> VoiceVisualizationMetalView {
        let view = VoiceVisualizationMetalView(style: style, input: input(in: context.environment))
        view.isDark = context.environment.colorScheme == .dark
        return view
    }

    func updateUIView(_ view: VoiceVisualizationMetalView, context: Context) {
        view.input = input(in: context.environment)
        view.isDark = context.environment.colorScheme == .dark
    }

    private func input(in environment: EnvironmentValues) -> VoiceVisualizationDriver.Input {
        let traits = UITraitCollection(userInterfaceStyle: environment.colorScheme == .dark ? .dark : .light)
        let palette = colors.flatMap { $0.isEmpty ? nil : $0.map { UIColor($0) } }
            ?? appearanceColors.voiceVisualizationPalette
        return VoiceVisualizationDriver.Input(
            state: state,
            colors: VoiceVisualizationPalette.hsv(palette, traits: traits),
            expressivity: Float(min(max(expressivity, 0), 2)),
            audioLevel: audioLevel.map { Float(min(max($0, 0), 1)) },
            reduceMotion: environment.accessibilityReduceMotion
        )
    }
}
