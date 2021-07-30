//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that displays image attachment preview in composer.
public typealias ImageAttachmentComposerPreview = _ImageAttachmentComposerPreview<NoExtraData>

/// A view that displays image attachment preview in composer.
open class _ImageAttachmentComposerPreview: _View, ThemeProvider {
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
        
        imageView.loadImage(from: content, components: components)
    }
}
