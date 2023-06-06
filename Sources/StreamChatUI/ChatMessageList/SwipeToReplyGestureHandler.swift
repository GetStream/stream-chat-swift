//
// Copyright © 2023 Stream.io Inc. All rights reserved.
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

    /// The original message view position.
    public private(set) var messageOriginalCenter = CGPoint()
    /// The original reactions view position.
    public private(set) var reactionsOriginalCenter = CGPoint()
    /// The original reply icon position.
    public private(set) var replyIconOriginalCenter = CGPoint()
    /// Wether the swipe threshold was surpassed or not. If yes, it means we should trigger a reply action.
    public private(set) var shouldReply = false
    /// A boolean to control when a feedback should be generated. It should only be generated
    public private(set) var shouldTriggerFeedback = true

    /// The message bubble view.
    public var messageBubbleView: ChatMessageBubbleView? {
        messageCell?.messageContentView?.bubbleView
    }

    /// The message reactions bubble view.
    public var reactionsBubbleView: ChatReactionBubbleBaseView? {
        messageCell?.messageContentView?.reactionsBubbleView
    }

    /// The reply icon view.
    public var replyIconImageView: UIImageView? {
        messageCell?.replyIconImageView
    }

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
        guard let messageAnimatableView = messageBubbleView else {
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

        // When the gesture begins, record the current center location of the message view
        if gesture.state == .began, let indexPath = listView.indexPathForRow(at: location) {
            messageCell = listView.cellForRow(at: indexPath) as? ChatMessageCell
            messageOriginalCenter = messageBubbleView?.center ?? .zero
            replyIconOriginalCenter = replyIconImageView?.center ?? .zero
            reactionsOriginalCenter = reactionsBubbleView?.center ?? .zero
        }

        guard let messageBubbleView = self.messageBubbleView,
              let message = self.message else {
            return
        }

        guard message.isInteractionEnabled else {
            return
        }

        // When we are swiping, move the message view and handle if when it should swipe
        if gesture.state == .changed {
            let translation = gesture.translation(in: messageCell)

            messageBubbleView.center = CGPoint(
                x: max(messageOriginalCenter.x, messageOriginalCenter.x + translation.x),
                y: messageOriginalCenter.y
            )
            reactionsBubbleView?.center = CGPoint(
                x: max(reactionsOriginalCenter.x, reactionsOriginalCenter.x + translation.x),
                y: reactionsOriginalCenter.y
            )

            let translationAmount = (messageOriginalCenter.x + translation.x) - messageOriginalCenter.x
            shouldReply = translationAmount > swipeThreshold

            let replyIconTranslation = max(0, min(translationAmount, swipeThreshold))
            messageCell?.replyIconImageView.isHidden = false
            messageCell?.replyIconImageView.alpha = replyIconTranslation / swipeThreshold
            messageCell?.replyIconImageView.center = CGPoint(
                x: replyIconOriginalCenter.x + replyIconTranslation,
                y: replyIconOriginalCenter.y
            )

            if shouldReply && shouldTriggerFeedback {
                impactFeedbackGenerator.impactOccurred()
                shouldTriggerFeedback = false
            }

            if !shouldReply {
                shouldTriggerFeedback = true
            }
        }

        // When the gesture ends, animate back to the original position and trigger the swipe if needed
        if gesture.state == .ended {
            UIView.animate(withDuration: 0.4, animations: {
                self.messageBubbleView?.center = self.messageOriginalCenter
                self.reactionsBubbleView?.center = self.reactionsOriginalCenter
                self.replyIconImageView?.center = self.replyIconOriginalCenter
                self.replyIconImageView?.alpha = 0.0
            }, completion: { _ in
                self.replyIconImageView?.isHidden = true
            })

            if shouldReply {
                onReply?(message)
            }

            messageCell = nil
        }
    }
}
