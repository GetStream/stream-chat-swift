//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatThreadVC = _ChatThreadVC<NoExtraData>

open class _ChatThreadVC<ExtraData: ExtraDataTypes>: _ChatVC<ExtraData> {
    public var controller: _ChatMessageController<ExtraData>!

    // MARK: - Life Cycle

    override open func setUp() {
        super.setUp()

        controller.setDelegate(self)
        controller.synchronize()

        messageComposerViewController.threadParentMessage = controller.message
    }

    override open func viewDidAppear(_ animated: Bool) {
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

    override public func numberOfMessagesInChatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>) -> Int {
        controller.replies.count + 1
    }

    override public func chatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>, messageAt index: Int) -> _ChatMessage<ExtraData> {
        if index == controller.replies.count {
            return controller.message!
        }
        return controller.replies[index]
    }

    override public func loadMoreMessagesForChatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>) {
        controller.loadPreviousReplies()
    }

    override public func chatMessageListVC(
        _ vc: _ChatMessageListVC<ExtraData>,
        replyMessageFor message: _ChatMessage<ExtraData>,
        at index: Int
    ) -> _ChatMessage<ExtraData>? {
        nil
    }

    override public func chatMessageListVC(
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
    public func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeReplies changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
        messageList.updateMessages(with: changes)
    }
}
