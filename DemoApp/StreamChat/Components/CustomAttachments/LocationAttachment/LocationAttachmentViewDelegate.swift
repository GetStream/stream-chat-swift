//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@_spi(ExperimentalLocation)
import StreamChat
import StreamChatUI
import UIKit

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
        showDetailViewController(messageController: messageController)
    }

    func didTapOnLiveLocationAttachment(_ attachment: ChatMessageLiveLocationAttachment) {
        let messageController = client.messageController(
            cid: attachment.id.cid,
            messageId: attachment.id.messageId
        )
        showDetailViewController(messageController: messageController)
    }

    func didTapOnStopSharingLocation(_ attachment: ChatMessageLiveLocationAttachment) {
        client
            .channelController(for: attachment.id.cid)
            .stopLiveLocationSharing()
    }

    private func showDetailViewController(messageController: ChatMessageController) {
        let mapViewController = LocationDetailViewController(
            messageController: messageController
        )
        if UIDevice.current.userInterfaceIdiom == .pad {
            let nav = UINavigationController(rootViewController: mapViewController)
            navigationController?.present(nav, animated: true)
            return
        }
        navigationController?.pushViewController(mapViewController, animated: true)
    }
}
