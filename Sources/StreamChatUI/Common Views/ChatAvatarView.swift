//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

open class ChatAvatarView: View {
    // MARK: - Subviews
    
    public let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // MARK: - Overrides
    
    open var defaultIntrinsicContentSize: CGSize?
    override open var intrinsicContentSize: CGSize {
        defaultIntrinsicContentSize ?? imageView.intrinsicContentSize
    }
    
    // MARK: - Layout
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.layer.cornerRadius = imageView.bounds.width / 2
    }
    
    // MARK: - Public

    override public func defaultAppearance() {
        defaultIntrinsicContentSize = .init(width: 40, height: 40)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
    }

    override open func setUpLayout() {
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        embed(imageView)
    }
}
