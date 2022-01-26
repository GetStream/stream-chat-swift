//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

/// Stream's custom transitioning delegate to handle a modal presentation.
///
/// This should be used if you are presenting the ``ChatChannelVC`` in a modal.
/// The reason this custom transition should be used instead of the native one is because we use an inverted
/// `UITableView` for the message list component which it doesn't play well with the native modal transition.
open class StreamModalTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    public func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        StreamModalPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

/// Stream's custom `UIPresentationController` to handle a modal presentation.
open class StreamModalPresentationController: UIPresentationController {
    /// The overlay view that is rendered between the presenting and presented view.
    open var overlayView: UIView = UIView()

    /// The overlay opacity value when the presented view is shown.
    open var overlayViewAlpha: CGFloat = 0.7

    /// The corner radius of the presented view when it is shown.
    open var cornerRadius: CGFloat = 22

    /// The presented view height scale.
    open var presentedViewHeightScale: CGFloat = 0.94

    /// The presenting view height scale when the presented view is shown.
    open var presentingViewHeightScale: CGFloat = 0.9

    override public init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        setup()
    }

    /// Setup the overlay view and gesture recognizers of the `UIPresentationController`.
    open func setup() {
        overlayView.backgroundColor = UIColor.black
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissController))
        overlayView.addGestureRecognizer(tapGestureRecognizer)

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        presentedViewController.view.addGestureRecognizer(panGestureRecognizer)
    }

    override open var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = self.containerView else {
            return .zero
        }
        return CGRect(
            origin: CGPoint(x: 0, y: containerView.frame.height * (1 - presentedViewHeightScale)),
            size: CGSize(
                width: containerView.frame.width,
                height: containerView.frame.height * presentedViewHeightScale
            )
        )
    }

    override open func presentationTransitionWillBegin() {
        overlayView.alpha = 0
        containerView?.addSubview(overlayView)

        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.showPresentedView()
        })
    }

    override open func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dismissPresentedView()
        }, completion: { (_) in
            self.overlayView.removeFromSuperview()
        })
    }

    override open func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()

        presentedView?.frame = frameOfPresentedViewInContainerView
        overlayView.frame = containerView?.bounds ?? .zero
    }

    @objc open func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let presentedView = self.presentedView else { return }
        guard let containerView = self.containerView else { return }

        let translationY = gestureRecognizer.translation(in: presentedView).y
        guard translationY >= 0 else { return }

        animateInteractiveTransition(translationY)

        if gestureRecognizer.state == .ended {
            // In case the user drags the view too fast or below half of the screen, dismiss the controller
            let dragVelocity = gestureRecognizer.velocity(in: presentedView)
            if dragVelocity.y >= 1000 || translationY > containerView.frame.height * 0.5 {
                dismissController()
                return
            }

            // Otherwise, cancel the dismissal (which means, show the presented view again)
            UIView.animate(withDuration: 0.3) {
                self.showPresentedView()
            }
        }
    }

    @objc open func dismissController() {
        presentedViewController.dismiss(animated: true, completion: nil)
    }

    /// Animates the interactive transition based on the translation of the `UIPanGestureRecognizer`.
    /// - Parameter translationY: The translation in the Y axis of pan gesture.
    open func animateInteractiveTransition(_ translationY: CGFloat) {
        guard let presentedView = self.presentedView else { return }
        guard let containerView = self.containerView else { return }

        let translationPercentage = translationY / containerView.frame.height

        let newCornerRadius = cornerRadius - (cornerRadius * translationPercentage)
        presentedView.layer.cornerRadius = newCornerRadius

        var newFrame = frameOfPresentedViewInContainerView
        newFrame.origin.y += translationY
        presentedView.frame = newFrame

        let newOverlayAlpha = overlayViewAlpha - (overlayViewAlpha * translationPercentage)
        overlayView.alpha = newOverlayAlpha

        let newPresentingViewHeightScale = (1 - presentingViewHeightScale) * translationPercentage
        presentingViewController.view.transform = CGAffineTransform(
            scaleX: presentingViewHeightScale + newPresentingViewHeightScale,
            y: presentingViewHeightScale + newPresentingViewHeightScale
        )
    }

    /// Shows the presented view.
    open func showPresentedView() {
        overlayView.alpha = overlayViewAlpha
        presentedView?.layer.cornerRadius = cornerRadius
        presentedView?.frame = frameOfPresentedViewInContainerView
        presentingViewController.view.layer.cornerRadius = cornerRadius
        presentingViewController.view.transform = .init(
            scaleX: presentingViewHeightScale,
            y: presentingViewHeightScale
        )
    }

    /// Dismisses the presented view.
    open func dismissPresentedView() {
        overlayView.alpha = 0
        presentedView?.layer.cornerRadius = 0
        presentingViewController.view.transform = .init(scaleX: 1, y: 1)
        presentingViewController.view.layer.cornerRadius = 0
    }
}
