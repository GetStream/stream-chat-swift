//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageListRouter<ExtraData: ExtraDataTypes>: ChatRouter<ChatMessageListVC<ExtraData>> {
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
            title: L10n.Message.Actions.Delete.confirmationTitle,
            message: L10n.Message.Actions.Delete.confirmationMessage,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(
            title: L10n.Alert.Actions.cancel,
            style: .cancel,
            handler: { _ in confirmed(false) }
        ))
        alert.addAction(UIAlertAction(
            title: L10n.Alert.Actions.delete,
            style: .destructive,
            handler: { _ in confirmed(true) }
        ))

        let presenter = rootViewController?.presentedViewController ?? rootViewController
        presenter?.present(alert, animated: true)
    }
    
    open func showPreview(for attachment: _ChatMessageAttachment<ExtraData>) {
        let preview = ChatAttachmentPreviewVC()
        preview.content = attachment.type == .file ? attachment.url : attachment.imageURL

        let navigation = UINavigationController(rootViewController: preview)
        rootViewController?.present(navigation, animated: true)
    }
}
