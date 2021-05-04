//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageLinkPreviewView = _ChatMessageLinkPreviewView<NoExtraData>

open class _ChatMessageLinkPreviewView<ExtraData: ExtraDataTypes>: _Control, ThemeProvider {
    public var content: ChatMessageLinkAttachment? { didSet { updateContentIfNeeded() } }

    public private(set) lazy var imagePreview = UIImageView()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var authorBackground: UIView = {
        let view = ShapeView().withoutAutoresizingMaskConstraints
        view.shapeLayer.maskedCorners = .layerMaxXMinYCorner
        view.layer.cornerRadius = 16
        return view
    }()

    public private(set) lazy var authorLabel: UILabel = {
        let label = UILabel().withoutAutoresizingMaskConstraints
        label.font = appearance.fonts.bodyBold
        label.adjustsFontForContentSizeCategory = true
        return label.withBidirectionalLanguagesSupport
    }()

    public private(set) lazy var headlineLabel: UILabel = {
        let label = UILabel().withoutAutoresizingMaskConstraints
        label.font = appearance.fonts.subheadlineBold
        label.adjustsFontForContentSizeCategory = true
        return label.withBidirectionalLanguagesSupport
    }()

    public private(set) lazy var bodyTextView: UITextView = {
        let textView = UITextView().withoutAutoresizingMaskConstraints
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.font = appearance.fonts.subheadline
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.maximumNumberOfLines = 3
        textView.textContainer.lineBreakMode = .byTruncatingTail
        return textView
    }()

    public private(set) lazy var outlineView: UIView = {
        let view = UIView().withoutAutoresizingMaskConstraints
        view.widthAnchor.pin(equalToConstant: 2).isActive = true
        return view
    }()

    public private(set) lazy var textStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [authorLabel, headlineLabel, bodyTextView])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 3
        stack.setCustomSpacing(8, after: authorLabel)
        return stack.withoutAutoresizingMaskConstraints
    }()

    public private(set) lazy var outlineStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [outlineView, textStack])
        stack.axis = .horizontal
        stack.spacing = 6
        return stack.withoutAutoresizingMaskConstraints
    }()

    var authorOnImageConstraint: NSLayoutConstraint?
    var noAuthorWithImageConstraint: NSLayoutConstraint?

    override open func setUpAppearance() {
        super.setUpAppearance()
        authorBackground.backgroundColor = appearance.colorPalette.highlightedAccentBackground1
        backgroundColor = .clear
        imagePreview.contentMode = .scaleAspectFill
        imagePreview.layer.cornerRadius = 8
        imagePreview.clipsToBounds = true
    }

    override open func setUp() {
        super.setUp()

        imagePreview.isUserInteractionEnabled = false
        authorBackground.isUserInteractionEnabled = false
        outlineStack.isUserInteractionEnabled = false
    }

    override open func setUpLayout() {
        super.setUpLayout()
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)

        addSubview(imagePreview)
        addSubview(authorBackground)
        addSubview(outlineStack)

        imagePreview.pin(anchors: [.leading, .top, .trailing], to: self)
        imagePreview.widthAnchor.pin(equalTo: imagePreview.heightAnchor).isActive = true

        outlineStack.pin(anchors: [.leading, .bottom, .trailing], to: layoutMarginsGuide)
        outlineStack.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor).almostRequired.isActive = true

        authorBackground.leadingAnchor.pin(equalTo: leadingAnchor).isActive = true
        authorBackground.bottomAnchor.pin(equalTo: authorLabel.bottomAnchor).isActive = true
        authorBackground.layoutMarginsGuide.topAnchor.pin(equalTo: authorLabel.topAnchor).isActive = true
        authorBackground.layoutMarginsGuide.trailingAnchor.pin(equalTo: authorLabel.trailingAnchor).isActive = true

        authorLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        headlineLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        noAuthorWithImageConstraint = headlineLabel.topAnchor.pin(
            equalToSystemSpacingBelow: imagePreview.bottomAnchor,
            multiplier: 1
        )
        authorOnImageConstraint = authorLabel.firstBaselineAnchor.pin(equalTo: imagePreview.bottomAnchor)
    }

    override open func updateContent() {
        super.updateContent()

        let payload = content?.payload

        let isImageHidden = payload?.previewURL == nil
        let isAuthorHidden = payload?.author == nil

        authorLabel.textColor = tintColor
        outlineView.backgroundColor = tintColor

        imagePreview.loadImage(from: payload?.previewURL)
        imagePreview.isHidden = isImageHidden

        authorLabel.text = payload?.author
        authorLabel.isHidden = isAuthorHidden
        authorBackground.isHidden = isAuthorHidden

        headlineLabel.text = payload?.title
        headlineLabel.isHidden = payload?.title == nil

        bodyTextView.text = payload?.text
        bodyTextView.isHidden = payload?.text == nil

        outlineView.isVisible = isImageHidden

        noAuthorWithImageConstraint?.isActive = !isImageHidden && isAuthorHidden
        authorOnImageConstraint?.isActive = !isImageHidden && !isAuthorHidden
    }

    override open func tintColorDidChange() {
        super.tintColorDidChange()
        updateContentIfNeeded()
    }
}

private class ShapeView: UIView {
    override class var layerClass: AnyClass { CAShapeLayer.self }
    var shapeLayer: CAShapeLayer { layer as! CAShapeLayer }
}
