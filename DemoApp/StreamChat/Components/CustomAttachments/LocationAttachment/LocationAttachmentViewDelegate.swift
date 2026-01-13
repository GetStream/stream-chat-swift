//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

protocol LocationAttachmentViewDelegate: ChatMessageContentViewDelegate {
    func didTapOnLocation(
        _ location: SharedLocation
    )

    func didTapOnStopSharingLocation(
        _ location: SharedLocation
    )
}

extension DemoChatMessageListVC: LocationAttachmentViewDelegate {
    func didTapOnLocation(_ location: SharedLocation) {
        let messageController = client.messageController(
            cid: location.channelId,
            messageId: location.messageId
        )
        showDetailViewController(messageController: messageController)
    }

    func didTapOnStopSharingLocation(_ location: SharedLocation) {
        client
            .messageController(cid: location.channelId, messageId: location.messageId)
            .stopLiveLocationSharing { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    self.presentAlert(
                        title: "Could not stop sharing location",
                        message: error.localizedDescription
                    )
                }
            }
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
