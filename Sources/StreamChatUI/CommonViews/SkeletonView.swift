//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

/// A view used to cover views with shimmer while they are loading.
open class SkeletonView: UIView {
    
    /// Superview used as mask to have animation consistent across whole parent view.
    public private(set) weak var maskingView: UIView?
    
    /// A view which will be covered with the Skeleton layer.
    public private(set) weak var view: UIView?
    
    /// The layer which will be used to cover given view.
    public private(set) lazy var skeletonLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        layer.addSublayer(gradientLayer)
        return gradientLayer
    }()
    
    override open var bounds: CGRect {
        didSet { setupLayers() }
    }
    
    /// Setup layers with given properties.
    open func setupLayers() {
        guard let maskingView = maskingView else { return }
        
        layer.backgroundColor = Appearance.default.colorPalette.textLowEmphasis.cgColor
        layer.cornerRadius = bounds.height / 2
        layer.masksToBounds = true
        
        if let label = view as? UILabel {
            // There are some overlaps when using corner-radius, let's not show mock text anyway
            label.textColor = .clear
        }
        skeletonLayer.frame = maskingView.layer.bounds
        
        skeletonLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        skeletonLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        skeletonLayer.locations = [-1.0, -0.5, 0.0]

        skeletonLayer.colors = [
            Appearance.default.colorPalette.background.cgColor,
            Appearance.default.colorPalette.overlayBackground.cgColor,
            Appearance.default.colorPalette.background.cgColor
        ]
    }
        
    // MARK: - Setup
    
    /// Sets up view which is needed to cover together with superview.
    /// Also adds layer and sets up animation
    /// - Parameters:
    ///   - view: View to be covered by shimmer
    ///   - maskingView: Superview in which the view is contained to be masked and have consistent animation.
    open func setup(with view: UIView?, maskingView: UIView?) {
        self.view = view
        self.maskingView = maskingView
        setupLayers()
        setupAnimation()
    }
    
    /// Creates and adds animation for the shimmer.
    open func setupAnimation() {
        guard skeletonLayer.animation(forKey: "SkeletonAnimation") == nil else { return }
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 1.9]
        
        animation.duration = 1.5
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        animation.isRemovedOnCompletion = false
        animation.repeatCount = .infinity
        
        skeletonLayer.add(animation, forKey: "SkeletonAnimation")
    }
}
