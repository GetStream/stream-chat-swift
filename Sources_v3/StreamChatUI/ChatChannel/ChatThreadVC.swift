//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatThreadVC<ExtraData: ExtraDataTypes>: ChatVC<ExtraData> {
    public var controller: _ChatMessageController<ExtraData>!

    // MARK: - Life Cycle

    override open func setUp() {
        super.setUp()

        controller.setDelegate(self)
        controller.synchronize()

        messageComposerViewController.threadParentMessage = controller.message
    }

    override func makeNavbarListener(
        _ handler: @escaping (ChatChannelNavigationBarListener<ExtraData>.NavbarData) -> Void
    ) -> ChatChannelNavigationBarListener<ExtraData>? {
        let channelName = channelController.channel?.name ?? "love"
        handler(ChatChannelNavigationBarListener<ExtraData>.NavbarData(title: "Thread Reply", subtitle: "with \(channelName)"))
        return nil
    }

    // MARK: - ChatMessageListVCDataSource

    override public func numberOfMessagesInChatMessageListVC(_ vc: ChatMessageListVC<ExtraData>) -> Int {
        controller.replies.count + 1
    }

    override public func chatMessageListVC(_ vc: ChatMessageListVC<ExtraData>, messageAt index: Int) -> _ChatMessage<ExtraData> {
        if index == controller.replies.count {
            return controller.message!
        }
        return controller.replies[index]
    }

    override public func loadMoreMessagesForChatMessageListVC(_ vc: ChatMessageListVC<ExtraData>) {
        controller.loadPreviousReplies()
    }

    override public func chatMessageListVC(
        _ vc: ChatMessageListVC<ExtraData>,
        replyMessageFor message: _ChatMessage<ExtraData>,
        at index: Int
    ) -> _ChatMessage<ExtraData>? {
        nil
    }

    override public func chatMessageListVC(
        _ vc: ChatMessageListVC<ExtraData>,
        controllerFor message: _ChatMessage<ExtraData>
    ) -> _ChatMessageController<ExtraData> {
        controller.client.messageController(
            cid: controller.cid,
            messageId: message.id
        )
    }
}

// MARK: - _ChatChannelControllerDelegate

extension ChatThreadVC: _MessageControllerDelegate {
    public func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeReplies changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
        messageList.updateMessages(with: changes)
    }
}
