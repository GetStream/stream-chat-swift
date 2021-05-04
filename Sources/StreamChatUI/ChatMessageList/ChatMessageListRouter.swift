//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageListRouter = _ChatMessageListRouter<NoExtraData>

open class _ChatMessageListRouter<ExtraData: ExtraDataTypes>:
    ChatRouter<UIViewController>,
    UIViewControllerTransitioningDelegate {
    public private(set) lazy var transitionController = MessageActionsTransitionController<ExtraData>()
    
    open func showMessageActionsPopUp(
        messageContentView: _ChatMessageContentView<ExtraData>,
        messageActionsController: _ChatMessageActionsVC<ExtraData>,
        messageReactionsController: _ChatMessageReactionsVC<ExtraData>?
    ) {
        let popup = _ChatMessagePopupVC<ExtraData>()
        popup.messageContentView = messageContentView
        popup.actionsController = messageActionsController
        popup.reactionsController = messageReactionsController
        let bubbleView = messageContentView.bubbleView ?? messageContentView.bubbleContentContainer
        let bubbleViewFrame = bubbleView.superview!.convert(bubbleView.frame, to: nil)
        popup.messageBubbleViewInsets = UIEdgeInsets(
            top: bubbleViewFrame.origin.y,
            left: bubbleViewFrame.origin.x,
            bottom: messageContentView.frame.height - bubbleViewFrame.height,
            right: messageContentView.frame.width - bubbleViewFrame.origin.x - bubbleViewFrame.width
        )
        popup.modalPresentationStyle = .overFullScreen
        popup.transitioningDelegate = transitionController

        transitionController.messageContentView = messageContentView
        
        rootViewController.present(popup, animated: true)
    }
    
    open func showPreview(for url: URL?) {
        let preview = ChatMessageAttachmentPreviewVC()
        preview.content = url
        
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
