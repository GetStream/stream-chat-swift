//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

/// Object for animating transition of an image.
open class ZoomAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    /// `UIImageView` for view controller initiating the transition.
    public weak var fromImageView: UIImageView?
    /// `UIImageView` for view controller being transitioned to.
    public weak var toImageView: UIImageView?
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
        let containerView = transitionContext.containerView
        
        guard
            let toVC = transitionContext.viewController(forKey: .to),
            let fromVC = transitionContext.viewController(forKey: .from),
            let fromImageView = self.fromImageView
        else { return }
        
        toVC.view.alpha = 0
        containerView.addSubview(toVC.view)
        
        let backgroundColorView = UIView().withoutAutoresizingMaskConstraints
        containerView.addSubview(backgroundColorView)
        backgroundColorView.pin(to: containerView)
        backgroundColorView.backgroundColor = toVC.view.backgroundColor
        backgroundColorView.alpha = 0

        if transitionImageView == nil {
            let transitionImageView = UIImageView(image: fromImageView.image)
            transitionImageView.frame = fromImageView.convert(fromImageView.frame, to: fromVC.view)
            transitionImageView.contentMode = .scaleAspectFill
            transitionImageView.clipsToBounds = true
            self.transitionImageView = transitionImageView
            containerView.addSubview(transitionImageView)
        }

        fromImageView.isHidden = true

        let duration = transitionDuration(using: transitionContext)
        
        UIView.animateKeyframes(withDuration: duration, delay: 0, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1.0, animations: { [weak self] in
                if let image = fromImageView.image {
                    self?.transitionImageView?.frame = self?.calculateZoomInImageFrame(image: image, forView: toVC.view) ?? .zero
                    backgroundColorView.alpha = 1
                }
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.95, relativeDuration: 0.05, animations: {
                toVC.view.alpha = 1
            })
        }, completion: { _ in
            fromImageView.isHidden = false
            self.transitionImageView?.removeFromSuperview()
            self.transitionImageView = nil
            backgroundColorView.removeFromSuperview()

            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
    /// Animate dismissal transition.
    open func animateZoomOutTransition(using transitionContext: UIViewControllerContextTransitioning) {
        prepareZoomOutTransition(using: transitionContext)
        animateDismiss(using: transitionContext)
    }
    
    /// Prepare properties for dismissal transition.
    /// This is shared between interactive and non-interactive dismissal.
    open func prepareZoomOutTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        guard
            let fromVC = transitionContext.viewController(forKey: .from),
            let fromImageView = self.fromImageView,
            let toImageView = self.toImageView
        else { return }
        
        toImageView.isHidden = true
        
        if transitionImageView == nil {
            if let image = fromImageView.image {
                let transitionImageView = UIImageView(image: image)
                transitionImageView.contentMode = .scaleAspectFill
                transitionImageView.clipsToBounds = true
                transitionImageView.frame = fromImageView.convert(
                    frame(for: image, inImageViewAspectFit: fromImageView),
                    to: fromVC.view
                )
                self.transitionImageView = transitionImageView
                containerView.addSubview(transitionImageView)
            }
        }
        
        fromImageView.isHidden = true
    }
    
    /// Animate transition for dismissal.
    open func animateDismiss(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toVC = transitionContext.viewController(forKey: .to),
            let fromVC = transitionContext.viewController(forKey: .from),
            let fromImageView = self.fromImageView,
            let toImageView = self.toImageView
        else { return }
        let duration = transitionDuration(using: transitionContext)

        UIView.animate(
            withDuration: duration,
            animations: { [self] in
                fromVC.view.alpha = 0
                self.transitionImageView?.frame = toImageView.convert(toImageView.frame, to: toVC.view)
            },
            completion: { [self] _ in
                self.transitionImageView?.removeFromSuperview()
                toImageView.isHidden = false
                fromImageView.isHidden = false

                transitionContext.finishInteractiveTransition()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
    
    private func calculateZoomInImageFrame(image: UIImage, forView view: UIView) -> CGRect {
        let viewRatio = view.frame.size.width / view.frame.size.height
        let imageRatio = image.size.width / image.size.height
        let touchesSides = (imageRatio > viewRatio)
        
        if touchesSides {
            let height = view.frame.width / imageRatio
            let yPoint = view.frame.minY + (view.frame.height - height) / 2
            return CGRect(x: 0, y: yPoint, width: view.frame.width, height: height)
        } else {
            let width = view.frame.height * imageRatio
            let xPoint = view.frame.minX + (view.frame.width - width) / 2
            return CGRect(x: xPoint, y: 0, width: width, height: view.frame.height)
        }
    }
    
    private func frame(for image: UIImage, inImageViewAspectFit imageView: UIImageView) -> CGRect {
        let imageRatio = (image.size.width / image.size.height)
        let viewRatio = imageView.frame.size.width / imageView.frame.size.height
        if imageRatio < viewRatio {
            let scale = imageView.frame.size.height / image.size.height
            let width = scale * image.size.width
            let topLeftX = (imageView.frame.size.width - width) * 0.5
            return CGRect(x: topLeftX, y: 0, width: width, height: imageView.frame.size.height)
        } else {
            let scale = imageView.frame.size.width / image.size.width
            let height = scale * image.size.height
            let topLeftY = (imageView.frame.size.height - height) * 0.5
            return CGRect(x: 0.0, y: topLeftY, width: imageView.frame.size.width, height: height)
        }
    }
}
