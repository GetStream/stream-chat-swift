//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

open class AvatarView: View {
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
    }
    
    override open func setUpAppearance() {
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
    }
    
    override open func setUpLayout() {
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        embed(imageView)
    }
}
