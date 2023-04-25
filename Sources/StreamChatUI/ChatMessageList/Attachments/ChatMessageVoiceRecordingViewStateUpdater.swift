//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

/// An object that is responsible for updating the UI elements of an AudioView based on the current
/// playbackState and some provided values.
open class ChatMessageVoiceRecordingViewStateUpdater {
    public required init() {}

    /// Configures the AudioView's leading button
    open func configure(
        leadingButton: UIButton,
        for state: AudioPlaybackState,
        with appearance: Appearance
    ) {
        leadingButton.setImage(appearance.images.playFill, for: .normal)
        switch state {
        case .notLoaded, .loading:
            leadingButton.isSelected = false
            leadingButton.setImage(nil, for: .selected)
        case .paused, .playing, .stopped:
            leadingButton.setImage(appearance.images.pauseFill, for: .selected)
            leadingButton.isSelected = state == .playing
        default:
            break
        }
    }

    /// Configures the AudioView's loading indicator
    open func configure(
        loadingIndicator: ChatLoadingIndicator,
        for state: AudioPlaybackState,
        with appearance: Appearance
    ) {
        switch state {
        case .loading:
            loadingIndicator.isHidden = false
            loadingIndicator.startRotation()
        default:
            loadingIndicator.isHidden = true
            loadingIndicator.stopRotating()
        }
    }

    /// Configures the AudioView's detailsLabel with the provided string
    open func configure(
        detailsLabel: UILabel,
        for state: AudioPlaybackState,
        with appearance: Appearance,
        duration: TimeInterval,
        currentTime: TimeInterval
    ) {
        switch state {
        case .notLoaded:
            detailsLabel.isHidden = true
            detailsLabel.text = nil
        case .loading:
            detailsLabel.isHidden = true
            detailsLabel.text = nil
        case .stopped:
            detailsLabel.isHidden = false
            detailsLabel.text = appearance.formatters.videoDuration.format(duration)
        case .paused, .playing, .stopped:
            detailsLabel.isHidden = false
            detailsLabel.text = appearance.formatters.videoDuration.format(min(currentTime, duration))
        default:
            break
        }
    }

    open func configure(
        sizeLabel: UILabel,
        for state: AudioPlaybackState,
        with appearance: Appearance,
        value: String?
    ) {
        switch state {
        case .notLoaded:
            sizeLabel.isHidden = false
            sizeLabel.text = value
        case .loading:
            sizeLabel.isHidden = true
            sizeLabel.text = nil
        case .paused, .playing, .stopped:
            sizeLabel.isHidden = true
            sizeLabel.text = nil
        default:
            break
        }
    }

    /// Configures the AudioView's progressView with the provided values for maximum and current
    open func configure(
        progressView: UISlider,
        for state: AudioPlaybackState,
        with appearance: Appearance,
        maximumValue: Float,
        value: Float
    ) {
        progressView.isEnabled = state == .paused || state == .playing
        if progressView.isEnabled {
            progressView.maximumValue = maximumValue
            progressView.value = value
        } else {
            progressView.maximumValue = 0
            progressView.value = 0
        }
    }

    /// Configures the AudioView's fileIconImageView
    open func configure(
        fileIconImageView: UIImageView,
        for state: AudioPlaybackState,
        with appearance: Appearance
    ) {
        switch state {
        case .notLoaded, .loading, .stopped:
            fileIconImageView.isHidden = false
        case .paused, .playing:
            fileIconImageView.isHidden = true
        default:
            break
        }
    }

    /// Configures the AudioView's trailing button
    open func configure(
        trailingButton: UIButton,
        for state: AudioPlaybackState,
        with appearance: Appearance,
        value: Float,
        overrideValue: Float
    ) {
        switch state {
        case .notLoaded, .loading, .stopped:
            trailingButton.isHidden = true
            trailingButton.setTitle(nil, for: .normal)
        case .paused, .playing:
            guard
                let rateValueString = appearance.formatters.audioPlaybackRateFormatter.format(value != 0 ? value : overrideValue)
            else {
                trailingButton.isHidden = true
                return
            }
            trailingButton.isHidden = false
            trailingButton.setTitle(L10n.Audio.Player.rate(rateValueString), for: .normal)
        default:
            break
        }
    }
}
