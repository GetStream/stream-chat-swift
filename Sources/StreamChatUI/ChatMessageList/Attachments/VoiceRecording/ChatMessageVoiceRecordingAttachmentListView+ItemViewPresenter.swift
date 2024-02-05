//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

extension ChatMessageVoiceRecordingAttachmentListView {
    /// The Presenter that drives interactions and events for
    internal class ItemViewPresenter: AudioPlayingDelegate {
        /// The delegate to which the Presenter will forward all audioPlayback events.
        internal weak var delegate: VoiceRecordingAttachmentPresentationViewDelegate?

        /// The view that holds the reference to this Presenter.
        internal weak var view: ChatMessageVoiceRecordingAttachmentListView.ItemView?

        /// The rate of the currentPlayback. It's used to provide an override when the playback has been
        /// paused, but we want to maintain showing the last non-zero rate on UI.
        internal private(set) var currentPlaybackRate: AudioPlaybackRate = .zero

        /// The debouncer that will be used to add a grace period on the presentation of the playbackLoadingIndicator.
        private lazy var debouncer: Debouncer = .init(0.5, queue: .main)

        // MARK: - Lifecycle

        internal init(
            _ view: ChatMessageVoiceRecordingAttachmentListView.ItemView
        ) {
            self.view = view
        }

        internal func setUp() {
            delegate?.voiceRecordingAttachmentPresentationViewConnect(
                delegate: self
            )

            guard let view = view else { return }

            view.playPauseButton.addTarget(
                self,
                action: #selector(didTapOnPlayPauseButton),
                for: .touchUpInside
            )

            view.playbackRateButton.addTarget(
                self,
                action: #selector(didTapOnPlaybackRateButton),
                for: .touchUpInside
            )

            view.waveformView.slider.addTarget(
                self,
                action: #selector(didSlide),
                for: .valueChanged
            )

            view.waveformView.slider.addTarget(
                self,
                action: #selector(didTouchUpSlider),
                for: .touchUpInside
            )
        }

        // MARK: - Playback Handlers

        internal func play() {
            guard let attachment = view?.content else {
                return
            }
            delegate?.voiceRecordingAttachmentPresentationViewBeginPayback(attachment)
        }

        internal func pause() {
            delegate?.voiceRecordingAttachmentPresentationViewPausePayback()
        }

        // MARK: - Action Handlers

        @objc internal func didTapOnPlayPauseButton(
            _ sender: UIButton
        ) {
            if sender.isSelected {
                pause()
            } else {
                play()
            }
        }

        @objc internal func didTapOnPlaybackRateButton(
            _ sender: UIButton
        ) {
            switch currentPlaybackRate {
            case .normal:
                delegate?.voiceRecordingAttachmentPresentationViewUpdatePlaybackRate(.double)
            case .half:
                delegate?.voiceRecordingAttachmentPresentationViewUpdatePlaybackRate(.normal)
            case .double:
                delegate?.voiceRecordingAttachmentPresentationViewUpdatePlaybackRate(.half)
            case .zero:
                delegate?.voiceRecordingAttachmentPresentationViewUpdatePlaybackRate(.normal)
            default:
                delegate?.voiceRecordingAttachmentPresentationViewUpdatePlaybackRate(.zero)
            }
        }

        @objc internal func didSlide(
            _ sender: UISlider
        ) {
            delegate?.voiceRecordingAttachmentPresentationViewSeek(
                to: TimeInterval(sender.value)
            )
        }

        @objc internal func didTouchUpSlider(
            _ sender: UISlider
        ) {
            play()
        }

        // MARK: - AudioPlayingDelegate

        internal func audioPlayer(
            _ audioPlayer: AudioPlaying,
            didUpdateContext context: AudioPlaybackContext
        ) {
            guard let view = view, let content = view.content else {
                return
            }

            let isCurrentItemActive = context.assetLocation == content.voiceRecordingURL
            let contextForViewUpdate = isCurrentItemActive ? context : .notLoaded
            let contentDuration = content.duration ?? contextForViewUpdate.duration

            view.updatePlayPauseButton(for: contextForViewUpdate.state)
            view.updateFileIconImageView(for: contextForViewUpdate.state)
            view.updateWaveformView(
                for: contextForViewUpdate.state,
                duration: contentDuration,
                currentTime: contextForViewUpdate.currentTime
            )

            let playbackRate: Float = {
                switch contextForViewUpdate.state {
                case .paused, .playing:
                    return contextForViewUpdate.rate.rawValue != 0
                        ? contextForViewUpdate.rate.rawValue
                        : currentPlaybackRate.rawValue
                default:
                    return contextForViewUpdate.rate.rawValue
                }
            }()

            view.updatePlaybackRateButton(
                for: contextForViewUpdate.state,
                value: playbackRate
            )

            if contextForViewUpdate.rate != .zero {
                currentPlaybackRate = contextForViewUpdate.rate
            }

            let loadingIndicatorAndDurationLabel = { [view] in
                view.updatePlaybackLoadingIndicator(for: contextForViewUpdate.state)
                view.updateDurationLabel(
                    for: contextForViewUpdate.state,
                    duration: contentDuration,
                    currentTime: contextForViewUpdate.currentTime
                )
                view.durationLabel.isHidden = view.durationLabel.isHidden || !view.playbackLoadingIndicator.isHidden
            }

            debouncer.invalidate()
            if contextForViewUpdate.state == .loading {
                debouncer.execute { loadingIndicatorAndDurationLabel() }
            } else {
                loadingIndicatorAndDurationLabel()
            }
        }
    }
}
