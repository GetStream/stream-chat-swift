//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageLinkPreviewView = _ChatMessageLinkPreviewView<NoExtraData>

open class _ChatMessageLinkPreviewView<ExtraData: ExtraDataTypes>: _Control, ThemeProvider {
    public var content: ChatMessageLinkAttachment? { didSet { updateContentIfNeeded() } }

    /// Image view showing link's preview image.
    public private(set) lazy var imagePreview = UIImageView()
        .withoutAutoresizingMaskConstraints

    /// Background for `authorLabel`.
    public private(set) lazy var authorBackground = UIView()
        .withoutAutoresizingMaskConstraints

    /// Label showing author of the link.
    public private(set) lazy var authorLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
    
    /// Label showing `title`.
    public private(set) lazy var titleLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport

    /// Text view for showing `content`'s `text`.
    public private(set) lazy var bodyTextView = UITextView()
        .withoutAutoresizingMaskConstraints

    /// `ContainerStackView` for labels with text metadata.
    public private(set) lazy var textStack = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// Constraint for `authorLabel`.
    open var authorOnImageConstraint: NSLayoutConstraint?

    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = .clear
        imagePreview.contentMode = .scaleAspectFill
        imagePreview.layer.cornerRadius = 8
        imagePreview.clipsToBounds = true
        
        authorBackground.layer.cornerRadius = 15
        authorBackground.layer.maskedCorners = [.layerMaxXMinYCorner]
        authorBackground.clipsToBounds = true
        authorBackground.backgroundColor = appearance.colorPalette.highlightedAccentBackground1
        
        authorLabel.font = appearance.fonts.bodyBold
        authorLabel.adjustsFontForContentSizeCategory = true
        
        titleLabel.font = appearance.fonts.subheadlineBold
        titleLabel.adjustsFontForContentSizeCategory = true
        
        bodyTextView.backgroundColor = .clear
        bodyTextView.font = appearance.fonts.subheadline
        bodyTextView.adjustsFontForContentSizeCategory = true
        bodyTextView.textContainerInset = .zero
        bodyTextView.textContainer.lineFragmentPadding = 0
        bodyTextView.textContainer.maximumNumberOfLines = 3
        bodyTextView.textContainer.lineBreakMode = .byTruncatingTail
    }
    
    override open func setUp() {
        super.setUp()

        imagePreview.isUserInteractionEnabled = false
        authorBackground.isUserInteractionEnabled = false
        textStack.isUserInteractionEnabled = false
        
        bodyTextView.isEditable = false
        bodyTextView.isScrollEnabled = false
    }

    override open func setUpLayout() {
        super.setUpLayout()

        addSubview(imagePreview)
        addSubview(authorBackground)
        addSubview(textStack)
        
        imagePreview.pin(anchors: [.leading, .top, .trailing], to: self)
        imagePreview.widthAnchor.pin(equalTo: imagePreview.heightAnchor, multiplier: 2).isActive = true
        
        textStack.addArrangedSubviews([titleLabel, bodyTextView])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 3
        textStack.topAnchor.pin(equalToSystemSpacingBelow: imagePreview.bottomAnchor).isActive = true
        textStack.pin(anchors: [.leading, .bottom, .trailing], to: layoutMarginsGuide)

        authorBackground.leadingAnchor.pin(equalTo: imagePreview.leadingAnchor).isActive = true
        authorBackground.bottomAnchor.pin(equalTo: imagePreview.bottomAnchor).isActive = true
        imagePreview.trailingAnchor.pin(greaterThanOrEqualToSystemSpacingAfter: authorBackground.trailingAnchor).isActive = true
        authorBackground.embed(authorLabel, insets: NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 4, trailing: 12))
    
        authorLabel.setContentCompressionResistancePriority(.streamRequire, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.streamRequire, for: .vertical)
        bodyTextView.setContentHuggingPriority(.streamLow, for: .horizontal)
    }

    override open func updateContent() {
        super.updateContent()

        let payload = content?.payload

        let isImageHidden = payload?.previewURL == nil
        let isAuthorHidden = payload?.author == nil

        authorLabel.textColor = tintColor

        imagePreview.loadImage(from: payload?.previewURL, components: components)
        imagePreview.isHidden = isImageHidden

        authorLabel.text = payload?.author
        authorLabel.isHidden = isAuthorHidden
        authorBackground.isHidden = isAuthorHidden

        titleLabel.text = payload?.title
        titleLabel.isHidden = payload?.title == nil

        bodyTextView.text = payload?.text
        bodyTextView.isHidden = payload?.text == nil

        authorOnImageConstraint?.isActive = !isImageHidden && !isAuthorHidden
    }

    override open func tintColorDidChange() {
        super.tintColorDidChange()
        updateContentIfNeeded()
    }
}
