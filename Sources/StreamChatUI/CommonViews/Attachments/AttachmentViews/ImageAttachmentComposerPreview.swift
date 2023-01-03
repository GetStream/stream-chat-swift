//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that displays image attachment preview in composer.
open class ImageAttachmentComposerPreview: _View, ThemeProvider {
    open var width: CGFloat = 100
    open var height: CGFloat = 100

    /// Local URL of the image preview to show.
    public var content: URL? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The image view that displays the image of the attachment.
    open private(set) lazy var imageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    override open func setUpAppearance() {
        super.setUpAppearance()

        layer.masksToBounds = true
        layer.cornerRadius = 11

        imageView.contentMode = .scaleAspectFill
    }

    override open func setUpLayout() {
        super.setUpLayout()

        embed(imageView)

        widthAnchor.pin(equalToConstant: width).isActive = true
        heightAnchor.pin(equalToConstant: height).isActive = true
    }

    override open func updateContent() {
        super.updateContent()

        let size = CGSize(width: width, height: height)
        components.imageLoader.loadImage(
            into: imageView,
            from: content,
            with: ImageLoaderOptions(resize: ImageResize(size))
        )
    }
}
