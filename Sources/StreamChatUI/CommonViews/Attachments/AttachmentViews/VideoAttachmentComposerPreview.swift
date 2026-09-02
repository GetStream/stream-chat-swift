//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import UIKit

/// A view that displays the video attachment preview in composer.
open class VideoAttachmentComposerPreview: _View, ThemeProvider {
    open var width: CGFloat = 100
    open var height: CGFloat = 100

    /// Local URL of the video to show a preview for.
    public var content: URL? {
        didSet { updateContentIfNeeded() }
    }

    /// A thumbnail provided by the photos picker. When set, it is shown immediately
    /// instead of generating a preview from the video file.
    public var previewImage: UIImage? {
        didSet { updateContentIfNeeded() }
    }

    /// Whether the video is still being processed (for example compressed) before it can be sent.
    public var isProcessing: Bool = false {
        didSet {
            guard isProcessing != oldValue else { return }
            updateProcessingState()
        }
    }

    /// The view that displays the video preview.
    open private(set) lazy var previewImageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    /// The view that displays camera icon.
    open private(set) lazy var cameraIconView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    /// The view that displays video duration.
    open private(set) lazy var videoDurationLabel: UILabel = UILabel()
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints

    /// The view that renders the gradient behind camera and video duration.
    open private(set) lazy var gradientView = components
        .gradientView.init()
        .withoutAutoresizingMaskConstraints

    /// The view that displays a loading indicator while the video preview is loading.
    open private(set) lazy var loadingIndicator = components
        .loadingIndicator.init()
        .withoutAutoresizingMaskConstraints

    /// Dims the preview while the attachment is being processed.
    open private(set) lazy var processingOverlayView: UIView = UIView()
        .withoutAutoresizingMaskConstraints

    /// The view that displays a loading indicator while the video is being processed.
    open private(set) lazy var processingIndicator = components
        .loadingIndicator.init()
        .withoutAutoresizingMaskConstraints

    override open func setUpAppearance() {
        super.setUpAppearance()

        previewImageView.contentMode = .scaleAspectFill
        if #available(iOS 17.0, *) {
            previewImageView.preferredImageDynamicRange = .standard
        }

        cameraIconView.image = appearance.images.camera
        cameraIconView.contentMode = .scaleAspectFit
        cameraIconView.tintColor = appearance.colorPalette.textOnAccent

        videoDurationLabel.textColor = appearance.colorPalette.textOnAccent
        videoDurationLabel.font = appearance.fonts.footnoteBold

        gradientView.content = .init(
            direction: .vertical,
            colors: [.clear, UIColor.black.withAlphaComponent(0.7)]
        )

        layer.cornerRadius = 12
        layer.masksToBounds = true

        processingOverlayView.isOpaque = false
        processingOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        processingOverlayView.isAccessibilityElement = true
        processingOverlayView.accessibilityLabel = L10n.Composer.VideoCompression.compressing
        processingOverlayView.accessibilityTraits = .updatesFrequently
    }

    override open func setUpLayout() {
        super.setUpLayout()

        addSubview(previewImageView)
        previewImageView.pin(to: self)

        addSubview(loadingIndicator)
        loadingIndicator.pin(anchors: [.centerX, .centerY], to: self)
        loadingIndicator.pin(anchors: [.height], to: 16)
        loadingIndicator.isHidden = true

        addSubview(gradientView)
        gradientView.pin(anchors: [.leading, .bottom, .trailing], to: self)
        gradientView.pin(anchors: [.height], to: height / 3)

        gradientView.addSubview(cameraIconView)
        gradientView.addSubview(videoDurationLabel)
        cameraIconView.pin(anchors: [.leading, .centerY], to: gradientView.layoutMarginsGuide)
        videoDurationLabel.pin(anchors: [.trailing, .centerY], to: gradientView.layoutMarginsGuide)

        addSubview(processingOverlayView)
        processingOverlayView.pin(to: self)
        processingOverlayView.addSubview(processingIndicator)
        processingIndicator.pin(anchors: [.centerX, .centerY], to: processingOverlayView)
        processingIndicator.pin(anchors: [.height], to: 28)
        updateProcessingState()

        pin(anchors: [.width], to: width)
        pin(anchors: [.height], to: height)
    }

    override open func updateContent() {
        super.updateContent()

        loadingIndicator.isHidden = previewImage != nil
        previewImageView.image = previewImage
        videoDurationLabel.text = nil

        if let url = content {
            if previewImage == nil {
                components.mediaLoader.loadVideoPreview(at: url) { [weak self] in
                    self?.loadingIndicator.isHidden = true
                    switch $0 {
                    case let .success(preview):
                        self?.previewImageView.image = preview.image
                    case .failure:
                        self?.previewImageView.image = nil
                    }
                }
            }
            components.mediaLoader.loadVideoAsset(at: url) { [weak self] result in
                if case let .success(loaded) = result {
                    self?.videoDurationLabel.text = self?.appearance.formatters.videoDuration.format(
                        loaded.asset.duration.seconds
                    )
                }
            }
        }
        updateProcessingState()
    }

    /// Shows or hides the processing overlay in the middle of the preview.
    open func updateProcessingState() {
        processingOverlayView.isHidden = !isProcessing
        processingIndicator.isHidden = !isProcessing
    }
}
