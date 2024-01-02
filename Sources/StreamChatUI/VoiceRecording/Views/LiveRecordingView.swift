//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// A view that displays information about a currently active recording or a recording in preview.
open class LiveRecordingView: _View, ThemeProvider {
    public struct Content: Equatable {
        /// A flag that informs the view that we are currently recording audio.
        public var isRecording: Bool

        /// A flag that informs the view that we are in preview and the audio's playback is active.
        public var isPlaying: Bool

        /// The duration of the recording.
        public var duration: TimeInterval

        /// While in preview this one contains the currentTime of the active playback (if any).
        public var currentTime: TimeInterval

        /// An array containing the data that can be used to render a waveform visualisation for the
        /// recording (active or in preview).
        public var waveform: [Float]

        public init(
            isRecording: Bool,
            isPlaying: Bool,
            duration: TimeInterval,
            currentTime: TimeInterval,
            waveform: [Float]
        ) {
            self.isRecording = isRecording
            self.isPlaying = isPlaying
            self.duration = duration
            self.currentTime = currentTime
            self.waveform = waveform
        }

        static var initial = Content(
            isRecording: false,
            isPlaying: false,
            duration: 0,
            currentTime: 0,
            waveform: []
        )
    }

    public var content: Content = .initial {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - UI Components

    /// The main container that all view's components will be added into.
    open private(set) lazy var container: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    /// The button that can be used to control playback while in preview.
    open private(set) lazy var playbackButton: UIButton = .init()
        .withoutAutoresizingMaskConstraints

    /// A view that shows a mic image by default to inform the user that we are currently recording audio.
    open private(set) lazy var recordingIndicator: UIImageView = .init()
        .withoutAutoresizingMaskConstraints

    /// A label containing the recording's duration or the playback's currentTime while in preview and have
    /// an active playback.
    open private(set) lazy var durationLabel: UILabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints

    /// The view used to render a waveform visualisation from the waveform array.
    open lazy var waveformView: WaveformView = .init()
        .withoutAutoresizingMaskConstraints

    // MARK: - Lifecycle

    override open func setUpLayout() {
        super.setUpLayout()
        [playbackButton, recordingIndicator]
            .forEach {
                $0.pin(anchors: [.width], to: 35)
                $0.pin(anchors: [.height], to: 40)
            }

        container.axis = .horizontal
        container.spacing = 5
        container.addArrangedSubview(playbackButton)
        container.addArrangedSubview(recordingIndicator)
        container.addArrangedSubview(durationLabel)
        container.addArrangedSubview(waveformView)

        playbackButton.isHidden = true

        embed(container, insets: .zero)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = appearance.colorPalette.background

        playbackButton.setImage(appearance.images.recordingPlay, for: .normal)
        playbackButton.setImage(appearance.images.recordingPause, for: .selected)
        playbackButton.tintColor = appearance.colorPalette.accentPrimary

        recordingIndicator.contentMode = .center
        recordingIndicator.image = appearance.images.mic.tinted(with: appearance.colorPalette.alert)

        durationLabel.textColor = appearance.colorPalette.textLowEmphasis
        durationLabel.font = .monospacedDigitSystemFont(ofSize: appearance.fonts.footnote.pointSize, weight: .medium)
    }

    override open func updateContent() {
        durationLabel.text = appearance.formatters.videoDuration.format(
            content.currentTime == 0 && !content.isPlaying ? content.duration : content.currentTime
        )
        waveformView.content = .init(
            isRecording: content.isRecording,
            duration: content.duration,
            currentTime: content.currentTime,
            waveform: content.waveform
        )
        playbackButton.isHidden = content.isRecording
        playbackButton.isSelected = content.isPlaying
        recordingIndicator.isHidden = !content.isRecording
    }
}
