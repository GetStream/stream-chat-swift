//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI

protocol LocationAttachmentViewDelegate: ChatMessageContentViewDelegate {
    func didTapOnLocationAttachment(
        _ attachment: ChatMessageStaticLocationAttachment
    )
}

extension DemoChatMessageListVC: LocationAttachmentViewDelegate {
    func didTapOnLocationAttachment(_ attachment: ChatMessageStaticLocationAttachment) {
        let mapViewController = LocationDetailViewController(locationAttachment: attachment)
        navigationController?.pushViewController(mapViewController, animated: true)
    }
}
