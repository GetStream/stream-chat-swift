//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageListRouter<ExtraData: ExtraDataTypes>: ChatRouter<ChatMessageListVC<ExtraData>>,
                                                             ChatMessageActionsVCDelegate {
    open func showMessageActionsPopUp(
        messageContentFrame: CGRect,
        messageData: _ChatMessageGroupPart<ExtraData>,
        messageActionsController: ChatMessageActionsVC<ExtraData>,
        messageReactionsController: ChatMessageReactionViewController<ExtraData>?
    ) {
        let popup = ChatMessagePopupViewController<ExtraData>()
        popup.message = messageData
        popup.messageViewFrame = messageContentFrame
        popup.actionsController = messageActionsController
        popup.actionsController.delegate = .init(delegate: self)
        popup.reactionsController = messageReactionsController
        popup.modalPresentationStyle = .overFullScreen
        popup.modalTransitionStyle = .crossDissolve

        rootViewController.present(popup, animated: true)
    }
    
    open func showPreview(for attachment: _ChatMessageAttachment<ExtraData>) {
        let preview = ChatAttachmentPreviewVC()
        preview.content = attachment.type == .file ? attachment.url : attachment.imageURL
        
        let navigation = UINavigationController(rootViewController: preview)
        rootViewController.present(navigation, animated: true)
    }

    // MARK: - ChatMessageActionsVCDelegate

    open func chatMessageActionsVC(
        _ vc: ChatMessageActionsVC<ExtraData>,
        didTapOnInlineReplyFor message: _ChatMessage<ExtraData>
    ) {
        rootViewController.delegate?.didTapOnInlineReply?(rootViewController, message)
        rootViewController.dismiss(animated: true)
    }

    open func chatMessageActionsVC(
        _ vc: ChatMessageActionsVC<ExtraData>,
        didTapOnThreadReplyFor message: _ChatMessage<ExtraData>
    ) {
        rootViewController.dismiss(animated: true)
    }

    open func chatMessageActionsVC(
        _ vc: ChatMessageActionsVC<ExtraData>,
        didTapOnEdit message: _ChatMessage<ExtraData>
    ) {
        rootViewController.delegate?.didTapOnEdit?(rootViewController, message)
        rootViewController.dismiss(animated: true)
    }

    open func chatMessageActionsVCDidFinish(_ vc: ChatMessageActionsVC<ExtraData>) {
        rootViewController.dismiss(animated: true)
    }
}
