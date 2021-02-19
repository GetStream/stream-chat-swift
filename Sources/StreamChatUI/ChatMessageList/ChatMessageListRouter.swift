//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageListRouter = _ChatMessageListRouter<NoExtraData>

internal class _ChatMessageListRouter<ExtraData: ExtraDataTypes>: ChatRouter<_ChatMessageListVC<ExtraData>> {
    internal func showMessageActionsPopUp(
        messageContentFrame: CGRect,
        messageData: _ChatMessageGroupPart<ExtraData>,
        messageActionsController: _ChatMessageActionsVC<ExtraData>,
        messageReactionsController: _ChatMessageReactionsVC<ExtraData>?
    ) {
        guard let root = rootViewController else {
            log.error("Can't preset the message action pop up because the root VC is `nil`.")
            return
        }

        let popup = _ChatMessagePopupVC<ExtraData>()
        popup.message = messageData
        popup.messageViewFrame = messageContentFrame
        popup.actionsController = messageActionsController
        popup.reactionsController = messageReactionsController
        popup.modalPresentationStyle = .overFullScreen
        popup.modalTransitionStyle = .crossDissolve

        root.present(popup, animated: true)
    }
    
    internal func showPreview(for attachment: ChatMessageDefaultAttachment) {
        guard let root = rootViewController else {
            log.error("Can't preset the attachment preview because the root VC is `nil`.")
            return
        }

        let preview = ChatMessageAttachmentPreviewVC<ExtraData>()
        preview.content = attachment.type == .file ? attachment.url : attachment.imageURL
        
        let navigation = UINavigationController(rootViewController: preview)
        root.present(navigation, animated: true)
    }

    internal func internalLink(_ link: ChatMessageDefaultAttachment) {
        guard let root = rootViewController else {
            log.error("Can't preset the link preview because the root VC is `nil`.")
            return
        }

        let preview = ChatMessageAttachmentPreviewVC<ExtraData>()
        preview.content = link.url

        let navigation = UINavigationController(rootViewController: preview)
        root.present(navigation, animated: true)
    }
}
