//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import SwiftUI
import UIKit

/// A custom message list view controller for livestream channels that uses LivestreamChannelController
/// instead of MessageController and shows a custom bottom sheet for message actions.
class DemoLivestreamChatMessageListVC: ChatMessageListVC {
    public weak var livestreamChannelController: LivestreamChannelController?

    override func didSelectMessageCell(at indexPath: IndexPath) {
        guard
            let cell = listView.cellForRow(at: indexPath) as? ChatMessageCell,
            let messageContentView = cell.messageContentView,
            let message = messageContentView.content,
            message.isInteractionEnabled == true,
            let livestreamChannelController = livestreamChannelController
        else { return }

        let actionsController = DemoLivestreamMessageActionsVC()
        actionsController.message = message
        actionsController.livestreamChannelController = livestreamChannelController
        actionsController.delegate = self

        actionsController.modalPresentationStyle = .pageSheet
        
        if #available(iOS 16.0, *) {
            if let sheetController = actionsController.sheetPresentationController {
                sheetController.detents = [
                    .custom { _ in
                        180
                    }
                ]
                sheetController.prefersGrabberVisible = true
                sheetController.preferredCornerRadius = 16
            }
        }
        
        present(actionsController, animated: true)
    }
    
    override func messageContentViewDidTapOnReactionsView(_ indexPath: IndexPath?) {
        guard
            let indexPath = indexPath,
            let cell = listView.cellForRow(at: indexPath) as? ChatMessageCell,
            let messageContentView = cell.messageContentView,
            let message = messageContentView.content,
            let livestreamChannelController = livestreamChannelController
        else { return }

        let reactionsView = DemoLivestreamReactionsListView(
            message: message,
            controller: livestreamChannelController
        )

        let hostingController = UIHostingController(rootView: reactionsView)
        hostingController.modalPresentationStyle = .pageSheet
        
        if #available(iOS 16.0, *) {
            if let sheetController = hostingController.sheetPresentationController {
                sheetController.detents = [.medium(), .large()]
                sheetController.prefersGrabberVisible = true
                sheetController.preferredCornerRadius = 16
            }
        }
        
        present(hostingController, animated: true)
    }
}

// MARK: - LivestreamMessageActionsVCDelegate

extension DemoLivestreamChatMessageListVC: LivestreamMessageActionsVCDelegate {
    public func livestreamMessageActionsVCDidFinish(_ vc: DemoLivestreamMessageActionsVC) {
        dismiss(animated: true)
    }
    
    func livestreamMessageActionsVC(
        _ vc: DemoLivestreamMessageActionsVC,
        message: ChatMessage,
        didTapOnActionItem actionItem: ChatMessageActionItem
    ) {
        delegate?.chatMessageListVC(self, didTapOnAction: actionItem, for: message)
    }
}
