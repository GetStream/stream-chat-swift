//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

/// Object for controlling zoom transition.
open class ZoomTransitionController: NSObject, UIViewControllerTransitioningDelegate {
    /// Object for animation changes.
    public private(set) lazy var zoomAnimator = ZoomAnimator()
    
    /// `UIImageView` that is being presented.
    public weak var fromImageView: UIImageView?

    /// Closure for `UIImageView` in the presented view controller.
    public var presentedVCImageView: (() -> UIImageView?)?

    /// Closure for `UIImageView` that is in the presenting view controller.
    public var presentingImageView: (() -> UIImageView?)?
    
    /// Controller for interactive dismissal
    public private(set) lazy var interactionController = ZoomDismissalInteractionController()

    /// Indiicates whether the current transition is interactive or not.
    public var isInteractive: Bool = false
    
    open func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        zoomAnimator.isPresenting = true
        zoomAnimator.fromImageView = fromImageView
        return zoomAnimator
    }
    
    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        zoomAnimator.isPresenting = false
        zoomAnimator.toImageView = presentingImageView?()
        zoomAnimator.fromImageView = presentedVCImageView?()
        return zoomAnimator
    }
    
    open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning? {
        guard isInteractive else { return nil }

        interactionController.animator = animator
        return interactionController
    }

    /// Update interactive dismissal.
    open func handlePan(with gestureRecognizer: UIPanGestureRecognizer) {
        interactionController.handlePan(with: gestureRecognizer)
    }
}
