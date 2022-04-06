//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
            let fromImageView = animator.fromImageView,
            let toImageView = animator.toImageView,
            let transitionImageView = animator.transitionImageView
        else { return }

        fromImageView.isHidden = true
        toImageView.isHidden = true

        let translatedPoint = gestureRecognizer.translation(in: fromVC.view)

        let verticalDelta: CGFloat = max(translatedPoint.y, 0.0)
        
        let fromVCAlpha = backgroundAlpha(for: fromVC.view, delta: verticalDelta)
        let scale = self.scale(in: fromVC.view, delta: verticalDelta)
        
        fromVC.view.alpha = fromVCAlpha
        
        transitionImageView.transform = CGAffineTransform(scaleX: scale, y: scale)

        let newCenterX = fromImageView.center.x + translatedPoint.x
        let newCenterY = fromImageView.center.y + translatedPoint.y - transitionImageView.frame
            .height * (1 - scale) / 2.0
        let newCenter = CGPoint(x: newCenterX, y: newCenterY)
        transitionImageView.center = newCenter
        
        transitionContext.updateInteractiveTransition(1 - scale)

        guard gestureRecognizer.state == .ended else { return }

        let velocity = gestureRecognizer.velocity(in: fromVC.view)

        if velocity.y < 0 {
            let duration = animator.transitionDuration(using: transitionContext)
            UIView.animate(
                withDuration: duration,
                animations: {
                    transitionImageView.transform = .identity
                    transitionImageView.center = fromImageView.center
                    fromVC.view.alpha = 1
                },
                completion: { _ in
                    fromImageView.isHidden = false
                    toImageView.isHidden = false
                    transitionImageView.removeFromSuperview()
                    animator.transitionImageView = nil
                    
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
