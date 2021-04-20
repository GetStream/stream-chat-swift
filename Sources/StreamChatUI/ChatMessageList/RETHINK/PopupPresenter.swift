//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class PopupPresenter {
    /// Feedback generator used when presenting actions controller on selected message
    open var impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    public let rootViewController: UIViewController
    
    public init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
    }
    
    open func present<ExtraData>(
        targetView: UIView,
        message: _ChatMessage<ExtraData>,
        actionsController: _ChatMessageActionsVC<ExtraData>,
        reactionsController: _ChatMessageReactionsVC<ExtraData>?
    ) {
        // TODO: for PR: This should be doable via:
        // 1. options: [.autoreverse, .repeat] and
        // 2. `UIView.setAnimationRepeatCount(0)` inside the animation block...
        //
        // and then just set completion to the animation to transform this back. aka `cell.messageView.transform = .identity`
        // however, this doesn't work as after the animation is done, it clips back to the value set in animation block
        // and then on completion goes back to `.identity`... This is really strange, but I was fighting it for some time
        // and couldn't find proper solution...
        // Also there are some limitations to the current solution ->
        // According to my debug view hiearchy, the content inside `messageView.messageBubbleView` is not constrainted to the
        // bubble view itself, meaning right now if we want to scale the view of incoming message, we scale the avatarView
        // of the sender as well...
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.curveEaseIn],
            animations: {
                targetView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            },
            completion: { _ in
                self.impactFeedbackGenerator.impactOccurred()

                UIView.animate(
                    withDuration: 0.1,
                    delay: 0,
                    options: [.curveEaseOut],
                    animations: {
                        targetView.transform = .identity
                    }
                )
                
                let popup = _ChatMessagePopupVC<ExtraData>()
                // only `message` is used but I don't want to break current implementation
                popup.message = _ChatMessageGroupPart(
                    message: message,
                    quotedMessage: nil,
                    isFirstInGroup: true,
                    isLastInGroup: true,
                    didTapOnAttachment: nil,
                    didTapOnAttachmentAction: nil
                )
                popup.messageViewFrame = targetView.superview!.convert(targetView.frame, to: nil)
                popup.actionsController = actionsController
                popup.reactionsController = reactionsController
                popup.modalPresentationStyle = .overFullScreen
                popup.modalTransitionStyle = .crossDissolve

                self.rootViewController.present(popup, animated: false)
            }
        )
    }
}
