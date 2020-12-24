//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageLinkPreviewView<ExtraData: ExtraDataTypes>: Control, UIConfigProvider {
    public var content: _ChatMessageAttachment<ExtraData>? { didSet { updateContentIfNeeded() } }

    public private(set) lazy var imagePreview: ChatMessageImageGallery<ExtraData>.ImagePreview = uiConfig
        .messageList
        .messageContentSubviews
        .attachmentSubviews
        .imageGalleryItem
        .init()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var authorBackground: UIView = {
        let view = ShapeView().withoutAutoresizingMaskConstraints
        view.shapeLayer.maskedCorners = .layerMaxXMinYCorner
        view.layer.cornerRadius = 16
        return view
    }()

    public private(set) lazy var authorLabel: UILabel = {
        let label = UILabel().withoutAutoresizingMaskConstraints
        label.font = .preferredFont(forTextStyle: .title3)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    public private(set) lazy var headlineLabel: UILabel = {
        let label = UILabel().withoutAutoresizingMaskConstraints
        label.font = UIFont.preferredFont(forTextStyle: .subheadline).bold
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    public private(set) lazy var bodyTextView: UITextView = {
        let textView = UITextView().withoutAutoresizingMaskConstraints
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.font = .preferredFont(forTextStyle: .footnote)
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.maximumNumberOfLines = 3
        textView.textContainer.lineBreakMode = .byTruncatingTail
        return textView
    }()

    public private(set) lazy var outlineView: UIView = {
        let view = UIView().withoutAutoresizingMaskConstraints
        view.widthAnchor.constraint(equalToConstant: 2).isActive = true
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

    override public func defaultAppearance() {
        super.defaultAppearance()
        authorBackground.backgroundColor = uiConfig.colorPalette.linkMessageBubbleBackground
        backgroundColor = .clear
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
        imagePreview.widthAnchor.constraint(equalTo: imagePreview.heightAnchor).isActive = true

        outlineStack.pin(anchors: [.leading, .bottom, .trailing], to: layoutMarginsGuide)
        outlineStack.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).with(priority: .required - 1).isActive = true

        authorBackground.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        authorBackground.bottomAnchor.constraint(equalTo: authorLabel.bottomAnchor).isActive = true
        authorBackground.layoutMarginsGuide.topAnchor.constraint(equalTo: authorLabel.topAnchor).isActive = true
        authorBackground.layoutMarginsGuide.trailingAnchor.constraint(equalTo: authorLabel.trailingAnchor).isActive = true

        authorLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        headlineLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        noAuthorWithImageConstraint = headlineLabel.topAnchor.constraint(
            equalToSystemSpacingBelow: imagePreview.bottomAnchor,
            multiplier: 1
        )
        authorOnImageConstraint = authorLabel.firstBaselineAnchor.constraint(equalTo: imagePreview.bottomAnchor)
    }

    override open func updateContent() {
        super.updateContent()

        let isImageHidden = content?.imagePreviewURL == nil
        let isAuthorHidden = content?.author == nil

        authorLabel.textColor = tintColor
        outlineView.backgroundColor = tintColor

        imagePreview.content = content.map { AttachmentListViewData<ExtraData>.ItemData(attachment: $0, didTapOnAttachment: {}) }

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

    override open func tintColorDidChange() {
        super.tintColorDidChange()
        updateContentIfNeeded()
    }
}

private class ShapeView: UIView {
    override class var layerClass: AnyClass { CAShapeLayer.self }
    var shapeLayer: CAShapeLayer { layer as! CAShapeLayer }
}
