//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI

protocol LocationAttachmentViewDelegate: ChatMessageContentViewDelegate {
    func didTapOnLocationAttachment(
        _ attachment: ChatMessageStaticLocationAttachment
    )

    func didTapOnStopSharingLocation(
        _ attachment: ChatMessageLiveLocationAttachment
    )
}

extension DemoChatMessageListVC: LocationAttachmentViewDelegate {
    func didTapOnLocationAttachment(_ attachment: ChatMessageStaticLocationAttachment) {
        let mapViewController = LocationDetailViewController(locationAttachment: attachment)
        navigationController?.pushViewController(mapViewController, animated: true)
    }

    func didTapOnStopSharingLocation(_ attachment: ChatMessageLiveLocationAttachment) {
        client
            .channelController(for: attachment.id.cid)
            .stopLiveLocationSharing()
    }
}
