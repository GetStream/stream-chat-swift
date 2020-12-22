//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageListRouter<ExtraData: ExtraDataTypes>: ChatRouter<ChatMessageListVC<ExtraData>> {
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
        popup.actionsController.delegate = .init(
            didTapOnInlineReply: { [weak rootViewController] in
                guard let root = rootViewController else { return }
                root.delegate?.didTapOnInlineReply?(root, $1)
                root.dismiss(animated: true)
            },
            didTapOnThreadReply: { [weak rootViewController] _, _ in
                rootViewController?.dismiss(animated: true)
            },
            didTapOnEdit: { [weak rootViewController] in
                guard let root = rootViewController else { return }
                root.delegate?.didTapOnEdit?(root, $1)
                root.dismiss(animated: true)
            },
            didFinish: { [weak rootViewController] _ in
                rootViewController?.dismiss(animated: true)
            }
        )
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
}
