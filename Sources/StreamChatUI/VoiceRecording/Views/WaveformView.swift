//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// Displays an interactive waveform visualisation of an audio file.
open class WaveformView: _View, ThemeProvider {
    public struct Content: Equatable {
        /// When set to `true` the waveform will be updating with the data live (scrolling to the trailing side
        /// as new data arrive).
        public var isRecording: Bool

        /// The duration of the Audio file that we are representing.
        public var duration: TimeInterval

        /// The playback's currentTime for the Audio file we are representing.
        public var currentTime: TimeInterval

        /// The waveform's data that will be used to render the visualisation.
        public var waveform: [Float]

        public static let initial = Content(
            isRecording: false,
            duration: 0,
            currentTime: 0,
            waveform: []
        )

        public init(
            isRecording: Bool,
            duration: TimeInterval,
            currentTime: TimeInterval,
            waveform: [Float]
        ) {
            self.isRecording = isRecording
            self.duration = duration
            self.currentTime = currentTime
            self.waveform = waveform
        }
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
