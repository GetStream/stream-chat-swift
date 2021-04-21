//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatChannelVC = _ChatChannelVC<NoExtraData>

open class _ChatChannelVC<ExtraData: ExtraDataTypes>: _ChatVC<ExtraData> {
    // MARK: - Properties

    public lazy var router = uiConfig.navigation.channelDetailRouter.init(rootViewController: self)
    
    // MARK: - Life Cycle
    
    override open func setUp() {
        super.setUp()

        channelController.setDelegate(self)
        channelController.synchronize()
    }

    override func makeNavbarListener(
        _ handler: @escaping (ChatChannelNavigationBarListener<ExtraData>.NavbarData) -> Void
    ) -> ChatChannelNavigationBarListener<ExtraData>? {
        guard let channel = channelController.channel else { return nil }
        let navbarListener = ChatChannelNavigationBarListener.make(
            for: channel.cid,
            in: channelController.client,
            using: uiConfig.channelList.channelNamer
        )
        navbarListener.onDataChange = handler
        return navbarListener
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        
        guard let channel = channelController.channel else { return }

        let avatar = _ChatChannelAvatarView<ExtraData>()
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.heightAnchor.pin(equalToConstant: 32).isActive = true
        avatar.widthAnchor.pin(equalToConstant: 32).isActive = true
        avatar.content = (channel: channel, currentUserId: channelController.client.currentUserId)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: avatar)
        navigationItem.largeTitleDisplayMode = .never
    }

    // MARK: - ChatMessageListVCDataSource

    override public func numberOfMessagesInChatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>) -> Int {
        channelController.messages.count
    }

    override public func chatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>, messageAt index: Int) -> _ChatMessage<ExtraData> {
        channelController.messages[index]
    }

    override public func loadMoreMessagesForChatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>) {
        channelController.loadNextMessages()
    }

    override public func chatMessageListVC(
        _ vc: _ChatMessageListVC<ExtraData>,
        replyMessageFor message: _ChatMessage<ExtraData>,
        at index: Int
    ) -> _ChatMessage<ExtraData>? {
        message.quotedMessageId.flatMap { channelController.dataStore.message(id: $0) }
    }

    override public func chatMessageListVC(
        _ vc: _ChatMessageListVC<ExtraData>,
        controllerFor message: _ChatMessage<ExtraData>
    ) -> _ChatMessageController<ExtraData> {
        channelController.client.messageController(
            cid: channelController.cid!,
            messageId: message.id
        )
    }

    // MARK: - ChatMessageListVCDelegate

    override public func chatMessageListVC(
        _ vc: _ChatMessageListVC<ExtraData>,
        didTapOnRepliesFor message: _ChatMessage<ExtraData>
    ) {
        router.showThreadDetail(for: message, within: channelController)
    }
}

// MARK: - _ChatChannelControllerDelegate

extension _ChatChannelVC: _ChatChannelControllerDelegate {
    public func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateMessages changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
        messageList.updateMessages(with: changes)
    }

    public func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didChangeTypingMembers typingMembers: Set<_ChatChannelMember<ExtraData.User>>
    ) {
        if typingMembers.contains(where: { member in member.id == self.channelController.client.currentUserId }) {
            let typingMembersWithoutCurrentUser = typingMembers.filter { $0.id != self.channelController.client.currentUserId }
            showTypingIndicatorIfNeeded(typingMembers: typingMembersWithoutCurrentUser)
        } else {
            // Current user is not member of the room but can see that someone is actually typing
            showTypingIndicatorIfNeeded(typingMembers: typingMembers)
        }
    }

    private func showTypingIndicatorIfNeeded(typingMembers: Set<_ChatChannelMember<ExtraData.User>>) {
        if typingMembers.isEmpty {
            typingIndicatorView.isHidden = true
        } else {
            // If we somehow cannot fetch any member name, we simply show that `Someone is typing`
            guard let member = typingMembers.first(where: { user in user.name != nil }), let name = member.name else {
                typingIndicatorView.content = L10n.MessageList.TypingIndicator.typingUnknown
                typingIndicatorView.isHidden = false
                return
            }

            typingIndicatorView.content = L10n.MessageList.TypingIndicator.users(name, typingMembers.count - 1)
            typingIndicatorView.isHidden = false
        }
    }
}
