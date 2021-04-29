//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageListRouter = _ChatMessageListRouter<NoExtraData>

open class _ChatMessageListRouter<ExtraData: ExtraDataTypes>: ChatRouter<UIViewController> {
    /// Feedback generator used when presenting actions controller on selected message
    open var impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    open func showMessageActionsPopUp(
        viewToAnimate: _ChatMessageContentView<ExtraData>,
        viewToShow: _ChatMessageContentView<ExtraData>,
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
                viewToAnimate.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            },
            completion: { _ in
                self.impactFeedbackGenerator.impactOccurred()

                UIView.animate(
                    withDuration: 0.1,
                    delay: 0,
                    options: [.curveEaseOut],
                    animations: {
                        viewToAnimate.transform = .identity
                    }
                )

                let popup = _ChatMessagePopupVC<ExtraData>()
                // only `message` is used but I don't want to break current implementation
                popup.messageContentView = viewToShow
                // TODO: Whole PopupVC has to be updated for the new MessageCell
                popup.messageViewFrame = viewToAnimate.superview!.convert(viewToAnimate.frame, to: nil)
                popup.actionsController = actionsController
                popup.reactionsController = reactionsController
                popup.modalPresentationStyle = .overFullScreen
                popup.modalTransitionStyle = .crossDissolve

                self.rootViewController.present(popup, animated: false)
            }
        )
    }
    
    open func showPreview(for attachment: ChatMessageDefaultAttachment) {
        let preview = ChatMessageAttachmentPreviewVC()
        preview.content = attachment.type == .file ? attachment.url : attachment.imageURL
        
        let navigation = UINavigationController(rootViewController: preview)
        rootViewController.present(navigation, animated: true)
    }

    open func openLink(_ link: ChatMessageDefaultAttachment) {
        let preview = ChatMessageAttachmentPreviewVC()
        preview.content = link.url

        let navigation = UINavigationController(rootViewController: preview)
        rootViewController.present(navigation, animated: true)
    }

    open func showThread(
        for message: _ChatMessage<ExtraData>,
        in channel: _ChatChannel<ExtraData>,
        client: _ChatClient<ExtraData>
    ) {
        let threadVC = _ChatThreadVC<ExtraData>()
        threadVC.channelController = client.channelController(for: channel.cid)
        threadVC.messageController = client.messageController(
            cid: channel.cid,
            messageId: message.id
        )
        navigationController?.show(threadVC, sender: self)
    }
}
