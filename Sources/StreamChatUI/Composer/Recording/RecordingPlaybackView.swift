//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

open class RecordingPlaybackView: _View, ThemeProvider {
    public struct Content {
        var isRecording: Bool
        var isPlaying: Bool
        var duration: TimeInterval
        var currentTime: TimeInterval
        var waveform: [Float]

        static var initial = Content(
            isRecording: false,
            isPlaying: false,
            duration: 0,
            currentTime: 0,
            waveform: []
        )
    }

    var content: Content = .initial {
        didSet { updateContentIfNeeded() }
    }

    open private(set) lazy var container: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var playbackButton: UIButton = .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var recordingIndicator: UIImageView = .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var durationLabel: UILabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints

    open lazy var waveformView: WaveformView = .init()
        .withoutAutoresizingMaskConstraints

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
            isPlaying: content.isPlaying,
            duration: content.duration,
            currentTime: content.currentTime,
            waveform: content.waveform
        )
        playbackButton.isHidden = content.isRecording
        playbackButton.isSelected = content.isPlaying
        recordingIndicator.isHidden = !content.isRecording
    }
}
