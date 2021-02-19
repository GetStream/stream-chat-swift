//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageLinkPreviewView = _ChatMessageLinkPreviewView<NoExtraData>

internal class _ChatMessageLinkPreviewView<ExtraData: ExtraDataTypes>: _Control, UIConfigProvider {
    internal var content: ChatMessageDefaultAttachment? { didSet { updateContentIfNeeded() } }

    internal private(set) lazy var imagePreview = uiConfig
        .messageList
        .messageContentSubviews
        .attachmentSubviews
        .imageGalleryItem
        .init()
        .withoutAutoresizingMaskConstraints

    internal private(set) lazy var authorBackground: UIView = {
        let view = ShapeView().withoutAutoresizingMaskConstraints
        view.shapeLayer.maskedCorners = .layerMaxXMinYCorner
        view.layer.cornerRadius = 16
        return view
    }()

    internal private(set) lazy var authorLabel: UILabel = {
        let label = UILabel().withoutAutoresizingMaskConstraints
        label.font = uiConfig.fonts.bodyBold
        label.adjustsFontForContentSizeCategory = true
        return label.withBidirectionalLanguagesSupport
    }()

    internal private(set) lazy var headlineLabel: UILabel = {
        let label = UILabel().withoutAutoresizingMaskConstraints
        label.font = uiConfig.fonts.subheadlineBold
        label.adjustsFontForContentSizeCategory = true
        return label.withBidirectionalLanguagesSupport
    }()

    internal private(set) lazy var bodyTextView: UITextView = {
        let textView = UITextView().withoutAutoresizingMaskConstraints
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.font = uiConfig.fonts.subheadline
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.maximumNumberOfLines = 3
        textView.textContainer.lineBreakMode = .byTruncatingTail
        return textView
    }()

    internal private(set) lazy var outlineView: UIView = {
        let view = UIView().withoutAutoresizingMaskConstraints
        view.widthAnchor.pin(equalToConstant: 2).isActive = true
        return view
    }()

    internal private(set) lazy var textStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [authorLabel, headlineLabel, bodyTextView])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 3
        stack.setCustomSpacing(8, after: authorLabel)
        return stack.withoutAutoresizingMaskConstraints
    }()

    internal private(set) lazy var outlineStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [outlineView, textStack])
        stack.axis = .horizontal
        stack.spacing = 6
        return stack.withoutAutoresizingMaskConstraints
    }()

    var authorOnImageConstraint: NSLayoutConstraint?
    var noAuthorWithImageConstraint: NSLayoutConstraint?

    override internal func defaultAppearance() {
        super.defaultAppearance()
        authorBackground.backgroundColor = uiConfig.colorPalette.highlightedAccentBackground1
        backgroundColor = .clear
        imagePreview.layer.cornerRadius = 8
        imagePreview.clipsToBounds = true
    }

    override internal func setUp() {
        super.setUp()

        imagePreview.isUserInteractionEnabled = false
        authorBackground.isUserInteractionEnabled = false
        outlineStack.isUserInteractionEnabled = false
    }

    override internal func setUpLayout() {
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

    override internal func updateContent() {
        super.updateContent()

        let isImageHidden = content?.imagePreviewURL == nil
        let isAuthorHidden = content?.author == nil

        authorLabel.textColor = tintColor
        outlineView.backgroundColor = tintColor

        imagePreview.content = content.map {
            .init(
                attachment: $0,
                didTapOnAttachment: {},
                didTapOnAttachmentAction: { _ in }
            )
        }

        imagePreview.isHidden = isImageHidden

        authorLabel.text = content?.author
        authorLabel.isHidden = isAuthorHidden
        authorBackground.isHidden = isAuthorHidden

        headlineLabel.text = content?.title
        headlineLabel.isHidden = content?.title == nil

        bodyTextView.text = content?.text
        bodyTextView.isHidden = content?.text == nil

        outlineView.isVisible = isImageHidden

        noAuthorWithImageConstraint?.isActive = !isImageHidden && isAuthorHidden
        authorOnImageConstraint?.isActive = !isImageHidden && !isAuthorHidden
    }

    override internal func tintColorDidChange() {
        super.tintColorDidChange()
        updateContentIfNeeded()
    }
}

private class ShapeView: UIView {
    override class var layerClass: AnyClass { CAShapeLayer.self }
    var shapeLayer: CAShapeLayer { layer as! CAShapeLayer }
}
