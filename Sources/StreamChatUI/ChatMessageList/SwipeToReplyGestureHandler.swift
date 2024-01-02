//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A component responsible to manage the swipe to quote reply logic.
open class SwipeToReplyGestureHandler {
    /// A reference to the message list view.
    public private(set) weak var listView: ChatMessageListView?
    /// The current message cell which the gesture is being applied.
    public private(set) weak var messageCell: ChatMessageCell?
    /// A feedback generator which will trigger whenever the threshold is surpassed.
    public private(set) var impactFeedbackGenerator: UIImpactFeedbackGenerator

    /// Whether the swipe threshold was surpassed or not. If yes, it means we should trigger a reply action.
    public private(set) var shouldReply = false
    /// A boolean to control when a feedback should be generated.
    /// It should be generated only one time, when it surpasses the threshold.
    public private(set) var shouldTriggerFeedback = true

    /// The reply icon view.
    public var replyIconImageView: UIImageView? {
        messageCell?.messageContentView?.replyIconImageView
    }

    /// The original reply icon position.
    public private(set) var replyIconOriginalPosition = CGPoint()

    /// The views which will animate when swiping.
    open var swipeableViews: [UIView] {
        [
            messageCell?.messageContentView?.reactionsBubbleView,
            messageCell?.messageContentView?.bubbleView,
            messageCell?.messageContentView?.threadInfoContainer
        ].compactMap { $0 }
    }

    /// The original message view position.
    public private(set) var swipeableViewsOriginalPositions: [UIView: CGPoint] = [:]

    /// The message content.
    public var message: ChatMessage? {
        messageCell?.messageContentView?.content
    }

    /// A closure that is triggered when swiping gesture has ended and the threshold was reached.
    public var onReply: ((ChatMessage) -> Void)?

    /// The swipe translation amount that should trigger a reply.
    ///
    /// By default it is half the size of the message bubble view with a maximum of 50 points.
    open var swipeThreshold: CGFloat {
        guard let messageAnimatableView = messageCell?.messageContentView?.bubbleView else {
            return 0
        }
        return min(50, messageAnimatableView.frame.width / 2.0)
    }

    public init(
        listView: ChatMessageListView,
        impactFeedbackGenerator: UIImpactFeedbackGenerator = .init(style: .medium)
    ) {
        self.listView = listView
        self.impactFeedbackGenerator = impactFeedbackGenerator
    }

    /// Handles the gesture state to determine if the reply should be triggered.
    open func handle(gesture: UIPanGestureRecognizer) {
        guard let listView = self.listView else { return }
        let location = gesture.location(in: listView)

        // When the gesture begins, record the original locations of the views
        if gesture.state == .began, let indexPath = listView.indexPathForRow(at: location) {
            messageCell = listView.cellForRow(at: indexPath) as? ChatMessageCell
            replyIconOriginalPosition = replyIconImageView?.center ?? .zero
            swipeableViewsOriginalPositions = [:]
            swipeableViews.forEach {
                swipeableViewsOriginalPositions[$0] = $0.center
            }
        }

        guard let message = self.message, message.isInteractionEnabled else {
            return
        }

        // Local only messages should be allowed to quote reply.
        if message.isLocalOnly {
            return
        }

        // When we are swiping, move the message views and determine if it should reply
        if gesture.state == .changed {
            let translation = gesture.translation(in: messageCell)
            animateViews(with: translation)

            shouldReply = translation.x > swipeThreshold

            if shouldReply && shouldTriggerFeedback {
                impactFeedbackGenerator.impactOccurred()
                shouldTriggerFeedback = false
            }

            if !shouldReply {
                shouldTriggerFeedback = true
            }
        }

        // When the gesture ends, animate back to the original position and trigger the reply if needed
        if gesture.state == .ended {
            resetViewPositions()

            if shouldReply {
                onReply?(message)
            }

            swipeableViewsOriginalPositions = [:]
        }
    }

    /// Animates the views when a swiping is happening.
    open func animateViews(with translation: CGPoint) {
        swipeableViews.forEach {
            guard let originalCenter = swipeableViewsOriginalPositions[$0] else { return }
            $0.center = CGPoint(
                x: max(originalCenter.x, originalCenter.x + translation.x),
                y: originalCenter.y
            )
        }

        let replyIconTranslation = max(0, min(translation.x, swipeThreshold))
        replyIconImageView?.center = CGPoint(
            x: replyIconOriginalPosition.x + replyIconTranslation,
            y: replyIconOriginalPosition.y
        )
        replyIconImageView?.isHidden = false
        replyIconImageView?.alpha = replyIconTranslation / swipeThreshold
    }

    /// Animates the views to their original positions.
    open func resetViewPositions() {
        UIView.animate(withDuration: 0.4, animations: {
            self.swipeableViews.forEach {
                $0.center = self.swipeableViewsOriginalPositions[$0] ?? .zero
            }
            self.replyIconImageView?.center = self.replyIconOriginalPosition
            self.replyIconImageView?.alpha = 0.0
        }, completion: { _ in
            self.replyIconImageView?.isHidden = true
        })
    }
}
