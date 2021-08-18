//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

/// Object for animating transition of an image.
open class ZoomAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    /// `UIImageView` for view controller initiating the transition.
    public weak var fromImageView: UIImageView?
    /// `UIImageView` for view controller being transitioned to.
    public weak var toImageView: UIImageView?
    /// Snapshot for view controller being transitioned to.
    public weak var toVCSnapshot: UIView?
    /// Snapshot for view controller initiating the transition.
    public weak var fromVCSnapshot: UIView?
    /// Container view for `transitionImageView`
    public weak var containerTransitionImageView: UIView?
    /// `UIImageView` to be animated between the view controllers.
    public weak var transitionImageView: UIImageView?
    /// Indicates whether the current animation is for presenting or dismissing.
    public var isPresenting: Bool = true
    
    open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.25
    }
    
    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isPresenting {
            animateZoomInTransition(using: transitionContext)
        } else {
            animateZoomOutTransition(using: transitionContext)
        }
    }
    
    /// Animate transition for presenting.
    open func animateZoomInTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toVC = transitionContext.viewController(forKey: .to),
            let fromVC = transitionContext.viewController(forKey: .from),
            let fromImageView = self.fromImageView
        else { return }

        transitionContext.containerView.addSubview(toVC.view)
        
        let fromVCSnapshot = fromVC.view.snapshotView(afterScreenUpdates: true)
        if let fromVCSnapshot = fromVCSnapshot {
            transitionContext.containerView.addSubview(fromVCSnapshot)
            fromVCSnapshot.frame = fromVC.view.frame
            fromVC.view.isHidden = true
        }
        self.fromVCSnapshot = fromVCSnapshot
        
        let toVCSnapshot = toVC.view.snapshotView(afterScreenUpdates: true)
        if let toVCSnapshot = toVCSnapshot {
            transitionContext.containerView.addSubview(toVCSnapshot)
            toVCSnapshot.frame = toVC.view.frame
            toVCSnapshot.alpha = 0
            toVC.view.isHidden = true
        }
        self.toVCSnapshot = toVCSnapshot
        
        let backgroundColorView = UIView().withoutAutoresizingMaskConstraints
        transitionContext.containerView.addSubview(backgroundColorView)
        backgroundColorView.pin(to: transitionContext.containerView)
        backgroundColorView.backgroundColor = toVC.view.backgroundColor
        backgroundColorView.alpha = 0
        
        let transitionImageView = UIImageView(image: fromImageView.image)
        transitionImageView.frame = fromImageView.convert(fromImageView.frame, to: fromVC.view)
        transitionImageView.contentMode = .scaleAspectFill
        transitionImageView.clipsToBounds = true
        transitionContext.containerView.addSubview(transitionImageView)
        self.transitionImageView = transitionImageView

        fromImageView.isHidden = true
        
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(
            withDuration: duration,
            animations: {
                transitionImageView.frame = toVC.view.frame
                transitionImageView.animateAspectFit()
                backgroundColorView.alpha = 1
            },
            completion: { _ in
                toVC.view.isHidden = false
                fromVC.view.isHidden = false
                fromImageView.isHidden = false
                transitionImageView.removeFromSuperview()
                fromVCSnapshot?.removeFromSuperview()
                toVCSnapshot?.removeFromSuperview()
                backgroundColorView.removeFromSuperview()
                
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
    
    /// Animate transition for dismissal.
    open func animateDismiss(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toVC = transitionContext.viewController(forKey: .to),
            let fromVC = transitionContext.viewController(forKey: .from)
        else { return }
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(
            withDuration: duration,
            animations: { [self] in
                containerTransitionImageView?.transform = .identity
                transitionImageView?.transform = .identity
                if let toImageView = toImageView {
                    containerTransitionImageView?.frame = toImageView.convert(toImageView.frame, to: toVC.view)
                }
                if let containerTransitionImageView = containerTransitionImageView {
                    transitionImageView?.frame.size = containerTransitionImageView.frame.size
                }
                transitionImageView?.animateAspectFill()
                fromVCSnapshot?.alpha = 0
                toVCSnapshot?.alpha = 1
            },
            completion: { [self] _ in
                toImageView?.isHidden = false
                toVC.view.isHidden = false
                fromVC.view.isHidden = false
                transitionImageView?.removeFromSuperview()
                containerTransitionImageView?.removeFromSuperview()
                fromVCSnapshot?.removeFromSuperview()
                toVCSnapshot?.removeFromSuperview()

                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
    
    /// Prepare properties for dismissal transition.
    /// This is shared between interactive and non-interactive dismissal.
    open func prepareZoomOutTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toVC = transitionContext.viewController(forKey: .to),
            let fromVC = transitionContext.viewController(forKey: .from),
            let fromImageView = self.fromImageView
        else { return }
        
        let containerTransitionImageView = UIView()
        containerTransitionImageView.frame = fromImageView.convert(fromImageView.frame, to: fromVC.view)
        containerTransitionImageView.clipsToBounds = true
        self.containerTransitionImageView = containerTransitionImageView
        
        let transitionImageView = UIImageView(image: fromImageView.image)
        transitionImageView.frame.size = containerTransitionImageView.frame.size
        transitionImageView.contentMode = .scaleAspectFit
        transitionImageView.clipsToBounds = true
        self.transitionImageView = transitionImageView
        
        toImageView?.isHidden = true
        fromImageView.isHidden = true
        
        let toVCSnapshot = toVC.view.snapshotView(afterScreenUpdates: true)
        if let toVCSnapshot = toVCSnapshot {
            transitionContext.containerView.addSubview(toVCSnapshot)
            toVCSnapshot.frame = toVC.view.frame
            toVCSnapshot.alpha = 0
            toVC.view.isHidden = true
        }
        self.toVCSnapshot = toVCSnapshot

        let fromVCSnapshot = fromVC.view.snapshotView(afterScreenUpdates: true)
        if let fromVCSnapshot = fromVCSnapshot {
            transitionContext.containerView.addSubview(fromVCSnapshot)
            fromVCSnapshot.frame = fromVC.view.frame
            fromVC.view.isHidden = true
        }
        self.fromVCSnapshot = fromVCSnapshot
        
        transitionContext.containerView.addSubview(containerTransitionImageView)
        containerTransitionImageView.addSubview(transitionImageView)
    }
    
    /// Animate dismissal transition.
    open func animateZoomOutTransition(using transitionContext: UIViewControllerContextTransitioning) {
        prepareZoomOutTransition(using: transitionContext)
        animateDismiss(using: transitionContext)
    }
}

extension UIImageView {
    func animateAspectFit() {
        animateContentMode(.scaleAspectFit)
    }
    
    func animateAspectFill() {
        animateContentMode(.scaleToFill)
    }
    
    private func animateContentMode(_ contentMode: UIImageView.ContentMode) {
        guard let image = image else { return }
        let initialBounds = bounds
        let imageToBoundsWidthRatio = image.size.width / bounds.size.width
        let imageToBoundsHeightRatio = image.size.height / bounds.size.height
        let newRatio: CGFloat
        if contentMode == .scaleAspectFit {
            newRatio = max(imageToBoundsWidthRatio, imageToBoundsHeightRatio)
        } else {
            newRatio = min(imageToBoundsWidthRatio, imageToBoundsHeightRatio)
        }
        let newImageSize = CGSize(
            width: image.size.width / newRatio,
            height: image.size.height / newRatio
        )
        frame.size = newImageSize
        frame.origin = CGPoint(
            x: frame.origin.x + (initialBounds.width - frame.size.width) / 2,
            y: frame.origin.y + (initialBounds.height - frame.size.height) / 2
        )
    }
}
