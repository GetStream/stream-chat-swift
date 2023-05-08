//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that displays the VoiceRecording attachment.
open class VoiceRecordingAttachmentComposerPreview: _View, AppearanceProvider, ComponentsProvider, AudioPlayingDelegate {
    public struct Content {
        /// The title of the attachment.
        public var title: String

        /// The size of the attachment.
        public var size: Int64

        /// The recording's duration
        public var duration: TimeInterval

        /// The local or remote URL to the file
        public var audioAssetURL: URL

        public init(
            title: String,
            size: Int64,
            duration: TimeInterval,
            audioAssetURL: URL
        ) {
            self.title = title
            self.size = size
            self.duration = duration
            self.audioAssetURL = audioAssetURL
        }
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The height the previewView should have
    open var height: CGFloat = 54

    /// The audioPlayer that will be used for the recording's playback.
    ///
    /// - Note: Upon set, the view will subscribe to receive playback events from the audioPlayer.
    open var audioPlayer: AudioPlaying? {
        didSet { audioPlayer?.subscribe(self) }
    }

    /// It provides the index of the recording in the containing message's attachment array.
    open var indexProvider: (() -> Int)?

    open private(set) lazy var container: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var playPauseButton: PlayPauseButton = .init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "actionButton")

    open private(set) lazy var fileNameLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withAccessibilityIdentifier(identifier: "fileNameLabel")

    open private(set) lazy var durationLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withAccessibilityIdentifier(identifier: "durationLabel")

    open private(set) lazy var fileNameAndDurationStack: ContainerStackView = {
        let stack = ContainerStackView(arrangedSubviews: [fileNameLabel, durationLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 3
        return stack
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "fileNameAndDurationStack")
    }()

    /// The image view that displays the file icon of the attachment.
    open private(set) lazy var fileIconImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "fileIconImageView")

    // MARK: - UI Lifecycle

    override open func setUp() {
        super.setUp()

        playPauseButton.addTarget(self, action: #selector(didTapPlayPause), for: .touchUpInside)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = appearance.colorPalette.background
        layer.cornerRadius = 15
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = appearance.colorPalette.border.cgColor

        fileIconImageView.contentMode = .center
        fileIconImageView.image = appearance.images.fileAac

        durationLabel.textColor = appearance.colorPalette.textLowEmphasis
        durationLabel.font = .monospacedDigitSystemFont(ofSize: appearance.fonts.footnote.pointSize, weight: .regular)

        fileNameLabel.textColor = appearance.colorPalette.text
        fileNameLabel.font = appearance.fonts.bodyBold
        fileNameLabel.lineBreakMode = .byTruncatingMiddle
    }

    override open func setUpLayout() {
        super.setUpLayout()

        embed(container, insets: .init(top: 4, leading: 8, bottom: 4, trailing: 34))

        container.axis = .horizontal
        container.spacing = 8
        container.alignment = .center

        container.addArrangedSubview(playPauseButton)
        container.addArrangedSubview(fileNameAndDurationStack)
        container.addArrangedSubview(fileIconImageView)
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = content else { return }

        fileNameLabel.text = appearance.formatters.audioRecordingNameFormatter.title(
            forItemAtURL: content.audioAssetURL,
            index: indexProvider?() ?? 0
        )
        durationLabel.text = appearance.formatters.videoDuration.format(content.duration)
    }

    // MARK: - Action Handlers

    @objc open func didTapPlayPause(_ sender: UIButton) {
        guard let content = content else {
            return
        }
        if sender.isSelected {
            audioPlayer?.pause()
        } else {
            audioPlayer?.loadAsset(from: content.audioAssetURL)
        }
    }

    // MARK: - AudioPlayingDelegate

    open func audioPlayer(
        _ audioPlayer: AudioPlaying,
        didUpdateContext context: AudioPlaybackContext
    ) {
        guard
            let content = content
        else { return }

        // We check if the currentlyPlaying asset is the one we have in this view.
        let isActive = context.assetLocation == content.audioAssetURL

        switch (isActive, context.state) {
        case (true, .playing), (true, .paused):
            playPauseButton.isSelected = context.state == .playing
            durationLabel.text = appearance.formatters.videoDuration.format(context.currentTime)
        case (true, .stopped), (false, _):
            playPauseButton.isSelected = false
            durationLabel.text = appearance.formatters.videoDuration.format(content.duration)
        default:
            break
        }
    }
}
