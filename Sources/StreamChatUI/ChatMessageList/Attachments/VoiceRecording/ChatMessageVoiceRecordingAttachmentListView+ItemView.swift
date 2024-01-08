//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension ChatMessageVoiceRecordingAttachmentListView {
    /// A view that renders a VoiceRecording attachment and allows playback and interaction.
    ///
    /// High level overview of the ItemView layout:
    /// ```
    /// |-----------------------------------------------------------------------|
    /// |                 | fileNameLabel           |                           |
    /// | playPauseButton | ------------------------| fileIconAndPlaybackRate   |
    /// |                 | bottomContainerStackView|                           |
    /// |-----------------------------------------------------------------------|
    /// ```
    open class ItemView: _View, ThemeProvider {
        // MARK: - Properties

        /// Content of the attachment `ChatMessageFileAttachment`
        public var content: ChatMessageVoiceRecordingAttachment? {
            didSet { updateContentIfNeeded() }
        }

        // MARK: - Configuration Properties

        /// The Presenter responsible for all interaction and event handling.
        internal lazy var presenter: ItemViewPresenter = .init(self)

        /// The provider that will be asked to provide the index of the content related to the other attachments
        /// in the same `ChatMessage`. The index then will be used to create an name for UI.
        open var indexProvider: (() -> Int)?

        // MARK: - UI Components

        open private(set) lazy var mainContainerStackView: UIStackView = .init()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "mainContainerStackView")

        /// The play/pause button that allows the user to control the playback.
        open private(set) lazy var playPauseButton: PlayPauseButton = .init()
            .withoutAutoresizingMaskConstraints

        /// A stack that contains by default the file name and the size of the file.
        open private(set) lazy var centerContainerStackView: UIStackView = .init()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "centerContainerStackView")

        /// Label which shows name of the file, usually with extension (file.pdf)
        open private(set) lazy var fileNameLabel = UILabel()
            .withoutAutoresizingMaskConstraints
            .withBidirectionalLanguagesSupport
            .withAdjustingFontForContentSizeCategory
            .withAccessibilityIdentifier(identifier: "fileNameLabel")

        /// Stack containing loading indicator and label with fileSize.
        open private(set) lazy var bottomContainerStackView: UIStackView = .init()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "informationStack")

        /// Animated indicator showing progress of uploading of a file.
        open private(set) lazy var loadingIndicator = components
            .loadingIndicator
            .init()
            .withoutAutoresizingMaskConstraints

        /// Label indicating size of the file.
        open private(set) lazy var fileSizeLabel = UILabel()
            .withoutAutoresizingMaskConstraints
            .withBidirectionalLanguagesSupport
            .withAdjustingFontForContentSizeCategory
            .withAccessibilityIdentifier(identifier: "fileSizeLabel")

        /// The clampedView that contains the playbackLoadingIndicator and the durationLabel.
        open private(set) lazy var playbackLoadingClampedView: ClampedView = .init()
            .withoutAutoresizingMaskConstraints

        /// Animated indicator showing progress of buffering an audio file.
        open private(set) lazy var playbackLoadingIndicator = components
            .loadingIndicator
            .init()
            .withoutAutoresizingMaskConstraints

        /// The label that shows the duration of an audio file/the current time of the playback.
        open private(set) lazy var durationLabel = UILabel()
            .withoutAutoresizingMaskConstraints
            .withBidirectionalLanguagesSupport
            .withAdjustingFontForContentSizeCategory
            .withAccessibilityIdentifier(identifier: "durationLabel")

        /// The view that shows a waveform visualisation of the audio file.
        open private(set) lazy var waveformView = WaveformView()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "waveform")

        /// The clampedView that contains the fileIcon and the playbackRate button
        open private(set) lazy var fileIconAndPlaybackRateClampedView: ClampedView = .init()
            .withoutAutoresizingMaskConstraints

        /// The imageView showing the file related icon.
        open private(set) lazy var fileIconImageView = UIImageView()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "fileIconImageView")

        /// The button that the user can use to set the playback's rate.
        open private(set) lazy var playbackRateButton: PillButton = .init()
            .withoutAutoresizingMaskConstraints

        // MARK: - UI Lifecycle

        override open func setUp() {
            super.setUp()
            presenter.setUp()
        }

        override open func setUpLayout() {
            super.setUpLayout()

            playbackLoadingClampedView.axis = .vertical
            playbackLoadingClampedView.addArrangedSubview(playbackLoadingIndicator)
            playbackLoadingClampedView.addArrangedSubview(durationLabel)

            fileIconAndPlaybackRateClampedView.addArrangedSubview(fileIconImageView)
            fileIconAndPlaybackRateClampedView.addArrangedSubview(playbackRateButton)

            bottomContainerStackView.axis = .horizontal
            bottomContainerStackView.spacing = 4
            bottomContainerStackView.alignment = .center
            [loadingIndicator, fileSizeLabel, playbackLoadingClampedView, waveformView]
                .forEach { bottomContainerStackView.addArrangedSubview($0) }

            centerContainerStackView.axis = .vertical
            centerContainerStackView.spacing = 8
            centerContainerStackView.alignment = .fill
            [fileNameLabel, bottomContainerStackView]
                .forEach { centerContainerStackView.addArrangedSubview($0) }

            addSubview(mainContainerStackView)
            mainContainerStackView.axis = .horizontal
            mainContainerStackView.spacing = 8
            mainContainerStackView.alignment = .center
            mainContainerStackView.pin(to: layoutMarginsGuide)

            [playPauseButton, centerContainerStackView, fileIconAndPlaybackRateClampedView]
                .forEach { mainContainerStackView.addArrangedSubview($0) }

            durationLabel.setContentHuggingPriority(.streamRequire, for: .vertical)
            waveformView.setContentHuggingPriority(.streamLow, for: .vertical)
            fileIconImageView.setContentHuggingPriority(.streamRequire, for: .horizontal)
        }

        override open func setUpAppearance() {
            super.setUpAppearance()

            backgroundColor = appearance.colorPalette.popoverBackground
            layer.cornerRadius = 12
            layer.masksToBounds = true
            layer.borderWidth = 1
            layer.borderColor = appearance.colorPalette.border.cgColor

            fileSizeLabel.textColor = appearance.colorPalette.subtitleText
            fileSizeLabel.font = appearance.fonts.subheadlineBold

            fileNameLabel.font = appearance.fonts.bodyBold
            fileNameLabel.lineBreakMode = .byTruncatingMiddle

            fileIconImageView.contentMode = .center
            fileIconImageView.image = appearance.images.fileAac

            durationLabel.textColor = appearance.colorPalette.textLowEmphasis
            durationLabel.font = .monospacedDigitSystemFont(
                ofSize: appearance.fonts.caption1.pointSize, weight: .medium
            )

            playbackRateButton.setTitleColor(appearance.colorPalette.staticBlackColorText, for: .normal)
            playbackRateButton.titleLabel?.font = appearance.fonts.footnote
        }

        override open func updateContent() {
            super.updateContent()

            fileNameLabel.text = content.map { content in
                appearance.formatters.audioRecordingNameFormatter.title(
                    forItemAtURL: content.voiceRecordingURL,
                    index: indexProvider?() ?? 0
                )
            }

            switch content?.uploadingState?.state {
            case .uploaded:
                fileSizeLabel.text = content?.payload.file.sizeString
            case .uploadingFailed:
                fileSizeLabel.text = L10n.Message.Sending.attachmentUploadingFailed
            default:
                fileSizeLabel.text = content?.uploadingState?.fileUploadingProgress
            }

            switch content?.uploadingState?.state {
            case .pendingUpload, .uploading:
                loadingIndicator.isVisible = true
            default:
                loadingIndicator.isVisible = false
            }

            switch content?.uploadingState?.state {
            case .uploadingFailed:
                fileIconImageView.image = appearance.fileAttachmentActionIcon(for: .uploadingFailed)
            default:
                fileIconImageView.image = appearance.images.fileAac
            }

            guard
                let content = content,
                content.uploadingState?.state == .uploaded || content.uploadingState == nil
            else {
                playPauseButton.isHidden = true
                durationLabel.isHidden = true
                fileSizeLabel.isHidden = false
                playbackRateButton.isHidden = true
                waveformView.isHidden = true
                playbackLoadingClampedView.isHidden = true
                return
            }

            playPauseButton.isHidden = false
            durationLabel.isHidden = false
            fileSizeLabel.isHidden = true
            waveformView.isHidden = false
            playbackLoadingClampedView.isHidden = false
            playbackLoadingIndicator.isHidden = true

            waveformView.content = .init(
                isRecording: false,
                duration: content.duration ?? 0,
                currentTime: TimeInterval(waveformView.slider.value),
                waveform: content.waveformData ?? []
            )
        }

        // MARK: - View updates

        open func updatePlayPauseButton(
            for state: AudioPlaybackState
        ) {
            playPauseButton.setImage(appearance.images.playFill, for: .normal)
            playPauseButton.isSelected = state == .playing
            switch state {
            case .notLoaded, .loading:
                playPauseButton.setImage(nil, for: .selected)
            case .paused, .playing, .stopped:
                playPauseButton.setImage(appearance.images.pauseFill, for: .selected)
            default:
                log.assert(false, "Unhandled `AudioPlaybackState` \(state)")
            }
        }

        open func updatePlaybackLoadingIndicator(
            for state: AudioPlaybackState
        ) {
            if state == .loading {
                playbackLoadingIndicator.isHidden = false
                playbackLoadingIndicator.startRotation()
            } else {
                playbackLoadingIndicator.isHidden = true
                playbackLoadingIndicator.stopRotating()
            }
        }

        open func updateDurationLabel(
            for state: AudioPlaybackState,
            duration: TimeInterval,
            currentTime: TimeInterval
        ) {
            durationLabel.isHidden = false
            switch state {
            case .notLoaded, .loading, .stopped:
                durationLabel.text = appearance.formatters.videoDuration.format(duration)
            case .paused, .playing:
                durationLabel.text = appearance.formatters.videoDuration.format(min(currentTime, duration))
            default:
                log.assert(false, "Unhandled `AudioPlaybackState` \(state)")
            }
        }

        open func updateWaveformView(
            for state: AudioPlaybackState,
            duration: TimeInterval,
            currentTime: TimeInterval
        ) {
            waveformView.content = .init(
                isRecording: false,
                duration: duration,
                currentTime: currentTime,
                waveform: waveformView.content.waveform
            )
        }

        open func updateFileIconImageView(
            for state: AudioPlaybackState
        ) {
            switch state {
            case .notLoaded, .loading, .stopped:
                fileIconImageView.isHidden = false
            case .paused, .playing:
                fileIconImageView.isHidden = true
            default:
                log.assert(false, "Unhandled `AudioPlaybackState` \(state)")
            }
        }

        open func updatePlaybackRateButton(
            for state: AudioPlaybackState,
            value: Float
        ) {
            switch state {
            case .notLoaded, .loading, .stopped:
                playbackRateButton.isHidden = true
                playbackRateButton.setTitle(nil, for: .normal)
            case .paused, .playing:
                guard
                    let rateValueString = appearance.formatters.audioPlaybackRateFormatter.format(value)
                else {
                    playbackRateButton.isHidden = true
                    return
                }
                playbackRateButton.isHidden = false
                playbackRateButton.setTitle(L10n.Audio.Player.rate(rateValueString), for: .normal)
            default:
                log.assert(false, "Unhandled `AudioPlaybackState` \(state)")
            }
        }
    }
}
