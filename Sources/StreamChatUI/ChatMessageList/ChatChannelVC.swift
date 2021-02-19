//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatChannelVC = _ChatChannelVC<NoExtraData>

public class _ChatChannelVC<ExtraData: ExtraDataTypes>: _ChatVC<ExtraData> {
    // MARK: - Properties

    internal lazy var router = uiConfig.navigation.channelDetailRouter.init(rootViewController: self)
    
    // MARK: - Life Cycle
    
    override internal func setUp() {
        super.setUp()

        channelController.setDelegate(self)
        channelController.synchronize()
    }

    override func makeNavbarListener(
        _ handler: @escaping (ChatChannelNavigationBarListener<ExtraData>.NavbarData) -> Void
    ) -> ChatChannelNavigationBarListener<ExtraData>? {
        guard let channel = channelController.channel else { return nil }
        let namer = uiConfig.messageList.channelNamer.init()
        let navbarListener = ChatChannelNavigationBarListener.make(for: channel.cid, in: channelController.client, using: namer)
        navbarListener.onDataChange = handler
        return navbarListener
    }

    override internal func defaultAppearance() {
        super.defaultAppearance()

        guard let channel = channelController.channel else { return }

        let avatar = _ChatChannelAvatarView<ExtraData>()
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.heightAnchor.pin(equalToConstant: 32).isActive = true
        avatar.widthAnchor.pin(equalToConstant: 32).isActive = true
        avatar.content = .channelAndUserId(channel: channel, currentUserId: channelController.client.currentUserId)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: avatar)
        navigationItem.largeTitleDisplayMode = .never
    }

    // MARK: - ChatMessageListVCDataSource

    override internal func numberOfMessagesInChatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>) -> Int {
        channelController.messages.count
    }

    override internal func chatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>, messageAt index: Int) -> _ChatMessage<ExtraData> {
        channelController.messages[index]
    }

    override internal func loadMoreMessagesForChatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>) {
        channelController.loadNextMessages()
    }

    override internal func chatMessageListVC(
        _ vc: _ChatMessageListVC<ExtraData>,
        replyMessageFor message: _ChatMessage<ExtraData>,
        at index: Int
    ) -> _ChatMessage<ExtraData>? {
        message.quotedMessageId.flatMap { channelController.dataStore.message(id: $0) }
    }

    override internal func chatMessageListVC(
        _ vc: _ChatMessageListVC<ExtraData>,
        controllerFor message: _ChatMessage<ExtraData>
    ) -> _ChatMessageController<ExtraData> {
        channelController.client.messageController(
            cid: channelController.cid!,
            messageId: message.id
        )
    }

    // MARK: - ChatMessageListVCDelegate

    override internal func chatMessageListVC(
        _ vc: _ChatMessageListVC<ExtraData>,
        didTapOnRepliesFor message: _ChatMessage<ExtraData>
    ) {
        router.showThreadDetail(for: message, within: channelController)
    }
}

// MARK: - _ChatChannelControllerDelegate

extension _ChatChannelVC: _ChatChannelControllerDelegate {
    public typealias ExtraData = ExtraData
    public func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateMessages changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
        messageList.updateMessages(with: changes)
    }
}
