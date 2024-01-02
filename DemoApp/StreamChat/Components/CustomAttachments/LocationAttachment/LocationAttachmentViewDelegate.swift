//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI

protocol LocationAttachmentViewDelegate: ChatMessageContentViewDelegate {
    func didTapOnLocationAttachment(
        _ attachment: ChatMessageLocationAttachment
    )
}

extension DemoChatMessageListVC: LocationAttachmentViewDelegate {
    func didTapOnLocationAttachment(_ attachment: ChatMessageLocationAttachment) {
        let mapViewController = LocationDetailViewController(locationAttachment: attachment)
        navigationController?.pushViewController(mapViewController, animated: true)
    }
}
