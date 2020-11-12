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
        embed(imageView)
        widthAnchor.constraint(equalTo: heightAnchor, multiplier: 1).isActive = true
    }
}
