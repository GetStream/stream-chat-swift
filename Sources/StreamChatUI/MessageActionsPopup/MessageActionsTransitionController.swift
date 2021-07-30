//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

/// Transitions controller for `ChatMessagePopupVC`.
open class MessageActionsTransitionController: NSObject, UIViewControllerTransitioningDelegate,
    UIViewControllerAnimatedTransitioning {
    /// Indicates if the transition is for presenting or dismissing.
    open var isPresenting: Bool = false
    /// `messageContentView`'s initial frame.
    open var messageContentViewFrame: CGRect = .zero
    /// `messageContentView`'s constraints to be activated after dismissal.
    open var messageContentViewActivateConstraints: [NSLayoutConstraint] = []
    /// Constraints to be deactivated after dismissal.
    open var messageContentViewDeactivateConstraints: [NSLayoutConstraint] = []
    /// `messageContentView` instance that is animated.
    open weak var messageContentView: _ChatMessageContentView<ExtraData>!
    /// `messageContentView`'s initial superview.
    open weak var messageContentViewSuperview: UIView!
    /// Top anchor for main container.
    open var mainContainerTopAnchor: NSLayoutConstraint?
    /// Feedback generator.
    public private(set) lazy var impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = true
        return self
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = false
        return self
    }
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.25
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isPresenting {
            animatePresent(using: transitionContext)
        } else {
            animateDismiss(using: transitionContext)
        }
    }
    
    /// Animates present transition.
    open func animatePresent(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toVC = transitionContext.viewController(forKey: .to) as? _ChatMessagePopupVC<ExtraData>,
            let fromVC = transitionContext.viewController(forKey: .from)
        else { return }

        messageContentViewSuperview = messageContentView.superview
        
        let messageContentViewSnapshot = messageContentView.snapshotView(afterScreenUpdates: true)
        if let messageContentViewSnapshot = messageContentViewSnapshot {
            messageContentViewSnapshot.frame = messageContentViewSuperview.convert(messageContentView.frame, to: fromVC.view)
            transitionContext.containerView.addSubview(messageContentViewSnapshot)
        }
    
        messageContentView.isHidden = true
        
        // Prepare `messageContentView` and update its frame to be without reactions.
        if messageContentView.reactionsBubbleView?.isVisible == true {
            messageContentView.reactionsBubbleView?.isVisible = false
            messageContentView.bubbleToReactionsConstraint?.isActive = false
            mainContainerTopAnchor = messageContentView.mainContainer.topAnchor.pin(equalTo: messageContentView.topAnchor)
            mainContainerTopAnchor?.isActive = true
        }
        messageContentView.setNeedsLayout()
        messageContentView.layoutIfNeeded()
        var messageContentViewFrame = messageContentView.superview!.convert(messageContentView.frame, to: nil)
        self.messageContentViewFrame = messageContentViewFrame
        let allMessageContentViewSuperviewConstraints = Set(messageContentView.superview!.constraints)
        messageContentView.removeFromSuperview()
        messageContentViewActivateConstraints = Array(
            allMessageContentViewSuperviewConstraints.subtracting(messageContentViewSuperview.constraints)
        )
        messageContentViewDeactivateConstraints = [
            messageContentViewSuperview.widthAnchor.constraint(equalToConstant: messageContentViewFrame.width),
            messageContentViewSuperview.heightAnchor.constraint(equalToConstant: messageContentViewFrame.height)
        ]
        NSLayoutConstraint.deactivate(messageContentViewActivateConstraints)
        NSLayoutConstraint.activate(messageContentViewDeactivateConstraints)
        messageContentViewFrame.size = messageContentView.systemLayoutSizeFitting(
            CGSize(width: messageContentViewFrame.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .streamRequire,
            verticalFittingPriority: .streamLow
        )

        toVC.messageViewFrame = messageContentViewFrame
        toVC.setUpLayout()
        
        transitionContext.containerView.addSubview(toVC.view)
        
        let fromVCSnapshot = fromVC.view.snapshotView(afterScreenUpdates: true)
        if let fromVCSnapshot = fromVCSnapshot {
            fromVCSnapshot.frame = fromVC.view.frame
            fromVC.view.isHidden = true
        }

        let blurView = UIVisualEffectView()
        blurView.frame = toVC.view.frame
        
        let reactionsSnapshot: UIView?
        if let reactionsController = toVC.reactionsController {
            reactionsSnapshot = reactionsController.view.snapshotView(afterScreenUpdates: true)
            reactionsSnapshot?.frame = reactionsController.view.superview!.convert(reactionsController.view.frame, to: nil)
            reactionsSnapshot?.transform = CGAffineTransform(scaleX: 0, y: 0)
            reactionsSnapshot?.alpha = 0.0
        } else {
            reactionsSnapshot = nil
        }
        
        let actionsSnapshot = toVC.actionsController.view.snapshotView(afterScreenUpdates: true)
        if let actionsSnapshot = actionsSnapshot {
            let actionsFrame = toVC.actionsController.view.superview!.convert(toVC.actionsController.view.frame, to: nil)
            actionsSnapshot.frame = actionsFrame
            actionsSnapshot.transform = CGAffineTransform(scaleX: 0, y: 0)
            actionsSnapshot.alpha = 0.0
        }
        
        if let messageContentViewSnapshot = messageContentViewSnapshot {
            fromVCSnapshot.map { transitionContext.containerView.insertSubview($0, belowSubview: messageContentViewSnapshot) }
            transitionContext.containerView.insertSubview(blurView, belowSubview: messageContentViewSnapshot)
            reactionsSnapshot.map { transitionContext.containerView.insertSubview($0, belowSubview: messageContentViewSnapshot) }
            actionsSnapshot.map { transitionContext.containerView.insertSubview($0, belowSubview: messageContentViewSnapshot) }
        }

        toVC.view.isHidden = true

        messageContentView.isHidden = false
        
        transitionContext.containerView.addSubview(messageContentView)
        messageContentView.frame = messageContentViewFrame
        messageContentView.translatesAutoresizingMaskIntoConstraints = true
        
        messageContentViewSnapshot?.removeFromSuperview()
        
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(
            withDuration: 0.2 * duration,
            delay: 0,
            options: [.curveEaseOut],
            animations: { [self] in
                messageContentView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            },
            completion: { [self] _ in
                impactFeedbackGenerator.impactOccurred()
            }
        )
        UIView.animate(
            withDuration: 0.8 * duration,
            delay: 0.2 * duration,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 4,
            options: [.curveEaseInOut],
            animations: { [self] in
                actionsSnapshot?.transform = .identity
                actionsSnapshot?.alpha = 1.0
                reactionsSnapshot?.transform = .identity
                reactionsSnapshot?.alpha = 1.0
                messageContentView.transform = .identity
                messageContentView.frame.origin = toVC.messageContentContainerView.superview!.convert(
                    toVC.messageContentContainerView.frame,
                    to: nil
                )
                .origin
                if let effect = (toVC.blurView as? UIVisualEffectView)?.effect {
                    blurView.effect = effect
                }
            },
            completion: { [self] _ in
                toVC.view.isHidden = false
                fromVC.view.isHidden = false
                messageContentView.isHidden = false
                toVC.messageContentContainerView.addSubview(messageContentView)
                messageContentView.translatesAutoresizingMaskIntoConstraints = false
                toVC.messageContentContainerView.embed(messageContentView)
                fromVCSnapshot?.removeFromSuperview()
                blurView.removeFromSuperview()
                reactionsSnapshot?.removeFromSuperview()
                actionsSnapshot?.removeFromSuperview()
                
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
    
    /// Animates dismissal transition.
    open func animateDismiss(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: .from) as? _ChatMessagePopupVC<ExtraData>,
            let toVC = transitionContext.viewController(forKey: .to)
        else { return }
        
        let messageContentViewSnapshot = messageContentView.snapshotView(afterScreenUpdates: true)
        if let messageContentViewSnapshot = messageContentViewSnapshot {
            messageContentViewSnapshot.frame = messageContentView.convert(messageContentView.frame, to: fromVC.view)
            transitionContext.containerView.addSubview(messageContentViewSnapshot)
        }
        
        messageContentView.isHidden = true
        
        let toVCSnapshot = toVC.view.snapshotView(afterScreenUpdates: true)
        if let toVCSnapshot = toVCSnapshot {
            transitionContext.containerView.addSubview(toVCSnapshot)
            toVCSnapshot.frame = toVC.view.frame
            toVC.view.isHidden = true
        }

        let blurView = UIVisualEffectView()
        if let effect = (fromVC.blurView as? UIVisualEffectView)?.effect {
            blurView.effect = effect
        }
        blurView.frame = fromVC.view.frame
        
        let reactionsSnapshot: UIView?
        if let reactionsController = fromVC.reactionsController {
            reactionsSnapshot = reactionsController.view.snapshotView(afterScreenUpdates: true)
            reactionsSnapshot?.frame = reactionsController.view.superview!.convert(reactionsController.view.frame, to: nil)
            reactionsSnapshot?.transform = .identity
            reactionsSnapshot.map(transitionContext.containerView.addSubview)
        } else {
            reactionsSnapshot = nil
        }
        
        let actionsSnapshot = fromVC.actionsController.view.snapshotView(afterScreenUpdates: true)
        if let actionsSnapshot = actionsSnapshot {
            actionsSnapshot.frame = fromVC.actionsController.view.superview!.convert(fromVC.actionsController.view.frame, to: nil)
            transitionContext.containerView.addSubview(actionsSnapshot)
        }
        
        if let messageContentViewSnapshot = messageContentViewSnapshot {
            toVCSnapshot.map { transitionContext.containerView.insertSubview($0, belowSubview: messageContentViewSnapshot) }
            transitionContext.containerView.insertSubview(blurView, belowSubview: messageContentViewSnapshot)
            reactionsSnapshot.map { transitionContext.containerView.insertSubview($0, belowSubview: messageContentViewSnapshot) }
            actionsSnapshot.map { transitionContext.containerView.insertSubview($0, belowSubview: messageContentViewSnapshot) }
        }

        messageContentView.isHidden = false
        let frame = messageContentView.convert(messageContentView.frame, to: fromVC.view)
        messageContentView.removeFromSuperview()
        transitionContext.containerView.addSubview(messageContentView)
        messageContentView.translatesAutoresizingMaskIntoConstraints = true
        messageContentView.frame = frame
        
        messageContentViewSnapshot?.removeFromSuperview()
        
        fromVC.view.isHidden = true
        
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(
            withDuration: duration,
            delay: 0,
            animations: { [self] in
                actionsSnapshot?.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                reactionsSnapshot?.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                actionsSnapshot?.alpha = 0.0
                reactionsSnapshot?.alpha = 0.0
                messageContentView.frame = messageContentViewFrame
                blurView.effect = nil
            },
            completion: { [self] _ in
                toVC.view.isHidden = false
                fromVC.view.isHidden = false
                messageContentView.translatesAutoresizingMaskIntoConstraints = false
                if let mainContainerTopAnchor = mainContainerTopAnchor {
                    mainContainerTopAnchor.isActive = false
                    messageContentView.reactionsBubbleView?.isVisible = true
                    messageContentView.bubbleToReactionsConstraint?.isActive = true
                }
                messageContentView.removeFromSuperview()
                messageContentViewSuperview.addSubview(messageContentView)
                NSLayoutConstraint.activate(messageContentViewActivateConstraints)
                NSLayoutConstraint.deactivate(messageContentViewDeactivateConstraints)
                toVCSnapshot?.removeFromSuperview()
                blurView.removeFromSuperview()
                reactionsSnapshot?.removeFromSuperview()
                actionsSnapshot?.removeFromSuperview()
                
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}
