//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

/// A view that displays the avatar image. By default a circular image.
internal class ChatAvatarView: _View {
    /// The `UIImageView` instance that shows the avatar image.
    internal private(set) var imageView: UIImageView = UIImageView().withoutAutoresizingMaskConstraints
    
    override internal var intrinsicContentSize: CGSize {
        imageView.image?.size ?? super.intrinsicContentSize
    }
    
    override internal func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = min(imageView.bounds.width, imageView.bounds.height) / 2
    }

    override internal func defaultAppearance() {
        super.defaultAppearance()
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }

    override internal func setUpLayout() {
        embed(imageView)
    }
}
