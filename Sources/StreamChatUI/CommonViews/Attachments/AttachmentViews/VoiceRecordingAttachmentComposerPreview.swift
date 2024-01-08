//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
    open var height: CGFloat = 60

    /// The audioPlayer that will be used for the recording's playback.
    ///
    /// - Note: Upon set, the view will subscribe to receive playback events from the audioPlayer.
    open var audioPlayer: AudioPlaying? {
        didSet { audioPlayer?.subscribe(self) }
    }

    /// It provides the index of the recording in the containing message's attachment array.
    open var indexProvider: (() -> Int)?

    /// The main container where all UI components will be added into.
    open private(set) lazy var container: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    /// A button that can be used to control the playback of the VoiceRecording.
    open private(set) lazy var playPauseButton: PlayPauseButton = .init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "actionButton")

    /// The container that the fileNameLabel and the durationLabel will be added into.
    open private(set) lazy var centerContainerStackView: ContainerStackView = .init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "centerContainerStackView")

    /// A label that shows the name of the VoiceRecording.
    open private(set) lazy var fileNameLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withAccessibilityIdentifier(identifier: "fileNameLabel")

    /// A label that shows the VoiceRecording's duration or the playback's currentTime when playback
    /// is active.
    open private(set) lazy var durationLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withAccessibilityIdentifier(identifier: "durationLabel")

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

        heightAnchor.pin(lessThanOrEqualToConstant: height).isActive = true
        embed(container, insets: .init(top: 4, leading: 8, bottom: 4, trailing: 34))

        container.axis = .horizontal
        container.spacing = 8
        container.alignment = .center

        centerContainerStackView.addArrangedSubviews([
            fileNameLabel,
            durationLabel
        ])
        centerContainerStackView.axis = .vertical
        centerContainerStackView.alignment = .leading
        centerContainerStackView.spacing = 3

        container.addArrangedSubview(playPauseButton)
        container.addArrangedSubview(centerContainerStackView)
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
