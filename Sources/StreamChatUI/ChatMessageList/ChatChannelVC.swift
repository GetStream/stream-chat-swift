//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatChannelVC = _ChatChannelVC<NoExtraData>

open class _ChatChannelVC<ExtraData: ExtraDataTypes>: _ViewController, UIConfigProvider, _ChatMessageListVCDataSource, _ChatMessageListVCDelegate, _ChatMessageComposerViewControllerDelegate {
    
    // MARK: - Properties
    
    public var channelController: _ChatChannelController<ExtraData>!
    public lazy var userSuggestionSearchController: _ChatUserSearchController<ExtraData> = channelController.client.userSearchController()

    public private(set) lazy var messageComposerViewController = uiConfig
        .messageComposer
        .messageComposerViewController
        .init()

    public private(set) lazy var messageList = uiConfig
        .messageList
        .messageListVC
        .init()
    
    public private(set) lazy var router = uiConfig.navigation.channelDetailRouter.init(rootViewController: self)

    private var navbarListener: ChatChannelNavigationBarListener<ExtraData>?
    
    private var messageComposerBottomConstraint: NSLayoutConstraint?
    
    // MARK: - Life Cycle
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        resignFirstResponder()
    }
    
    override open func setUp() {
        super.setUp()
        
        messageComposerViewController.delegate = .wrap(self)
        messageComposerViewController.controller = channelController
        messageComposerViewController.userSuggestionSearchController = userSuggestionSearchController

        messageList.delegate = .wrap(self)
        messageList.dataSource = .wrap(self)

        userSuggestionSearchController.search(term: nil)

        channelController.setDelegate(self)
        channelController.synchronize()
    }
    
    open override func setUpLayout() {
        super.setUpLayout()
        
        messageList.view.translatesAutoresizingMaskIntoConstraints = false
        messageComposerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        addChildViewController(messageList, targetView: view)
        addChildViewController(messageComposerViewController, targetView: view)

        messageList.view.leadingAnchor.pin(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        messageList.view.trailingAnchor.pin(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        messageList.view.topAnchor.pin(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        messageList.view.bottomAnchor.pin(equalTo: messageComposerViewController.view.topAnchor).isActive = true

        messageComposerViewController.view.leadingAnchor.pin(equalTo: view.safeAreaLayoutGuide.leadingAnchor)
            .isActive = true
        messageComposerViewController.view.trailingAnchor.pin(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
            .isActive = true
        messageComposerBottomConstraint =
            messageComposerViewController.view.bottomAnchor.pin(equalTo: view.bottomAnchor)
        messageComposerBottomConstraint?.isActive = true
    }

    override public func defaultAppearance() {
        super.defaultAppearance()
        
        view.backgroundColor = uiConfig.colorPalette.background
        let title = UILabel()
        title.textAlignment = .center
        title.font = uiConfig.font.headlineBold

        let subtitle = UILabel()
        subtitle.textAlignment = .center
        subtitle.font = uiConfig.font.caption1
        subtitle.textColor = uiConfig.colorPalette.subtitleText

        let titleView = UIStackView(arrangedSubviews: [title, subtitle])
        titleView.axis = .vertical

        navigationItem.titleView = titleView

        guard let channel = channelController.channel else { return }
        
        let navbarListener = ChatChannelNavigationBarListener.make(
            for: channel.cid,
            in: channelController.client,
            using: uiConfig.channelList.channelNamer
        )
        navbarListener.onDataChange = { data in
            title.text = data.title
            subtitle.text = data.subtitle
        }
        self.navbarListener = navbarListener

        let avatar = _ChatChannelAvatarView<ExtraData>()
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.heightAnchor.pin(equalToConstant: 32).isActive = true
        avatar.widthAnchor.pin(equalToConstant: 32).isActive = true
        avatar.content = (channel: channel, currentUserId: channelController.client.currentUserId)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: avatar)
        navigationItem.largeTitleDisplayMode = .never
    }

    // MARK: - ChatMessageListVCDataSource

    public func numberOfMessagesInChatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>) -> Int {
        channelController.messages.count
    }

    public func chatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>, messageAt index: Int) -> _ChatMessage<ExtraData> {
        channelController.messages[index]
    }

    public func loadMoreMessagesForChatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>) {
        channelController.loadNextMessages()
    }

    public func chatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>, replyMessageFor message: _ChatMessage<ExtraData>, at index: Int) -> _ChatMessage<ExtraData>? {
        message.quotedMessageId.flatMap { channelController.dataStore.message(id: $0) }
    }

    public func chatMessageListVC(
        _ vc: _ChatMessageListVC<ExtraData>,
        controllerFor message: _ChatMessage<ExtraData>
    ) -> _ChatMessageController<ExtraData> {
        channelController.client.messageController(
            cid: channelController.cid!,
            messageId: message.id
        )
    }

    // MARK: - ChatMessageListVCDelegate
    
    public func chatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>, didSelectMessageAt index: Int) {
        let selectedMessage = chatMessageListVC(vc, messageAt: index)
        debugPrint(selectedMessage)
    }
    
    public func chatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>, didTapOnRepliesFor message: _ChatMessage<ExtraData>) {
        router.showThreadDetail(for: message, within: channelController)
    }
    
    public func chatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>, didTapOnInlineReplyFor message: _ChatMessage<ExtraData>) {
        messageComposerViewController.state = .quote(message)
    }
    
    public func chatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>, didTapOnEdit message: _ChatMessage<ExtraData>) {
        messageComposerViewController.state = .edit(message)
    }
    
    public func messageComposerViewControllerDidSendMessage(_ vc: _ChatMessageComposerVC<ExtraData>) {
        messageList.setNeedsScrollToMostRecentMessage()
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
}
