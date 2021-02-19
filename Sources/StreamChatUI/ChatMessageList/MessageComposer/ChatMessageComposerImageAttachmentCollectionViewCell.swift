//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view cell that displays the image attachment.
internal typealias ChatMessageComposerImageAttachmentCollectionViewCell =
    _ChatMessageComposerImageAttachmentCollectionViewCell<NoExtraData>

/// The view cell that displays the image attachment.
internal class _ChatMessageComposerImageAttachmentCollectionViewCell<ExtraData: ExtraDataTypes>: _CollectionViewCell,
    UIConfigProvider {
    internal class var reuseId: String { String(describing: self) }

    /// A view that displays the image attachment preview.
    internal private(set) lazy var imageAttachmentView = uiConfig
        .messageComposer
        .imageAttachmentCellView.init()
        .withoutAutoresizingMaskConstraints

    override internal func setUpLayout() {
        super.setUpLayout()

        contentView.embed(imageAttachmentView)
    }
}

/// A view that displays the image attachment.
internal typealias ChatMessageComposerImageAttachmentView =
    _ChatMessageComposerImageAttachmentView<NoExtraData>

/// A view that displays the image attachment.
internal class _ChatMessageComposerImageAttachmentView<ExtraData: ExtraDataTypes>: _CollectionViewCell,
    UIConfigProvider {
    /// A closure handler that is called when the discard button of the attachment is clicked
    internal var discardButtonHandler: (() -> Void)?

    /// The image view that displays the image of the attachment.
    internal private(set) lazy var imageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    /// A button to remove the attachment from the collection of attachments.
    internal private(set) lazy var discardButton: UIButton = UIButton()
        .withoutAutoresizingMaskConstraints

    override internal func setUp() {
        super.setUp()

        discardButton.addTarget(self, action: #selector(discard), for: .touchUpInside)
    }

    override internal func defaultAppearance() {
        discardButton.setImage(uiConfig.images.messageComposerDiscardAttachment, for: .normal)

        layer.masksToBounds = true
        layer.cornerRadius = 15

        imageView.contentMode = .scaleAspectFill
    }

    override internal func setUpLayout() {
        contentView.embed(imageView)

        contentView.addSubview(discardButton)

        NSLayoutConstraint.activate([
            discardButton.topAnchor.pin(equalTo: contentView.layoutMarginsGuide.topAnchor),
            discardButton.trailingAnchor.pin(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
        ])
        
        discardButton.setContentHuggingPriority(.required, for: .horizontal)
    }

    @objc func discard() {
        discardButtonHandler?()
    }
}
