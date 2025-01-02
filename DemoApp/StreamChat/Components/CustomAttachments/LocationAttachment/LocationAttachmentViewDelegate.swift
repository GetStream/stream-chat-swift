//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI

protocol LocationAttachmentViewDelegate: ChatMessageContentViewDelegate {
    func didTapOnStaticLocationAttachment(
        _ attachment: ChatMessageStaticLocationAttachment
    )

    func didTapOnLiveLocationAttachment(
        _ attachment: ChatMessageLiveLocationAttachment
    )

    func didTapOnStopSharingLocation(
        _ attachment: ChatMessageLiveLocationAttachment
    )
}

extension DemoChatMessageListVC: LocationAttachmentViewDelegate {
    func didTapOnStaticLocationAttachment(_ attachment: ChatMessageStaticLocationAttachment) {
        let messageController = client.messageController(
            cid: attachment.id.cid,
            messageId: attachment.id.messageId
        )
        let mapViewController = LocationDetailViewController(
            messageController: messageController
        )
        navigationController?.pushViewController(mapViewController, animated: true)
    }

    func didTapOnLiveLocationAttachment(_ attachment: ChatMessageLiveLocationAttachment) {
        let messageController = client.messageController(
            cid: attachment.id.cid,
            messageId: attachment.id.messageId
        )
        let mapViewController = LocationDetailViewController(
            messageController: messageController
        )
        navigationController?.pushViewController(mapViewController, animated: true)
    }

    func didTapOnStopSharingLocation(_ attachment: ChatMessageLiveLocationAttachment) {
        client
            .channelController(for: attachment.id.cid)
            .stopLiveLocationSharing()
    }
}
