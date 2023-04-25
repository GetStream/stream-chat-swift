//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that displays the file attachment.
open class VoiceRecordingAttachmentComposerPreview: _View, AppearanceProvider, ComponentsProvider, AudioPlayingDelegate {
    open var height: CGFloat = 54

    public struct Content {
        /// The title of the attachment.
        var title: String
        /// The size of the attachment.
        var size: Int64

        var duration: TimeInterval

        var audioAssetURL: URL

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

    public var audioPlayer: AudioPlaying? {
        didSet { audioPlayer?.connect(delegate: self) }
    }

    public var indexProvider: (() -> Int)?

    public private(set) lazy var container: UIStackView =
        .init()
            .withoutAutoresizingMaskConstraints

    public private(set) lazy var playPauseButton: PlayPauseButton =
        .init()
            .withoutAutoresizingMaskConstraints

    public private(set) lazy var fileNameLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory

    public private(set) lazy var durationLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory

    public private(set) lazy var fileNameAndSizeStack: ContainerStackView = {
        let stack = ContainerStackView(arrangedSubviews: [fileNameLabel, durationLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 3
        return stack
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "fileNameAndSizeStack")
    }()

    /// The image view that displays the file icon of the attachment.
    public private(set) lazy var fileIconImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

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

//        playPauseButton.setImage(appearance.images.play, for: .normal)
//        playPauseButton.setImage(appearance.images.pause, for: .selected)
//        playPauseButton.backgroundColor = .yellow

        fileIconImageView.contentMode = .center
        fileIconImageView.image = appearance.images.fileAac

        durationLabel.textColor = appearance.colorPalette.textLowEmphasis
        durationLabel.font = .monospacedDigitSystemFont(ofSize: appearance.fonts.footnote.pointSize, weight: .bold)

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
        container.addArrangedSubview(fileNameAndSizeStack)
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

    public func audioPlayer(
        _ audioPlayer: AudioPlaying,
        didUpdateContext context: AudioPlaybackContext
    ) {
        guard
            let content = content
        else { return }

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
