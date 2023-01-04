//
// Copyright © 2023 Stream.io Inc. All rights reserved.
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

    override open func setUpAppearance() {
        super.setUpAppearance()

        previewImageView.contentMode = .scaleAspectFill

        cameraIconView.image = appearance.images.camera
        cameraIconView.contentMode = .scaleAspectFit
        cameraIconView.tintColor = appearance.colorPalette.staticColorText

        videoDurationLabel.textColor = appearance.colorPalette.staticColorText
        videoDurationLabel.font = appearance.fonts.footnoteBold

        gradientView.content = .init(
            direction: .vertical,
            colors: [.clear, UIColor.black.withAlphaComponent(0.7)]
        )

        layer.cornerRadius = 12
        layer.masksToBounds = true
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

        pin(anchors: [.width], to: width)
        pin(anchors: [.height], to: height)
    }

    override open func updateContent() {
        super.updateContent()

        loadingIndicator.isHidden = false
        previewImageView.image = nil
        videoDurationLabel.text = nil

        if let url = content {
            components.videoLoader.loadPreviewForVideo(at: url) { [weak self] in
                self?.loadingIndicator.isHidden = true
                switch $0 {
                case let .success(preview):
                    self?.previewImageView.image = preview
                case .failure:
                    self?.previewImageView.image = nil
                }
            }
            videoDurationLabel.text = appearance.formatters.videoDuration.format(
                components.videoLoader.videoAsset(at: url).duration.seconds
            )
        }
    }
}
