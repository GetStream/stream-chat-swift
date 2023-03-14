//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// A simple object that is responsible for updating the UI elements of an AudioView based on the current
/// playbackState and some provided values.
open class ChatMessageAudioViewStateUpdater {
    public required init() {}

    open func configure(
        leadingButton: _Button,
        for state: AudioPlaybackState,
        with appearance: Appearance
    ) {
        leadingButton.setImage(appearance.images.play, for: .normal)
        switch state {
        case .notLoaded, .loading:
            leadingButton.isSelected = false
            leadingButton.setImage(nil, for: .selected)
        case .paused, .playing, .stopped:
            leadingButton.setImage(appearance.images.pause, for: .selected)
            leadingButton.isSelected = state == .playing
        }
    }

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

    open func configure(
        detailsLabel: UILabel,
        for state: AudioPlaybackState,
        with appearance: Appearance,
        value: String?
    ) {
        switch state {
        case .notLoaded:
            detailsLabel.isHidden = false
            detailsLabel.font = appearance.fonts.caption1
            detailsLabel.text = value
        case .loading:
            detailsLabel.isHidden = true
            detailsLabel.text = nil
        case .paused, .playing, .stopped:
            detailsLabel.isHidden = false
            detailsLabel.font = .monospacedDigitSystemFont(
                ofSize: appearance.fonts.caption1.pointSize, weight: .medium
            )
            detailsLabel.text = value
        }
    }

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
        }
    }

    open func configure(
        trailingButton: _Button,
        for state: AudioPlaybackState,
        with appearance: Appearance,
        value: String
    ) {
        switch state {
        case .notLoaded, .loading, .stopped:
            trailingButton.isHidden = true
            trailingButton.setTitle(nil, for: .normal)
        case .paused, .playing:
            trailingButton.isHidden = false
            trailingButton.setTitle(value, for: .normal)
        }
    }
}
