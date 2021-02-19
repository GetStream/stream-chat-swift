//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatThreadVC = _ChatThreadVC<NoExtraData>

internal class _ChatThreadVC<ExtraData: ExtraDataTypes>: _ChatVC<ExtraData> {
    internal var controller: _ChatMessageController<ExtraData>!

    // MARK: - Life Cycle

    override internal func setUp() {
        super.setUp()

        controller.setDelegate(self)
        controller.synchronize()

        messageComposerViewController.threadParentMessage = controller.message
    }

    override internal func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        messageList.scrollToMostRecentMessageIfNeeded()
    }

    override func makeNavbarListener(
        _ handler: @escaping (ChatChannelNavigationBarListener<ExtraData>.NavbarData) -> Void
    ) -> ChatChannelNavigationBarListener<ExtraData>? {
        let channelName = channelController.channel?.name ?? "love"
        handler(ChatChannelNavigationBarListener<ExtraData>.NavbarData(title: "Thread Reply", subtitle: "with \(channelName)"))
        return nil
    }

    // MARK: - ChatMessageListVCDataSource

    override internal func numberOfMessagesInChatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>) -> Int {
        controller.replies.count + 1
    }

    override internal func chatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>, messageAt index: Int) -> _ChatMessage<ExtraData> {
        if index == controller.replies.count {
            return controller.message!
        }
        return controller.replies[index]
    }

    override internal func loadMoreMessagesForChatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>) {
        controller.loadPreviousReplies()
    }

    override internal func chatMessageListVC(
        _ vc: _ChatMessageListVC<ExtraData>,
        replyMessageFor message: _ChatMessage<ExtraData>,
        at index: Int
    ) -> _ChatMessage<ExtraData>? {
        nil
    }

    override internal func chatMessageListVC(
        _ vc: _ChatMessageListVC<ExtraData>,
        controllerFor message: _ChatMessage<ExtraData>
    ) -> _ChatMessageController<ExtraData> {
        controller.client.messageController(
            cid: controller.cid,
            messageId: message.id
        )
    }
}

// MARK: - ChatChannelControllerDelegate

extension _ChatThreadVC: _ChatMessageControllerDelegate {
    internal func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeReplies changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
        messageList.updateMessages(with: changes)
    }
}
