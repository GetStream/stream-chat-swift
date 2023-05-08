//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// Displays an interactive waveform visualisation of an audio file.
open class WaveformView: _View, ThemeProvider {
    public struct Content: Equatable {
        var isRecording: Bool
        var isPlaying: Bool
        var duration: TimeInterval
        var currentTime: TimeInterval
        var location: URL?
        var waveform: [Float]

        static let initial = Content(
            isRecording: false,
            isPlaying: false,
            duration: 0,
            currentTime: 0,
            location: nil,
            waveform: []
        )
    }

    var content: Content = .initial {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - UI Components

    open private(set) lazy var audioVisualizationView: AudioVisualizationView = .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var slider: UISlider = .init()
        .withoutAutoresizingMaskConstraints

    // MARK: - UI Lifecycle

    override open func setUpLayout() {
        super.setUpLayout()

        embed(audioVisualizationView, insets: .zero)
        embed(slider, insets: .zero)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        audioVisualizationView.backgroundColor = .clear

        slider.setThumbImage(appearance.images.sliderThumb, for: .normal)
        slider.minimumTrackTintColor = .clear
        slider.maximumTrackTintColor = .clear
    }

    override open func updateContent() {
        super.updateContent()

        slider.isUserInteractionEnabled = !content.isRecording
        slider.isHidden = content.isRecording
        slider.maximumValue = Float(content.duration)
        slider.minimumValue = 0
        slider.value = Float(content.currentTime)

        audioVisualizationView.audioVisualizationMode = content.isRecording ? .write : .read
        if audioVisualizationView.content != content.waveform {
            audioVisualizationView.content = content.waveform
        }
        audioVisualizationView.currentGradientPercentage = max(0, min(1, Float(content.currentTime / content.duration)))
        audioVisualizationView.setNeedsLayout()
        audioVisualizationView.setNeedsDisplay()
    }
}
