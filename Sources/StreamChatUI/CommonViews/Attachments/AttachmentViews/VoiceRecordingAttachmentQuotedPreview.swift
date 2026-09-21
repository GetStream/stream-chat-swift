//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that displays the VoiceRecording attachment in the quoted flow.
open class VoiceRecordingAttachmentQuotedPreview: _View, AppearanceProvider, ComponentsProvider {
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
        didSet { updateContentIfNeeded() }
    }

    // MARK: - UI Components

    public lazy var previewView: VoiceRecordingAttachmentComposerPreview = components
        .voiceRecordingAttachmentComposerPreview
        .init()
        .withoutAutoresizingMaskConstraints

    /// The minimum scale factor applied to the labels when the available width is not
    /// enough to render them at their default font size.
    open var minimumFontScaleFactor: CGFloat = 0.6

    // MARK: - UI Lifecycle

    override open func setUpAppearance() {
        super.setUpAppearance()

        previewView.fileNameLabel.font = appearance.fonts.subheadlineBold
        previewView.fileNameLabel.lineBreakMode = .byTruncatingTail
        previewView.fileNameLabel.adjustsFontSizeToFitWidth = true
        previewView.fileNameLabel.minimumScaleFactor = minimumFontScaleFactor

        previewView.durationLabel.font = .monospacedDigitSystemFont(
            ofSize: appearance.fonts.caption1.pointSize,
            weight: .regular
        )
        previewView.durationLabel.adjustsFontSizeToFitWidth = true
        previewView.durationLabel.minimumScaleFactor = minimumFontScaleFactor
    }

    override open func setUpLayout() {
        embed(previewView, insets: .zero)

        previewView.container.removeFromSuperview()
        previewView.embed(
            previewView.container,
            insets: .init(top: 8, leading: 8, bottom: 8, trailing: 8)
        )

        previewView.container.spacing = 4

        previewView.playPauseButton.removeFromSuperview()

        previewView.fileNameLabel.setContentCompressionResistancePriority(.streamAlmostRequire, for: .horizontal)
        previewView.durationLabel.setContentCompressionResistancePriority(.streamAlmostRequire, for: .horizontal)
    }

    override open func updateContent() {
        super.updateContent()
        previewView.content = content.map {
            VoiceRecordingAttachmentComposerPreview.Content(
                title: $0.title,
                size: $0.size,
                duration: $0.duration,
                audioAssetURL: $0.audioAssetURL
            )
        }
    }
}
