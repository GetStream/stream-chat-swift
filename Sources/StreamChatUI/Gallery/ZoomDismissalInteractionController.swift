//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

/// Controller for interactive dismissal.
open class ZoomDismissalInteractionController: NSObject, UIViewControllerInteractiveTransitioning {
    /// Context of the current transition.
    public weak var transitionContext: UIViewControllerContextTransitioning?
    /// Current transition's animator.
    public var animator: UIViewControllerAnimatedTransitioning?
    
    /// Update interactive dismissal.
    open func handlePan(with gestureRecognizer: UIPanGestureRecognizer) {
        guard
            let transitionContext = transitionContext,
            let animator = animator as? ZoomAnimator,
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to),
            let fromVCSnapshot = animator.fromVCSnapshot,
            let toVCSnapshot = animator.toVCSnapshot,
            let fromImageView = animator.fromImageView,
            let toImageView = animator.toImageView,
            let transitionImageView = animator.transitionImageView,
            let containerTransitionImageView = animator.containerTransitionImageView
        else { return }

        fromImageView.isHidden = true
        toImageView.isHidden = true

        let translatedPoint = gestureRecognizer.translation(in: fromVC.view)

        let verticalDelta: CGFloat = max(translatedPoint.y, 0.0)
        
        let fromVCAlpha = backgroundAlpha(for: fromVCSnapshot, delta: verticalDelta)
        let scale = self.scale(in: fromVC.view, delta: verticalDelta)
        
        fromVCSnapshot.alpha = fromVCAlpha
        toVCSnapshot.alpha = 1 - fromVCAlpha
        
        animator.containerTransitionImageView?.transform = CGAffineTransform(scaleX: scale, y: scale)
        transitionImageView.transform = CGAffineTransform(scaleX: scale, y: scale)

        let newCenterX = fromImageView.center.x + translatedPoint.x
        let newCenterY = fromImageView.center.y + translatedPoint.y - transitionImageView.frame
            .height * (1 - scale) / 2.0
        let newCenter = CGPoint(x: newCenterX, y: newCenterY)
        animator.containerTransitionImageView?.center = newCenter
        
        transitionContext.updateInteractiveTransition(1 - scale)

        guard gestureRecognizer.state == .ended else { return }

        let velocity = gestureRecognizer.velocity(in: fromVC.view)

        if velocity.y < 0 {
            let duration = animator.transitionDuration(using: transitionContext)
            UIView.animate(
                withDuration: duration,
                animations: {
                    containerTransitionImageView.transform = .identity
                    transitionImageView.transform = .identity
                    containerTransitionImageView.frame = toVC.view.frame
                    transitionImageView.frame = containerTransitionImageView.frame
                    fromVCSnapshot.alpha = 1
                    toVCSnapshot.alpha = 1
                },
                completion: { _ in
                    toVC.view.isHidden = false
                    fromVC.view.isHidden = false
                    fromImageView.isHidden = false
                    toImageView.isHidden = false
                    transitionImageView.removeFromSuperview()
                    fromVCSnapshot.removeFromSuperview()
                    toVCSnapshot.removeFromSuperview()
                    containerTransitionImageView.removeFromSuperview()
                    
                    transitionContext.cancelInteractiveTransition()
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
            )
        } else {
            animator.animateDismiss(using: transitionContext)
        }
    }

    /// Returns alpha for `view` based on `delta`.
    open func backgroundAlpha(for view: UIView, delta: CGFloat) -> CGFloat {
        let maximumDelta = view.bounds.height / 4.0
        let deltaAsPercentageOfMaximum = min(abs(delta) / maximumDelta, 1.0)
        
        return 1.0 - deltaAsPercentageOfMaximum
    }
    
    /// Returns scale for `view` based on `delta`.
    open func scale(in view: UIView, delta: CGFloat) -> CGFloat {
        let initialScale: CGFloat = 1.0
        let finalScale: CGFloat = 0.5
        let totalAvailableScale = initialScale - finalScale
        
        let maximumDelta = view.bounds.height / 2.0
        let deltaAsPercentageOfMaximun = min(abs(delta) / maximumDelta, 1.0)
        
        return initialScale - (deltaAsPercentageOfMaximun * totalAvailableScale)
    }
    
    open func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext

        guard
            let animator = self.animator as? ZoomAnimator
        else { return }
        
        animator.prepareZoomOutTransition(using: transitionContext)
    }
}
