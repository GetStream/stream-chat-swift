//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that displays the image attachment.
open class ChatImageAttachmentView: _View, AppearanceProvider {
    /// A closure handler that is called when the discard button of the attachment is clicked
    open var discardButtonHandler: (() -> Void)?

    /// The image view that displays the image of the attachment.
    open private(set) lazy var imageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    /// A button to remove the attachment from the collection of attachments.
    open private(set) lazy var discardButton: UIButton = UIButton()
        .withoutAutoresizingMaskConstraints

    override open func setUp() {
        super.setUp()

        discardButton.addTarget(self, action: #selector(discard), for: .touchUpInside)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        discardButton.setImage(appearance.images.messageComposerDiscardAttachment, for: .normal)

        layer.masksToBounds = true
        layer.cornerRadius = 15

        imageView.contentMode = .scaleAspectFill
    }

    override open func setUpLayout() {
        embed(imageView)

        addSubview(discardButton)

        NSLayoutConstraint.activate([
            discardButton.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor),
            discardButton.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor)
        ])

        discardButton.setContentHuggingPriority(.required, for: .horizontal)
    }

    @objc func discard() {
        discardButtonHandler?()
    }
}
