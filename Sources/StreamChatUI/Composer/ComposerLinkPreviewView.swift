//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that displays the link metadata when typing links in the composer.
open class ComposerLinkPreviewView: _View, ThemeProvider {
    /// The content of the composer link preview view.
    public struct Content {
        public var linkAttachmentPayload: LinkAttachmentPayload

        public init(linkAttachmentPayload: LinkAttachmentPayload) {
            self.linkAttachmentPayload = linkAttachmentPayload
        }
    }

    /// The content of the composer link preview view.
    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// A closure that is triggered whenever the `closeButton` is tapped.
    public var onClose: (() -> Void)?

    /// The main stack view that layouts the image preview, text content and the close button.
    open private(set) lazy var mainStackView = UIStackView()
        .withoutAutoresizingMaskConstraints

    /// An image view that displays the link image preview, or the link icon in case no image found.
    open private(set) lazy var imagePreviewView = UIImageView()
        .withoutAutoresizingMaskConstraints

    /// The stack view that holds the divider, title and description of the link.
    open private(set) lazy var textContainerStackView = UIStackView()
        .withoutAutoresizingMaskConstraints

    /// The divider between the image and the text content.
    open private(set) lazy var divider = UIView()
        .withoutAutoresizingMaskConstraints

    /// The stack view that holds the text content of the link.
    open private(set) lazy var textStackView = UIStackView()
        .withoutAutoresizingMaskConstraints

    /// The label that displays the title of the link.
    open private(set) lazy var titleLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory

    /// The label that displays the description of the link.
    open private(set) lazy var descriptionLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory

    /// The button that closes the link preview view.
    open private(set) lazy var closeButton = UIButton()
        .withoutAutoresizingMaskConstraints

    /// The width of the divider.
    open var dividerWidth: CGFloat {
        2
    }

    /// The minimum height of the divider.
    open var minimumDividerHeight: CGFloat {
        32
    }

    override open func setUp() {
        super.setUp()

        closeButton.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        imagePreviewView.clipsToBounds = true

        titleLabel.font = appearance.fonts.footnoteBold
        descriptionLabel.font = appearance.fonts.footnote

        backgroundColor = appearance.colorPalette.background
        closeButton.setImage(appearance.images.discard, for: .normal)
        closeButton.tintColor = appearance.colorPalette.textLowEmphasis
        divider.backgroundColor = appearance.colorPalette.accentPrimary
    }

    override open func setUpLayout() {
        super.setUpLayout()
        
        mainStackView.axis = .horizontal
        mainStackView.distribution = .fill
        mainStackView.alignment = .center
        mainStackView.spacing = 8

        textContainerStackView.axis = .horizontal
        textContainerStackView.spacing = 6

        textStackView.axis = .vertical
        textStackView.spacing = 3

        embed(mainStackView)
        mainStackView.addArrangedSubview(imagePreviewView)
        mainStackView.addArrangedSubview(textContainerStackView)
        textContainerStackView.addArrangedSubview(divider)
        textContainerStackView.addArrangedSubview(textStackView)
        mainStackView.addArrangedSubview(textContainerStackView)
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(descriptionLabel)
        mainStackView.addArrangedSubview(closeButton)

        NSLayoutConstraint.activate([
            divider.widthAnchor.pin(equalToConstant: dividerWidth),
            divider.heightAnchor.pin(greaterThanOrEqualToConstant: minimumDividerHeight),
            imagePreviewView.widthAnchor.pin(equalToConstant: 35),
            imagePreviewView.heightAnchor.pin(equalToConstant: 35),
            closeButton.widthAnchor.pin(equalToConstant: 28),
            closeButton.heightAnchor.pin(equalToConstant: 28)
        ])
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = self.content else {
            return
        }

        titleLabel.text = content.linkAttachmentPayload.title ?? content.linkAttachmentPayload.originalURL.absoluteString
       
        descriptionLabel.text = content.linkAttachmentPayload.text
        descriptionLabel.isHidden = content.linkAttachmentPayload.text == nil

        if let imageUrl = content.linkAttachmentPayload.previewURL {
            imagePreviewView.contentMode = .scaleAspectFill
            components.imageLoader.loadImage(
                into: imagePreviewView,
                from: imageUrl
            )
        } else {
            imagePreviewView.contentMode = .center
            imagePreviewView.setImage(appearance.images.link)
        }
    }

    @objc func didTapCloseButton() {
        onClose?()
    }
}
