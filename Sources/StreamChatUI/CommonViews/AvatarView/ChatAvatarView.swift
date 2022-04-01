//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

/// A view that displays the avatar image. By default a circular image.
/// In case you need to render an avatar from a user or channel, you should use
/// the `ChatUserAvatarView` and `ChatChannelAvatarView` components and not this one directly.
open class ChatAvatarView: _Control {
    /// The `UIImageView` instance that shows the avatar image.
    open private(set) var imageView: UIImageView = UIImageView().withoutAutoresizingMaskConstraints
    
    override open var intrinsicContentSize: CGSize {
        imageView.image?.size ?? super.intrinsicContentSize
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = min(imageView.bounds.width, imageView.bounds.height) / 2
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }

    override open func setUpLayout() {
        embed(imageView)
    }
}
