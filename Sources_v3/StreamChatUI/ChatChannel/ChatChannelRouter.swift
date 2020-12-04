//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelRouter<ExtraData: UIExtraDataTypes>: ChatRouter<ChatChannelVC<ExtraData>> {
    open func showMessageActionsPopUp(
        messageContentFrame: CGRect,
        messageData: _ChatMessageGroupPart<ExtraData>,
        messageController: _ChatMessageController<ExtraData>,
        messageActions: [ChatMessageActionItem]
    ) {
        guard let root = rootViewController else { return }

        let actionsController = ChatMessageActionsViewController<ExtraData>()
        actionsController.messageActions = messageActions

        let reactionsController = ChatMessageReactionViewController<ExtraData>()
        reactionsController.messageController = messageController
        
        let popup = ChatMessagePopupViewController<ExtraData>()
        popup.message = messageData
        popup.messageViewFrame = messageContentFrame
        popup.actionsController = actionsController
        popup.reactionsController = reactionsController
        popup.modalPresentationStyle = .overFullScreen
        popup.modalTransitionStyle = .crossDissolve
        
        root.present(popup, animated: true)
    }

    open func showMessageDeletionConfirmationAlert(confirmed: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: "Delete message",
            message: "Are you sure you want to permanently delete this message?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            confirmed(false)
        })
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            confirmed(true)
        })

        let presenter = rootViewController?.presentedViewController ?? rootViewController
        presenter?.present(alert, animated: true)
    }
}
