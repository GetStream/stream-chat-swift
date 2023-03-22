//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamChat
import UIKit

extension ChatMessageFileAttachmentListView {
    open class AudioView: _View, ThemeProvider, AudioPlayingDelegate {
        public weak var delegate: AudioAttachmentPresentationViewDelegate?

        /// Content of the attachment `ChatMessageFileAttachment`
        public var content: ChatMessageFileAttachment? {
            didSet { updateContentIfNeeded() }
        }

        open private(set) lazy var viewConfigurator: ChatMessageAudioViewStateUpdater = components
            .audioAttachmentViewUpdater
            .init()

        open private(set) lazy var mainContainerStackView: ContainerStackView = ContainerStackView()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "mainContainerStackView")

        open private(set) lazy var leadingButton = _Button()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "playPauseButton")

        public private(set) lazy var loadingIndicator: ChatLoadingIndicator = components
            .loadingIndicator.init()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "loadingIndicator")

        open private(set) lazy var detailsLabel = UILabel()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "fileSizeLabel")

        open private(set) lazy var progressView = UISlider()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "progressBar")

        open private(set) lazy var fileIconImageView = UIImageView()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "fileIconImageView")

        open private(set) lazy var trailingButton = _Button()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "rateButton")

        private var currentPlaybackContext: AudioPlaybackContext?

        // MARK: - Lifecycle

        override open func prepareForReuse() {
            super.prepareForReuse()

            /// Pause the current playback once the view is ready for reuse
            delegate?.audioAttachmentPresentationViewPausePayback()
        }

        override open func setUp() {
            super.setUp()

            leadingButton.removeTarget(self, action: nil, for: .touchUpInside)
            trailingButton.removeTarget(self, action: nil, for: .touchUpInside)
            progressView.removeTarget(self, action: nil, for: .valueChanged)

            leadingButton.addTarget(
                self,
                action: #selector(didTapLeadingButton),
                for: .touchUpInside
            )
            trailingButton.addTarget(
                self,
                action: #selector(didTapTrailingButton),
                for: .touchUpInside
            )
            progressView.addTarget(
                self,
                action: #selector(didChangeSliderValue),
                for: .valueChanged
            )
        }

        override open func setUpLayout() {
            super.setUpLayout()

            addSubview(mainContainerStackView)
            mainContainerStackView.pin(to: layoutMarginsGuide)

            mainContainerStackView.axis = .horizontal
            mainContainerStackView.alignment = .center
            mainContainerStackView.addArrangedSubviews([
                leadingButton,
                loadingIndicator,
                detailsLabel,
                progressView,
                fileIconImageView,
                trailingButton
            ])

            detailsLabel.setContentHuggingPriority(.lowest, for: .horizontal)
        }

        override open func setUpAppearance() {
            super.setUpAppearance()

            leadingButton.setImage(appearance.images.play, for: .selected)

            detailsLabel.textColor = appearance.colorPalette.subtitleText
            detailsLabel.font = UIFont.monospacedDigitSystemFont(
                ofSize: appearance.fonts.caption1.pointSize, weight: .medium
            )

            fileIconImageView.contentMode = .center

            trailingButton.titleLabel?.font = appearance.fonts.caption1
            trailingButton.setImage(nil, for: .normal)
            trailingButton.setTitleColor(
                appearance.colorPalette.subtitleText,
                for: .normal
            )

            backgroundColor = appearance.colorPalette.popoverBackground
            layer.cornerRadius = 12
            layer.masksToBounds = true
            layer.borderWidth = 1
            layer.borderColor = appearance.colorPalette.border.cgColor
        }

        // MARK: - Update Handlers

        override open func updateContent() {
            super.updateContent()

            guard let content = content else {
                fileIconImageView.image = nil
                detailsLabel.text = nil
                return
            }

            fileIconImageView.image = appearance.images.fileIcons[content.file.type] ?? appearance.images.fileFallback
            detailsLabel.text = AttachmentFile.sizeFormatter.string(
                fromByteCount: content.file.size
            )

            let context = delegate?.audioAttachmentPresentationViewPlaybackContextForAttachment(content) ?? .notLoaded
            didUpdatePlaybackContext(context)
        }

        private func didUpdatePlaybackContext(
            _ context: AudioPlaybackContext
        ) {
            currentPlaybackContext = context
            let detailsLabelText: String? = {
                switch context.state {
                case .notLoaded, .loading:
                    return content.map {
                        AttachmentFile.sizeFormatter.string(
                            fromByteCount: $0.file.size
                        )
                    }
                case .stopped:
                    return appearance.formatters.videoDuration
                        .format(context.duration)
                case .paused, .playing:
                    return appearance.formatters.videoDuration
                        .format(context.currentTime)
                default:
                    return nil
                }
            }()

            viewConfigurator.configure(
                leadingButton: leadingButton,
                for: context.state,
                with: appearance
            )
            viewConfigurator.configure(
                loadingIndicator: loadingIndicator,
                for: context.state,
                with: appearance
            )
            viewConfigurator.configure(
                detailsLabel: detailsLabel,
                for: context.state,
                with: appearance,
                value: detailsLabelText
            )
            viewConfigurator.configure(
                progressView: progressView,
                for: context.state,
                with: appearance,
                maximumValue: Float(context.duration),
                value: Float(context.currentTime)
            )
            viewConfigurator.configure(
                fileIconImageView: fileIconImageView,
                for: context.state,
                with: appearance
            )
            viewConfigurator.configure(
                trailingButton: trailingButton,
                for: context.state,
                with: appearance,
                value: context.rate.rawValue
            )
        }

        // MARK: - Action Handlers

        @objc open func didTapLeadingButton(
            _ sender: UIButton
        ) {
            if sender.isSelected {
                delegate?.audioAttachmentPresentationViewPausePayback()
            } else if let attachment = content {
                delegate?.audioAttachmentPresentationViewBeginPayback(
                    attachment,
                    with: self
                )
            }
        }

        @objc open func didTapTrailingButton(
            _ sender: UIButton
        ) {
            guard let context = currentPlaybackContext else {
                return
            }

            switch context.rate {
            case .double:
                delegate?.audioAttachmentPresentationViewUpdatePlaybackRate(.half)
            case .normal:
                delegate?.audioAttachmentPresentationViewUpdatePlaybackRate(.double)
            case .half:
                delegate?.audioAttachmentPresentationViewUpdatePlaybackRate(.normal)
            case .zero:
                delegate?.audioAttachmentPresentationViewUpdatePlaybackRate(.normal)
            default:
                break
            }
        }

        @objc open func didChangeSliderValue(
            _ sender: UISlider
        ) {
            delegate?.audioAttachmentPresentationViewSeek(
                to: TimeInterval(sender.value)
            )
        }

        // MARK: - AudioPlayerDelegate

        public func audioPlayer(
            _ audioPlayer: AudioPlaying,
            didUpdateContext context: AudioPlaybackContext
        ) {
            didUpdatePlaybackContext(context)
        }
    }
}
