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
        
        authorBackground.layer.cornerRadius = 16
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
        
        var constraints: [NSLayoutConstraint] = []

        imagePreview.pin(anchors: [.leading, .top, .trailing], to: layoutMarginsGuide)
        constraints.append(
            imagePreview.widthAnchor.pin(equalTo: imagePreview.heightAnchor)
        )

        textStack.addArrangedSubviews([
            authorLabel,
            titleLabel,
            bodyTextView
        ])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 3
        textStack.pin(anchors: [.leading, .bottom, .trailing], to: layoutMarginsGuide)
        
        bodyTextView.setContentHuggingPriority(.streamLow, for: .horizontal)

        constraints += [
            authorBackground.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
            authorBackground.bottomAnchor.pin(equalTo: authorLabel.bottomAnchor),
            authorBackground.layoutMarginsGuide.topAnchor.pin(equalTo: authorLabel.topAnchor),
            authorBackground.layoutMarginsGuide.trailingAnchor.pin(equalTo: authorLabel.trailingAnchor)
        ]

        titleLabel.setContentCompressionResistancePriority(.streamRequire, for: .vertical)
        authorLabel.setContentCompressionResistancePriority(.streamRequire, for: .vertical)
        constraints.append(
            titleLabel.topAnchor.pin(equalToSystemSpacingBelow: imagePreview.bottomAnchor)
                .almostRequired
        )
        authorOnImageConstraint = authorLabel.firstBaselineAnchor.pin(equalTo: imagePreview.bottomAnchor)
        
        NSLayoutConstraint.activate(constraints)
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
