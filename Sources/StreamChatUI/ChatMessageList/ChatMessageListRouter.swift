//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageListRouter = _ChatMessageListRouter<NoExtraData>

open class _ChatMessageListRouter<ExtraData: ExtraDataTypes>: ChatRouter<_ChatMessageListVC<ExtraData>> {
    open func showMessageActionsPopUp(
        messageContentViewClass: _ChatMessageContentView<ExtraData>.Type,
        messageContentFrame: CGRect,
        messageData: _ChatMessageGroupPart<ExtraData>,
        messageActionsController: _ChatMessageActionsVC<ExtraData>,
        messageReactionsController: _ChatMessageReactionsVC<ExtraData>?
    ) {
        let popup = _ChatMessagePopupVC<ExtraData>()
        popup.messageContentViewClass = messageContentViewClass
        popup.message = messageData
        popup.messageViewFrame = messageContentFrame
        popup.actionsController = messageActionsController
        popup.reactionsController = messageReactionsController
        popup.modalPresentationStyle = .overFullScreen
        popup.modalTransitionStyle = .crossDissolve

        rootViewController.present(popup, animated: false)
    }
    
    open func showPreview(for attachment: ChatMessageDefaultAttachment) {
        let preview = ChatMessageAttachmentPreviewVC<ExtraData>()
        preview.content = attachment.type == .file ? attachment.url : attachment.imageURL
        
        let navigation = UINavigationController(rootViewController: preview)
        rootViewController.present(navigation, animated: true)
    }

    open func openLink(_ link: ChatMessageDefaultAttachment) {
        let preview = ChatMessageAttachmentPreviewVC<ExtraData>()
        preview.content = link.url

        let navigation = UINavigationController(rootViewController: preview)
        rootViewController.present(navigation, animated: true)
    }
}
