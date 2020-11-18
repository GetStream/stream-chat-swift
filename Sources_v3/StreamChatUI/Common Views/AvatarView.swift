//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

open class AvatarView: UIView {
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
    
    // MARK: - Init
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        applyDefaultAppearance()
        setupLayout()
        setupAppearance()
    }
    
    // MARK: - Layout
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = bounds.width / 2
    }
    
    // MARK: - Public
    
    open func setupAppearance() {
        imageView.contentMode = .scaleAspectFit
        layer.masksToBounds = true
    }
    
    open func setupLayout() {
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        embed(imageView)
    }
}

// MARK: - AppearanceSetting

extension AvatarView: AppearanceSetting {
    public class func initialAppearanceSetup(_ view: AvatarView) {
        view.defaultIntrinsicContentSize = .init(width: 40, height: 40)
    }
}
