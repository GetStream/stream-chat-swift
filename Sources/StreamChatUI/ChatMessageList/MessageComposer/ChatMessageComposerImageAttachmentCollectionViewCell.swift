//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view cell that displays the image attachment.
public typealias ChatMessageComposerImageAttachmentCollectionViewCell =
    _ChatMessageComposerImageAttachmentCollectionViewCell<NoExtraData>

/// The view cell that displays the image attachment.
open class _ChatMessageComposerImageAttachmentCollectionViewCell<ExtraData: ExtraDataTypes>: _CollectionViewCell,
    UIConfigProvider {
    open class var reuseId: String { String(describing: self) }

    public private(set) lazy var imageAttachmentView = uiConfig
        .messageComposer
        .imageAttachmentCellView.init()
        .withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        super.setUpLayout()

        contentView.embed(imageAttachmentView)
    }
}

/// A view that displays the image attachment.
public typealias ChatMessageComposerImageAttachmentView =
    _ChatMessageComposerImageAttachmentView<NoExtraData>

/// A view that displays the image attachment.
open class _ChatMessageComposerImageAttachmentView<ExtraData: ExtraDataTypes>: _CollectionViewCell,
    UIConfigProvider {
    /// A closure handler that is called when the discard button of the attachment is clicked
    public var discardButtonHandler: (() -> Void)?

    /// The image view that displays the image of the attachment.
    public private(set) lazy var imageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    /// A button to remove the attachment from the collection of attachments.
    public private(set) lazy var discardButton: UIButton = UIButton()
        .withoutAutoresizingMaskConstraints

    /// The `ChatMessageComposerImageAttachmentView` layout constraints.
    public struct Layout {
        public var discardButtonConstraints: [NSLayoutConstraint] = []
    }

    /// The `ChatMessageComposerImageAttachmentView` layout constraints.
    public private(set) var layout = Layout()

    override open func setUp() {
        super.setUp()

        discardButton.addTarget(self, action: #selector(discard), for: .touchUpInside)
    }

    override public func defaultAppearance() {
        discardButton.setImage(uiConfig.images.messageComposerDiscardAttachment, for: .normal)

        layer.masksToBounds = true
        layer.cornerRadius = 15

        imageView.contentMode = .scaleAspectFill
    }

    override open func setUpLayout() {
        contentView.embed(imageView)

        contentView.addSubview(discardButton)

        layout.discardButtonConstraints = [
            discardButton.topAnchor.pin(equalTo: contentView.layoutMarginsGuide.topAnchor),
            discardButton.trailingAnchor.pin(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            discardButton.leadingAnchor.pin(
                greaterThanOrEqualToSystemSpacingAfter: contentView.layoutMarginsGuide.leadingAnchor,
                multiplier: 2
            )
        ]
        
        NSLayoutConstraint.activate(layout.discardButtonConstraints)
    }

    @objc func discard() {
        discardButtonHandler?()
    }
}
