//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Controller responsible for displaying the channel messages.
@available(iOSApplicationExtension, unavailable)
open class ChatChannelVC:
    _ViewController,
    ThemeProvider,
    ChatMessageListVCDataSource,
    ChatMessageListVCDelegate,
    ChatChannelControllerDelegate {
    /// Controller for observing data changes within the channel.
    open var channelController: ChatChannelController!

    /// User search controller for suggestion users when typing in the composer.
    open lazy var userSuggestionSearchController: ChatUserSearchController =
        channelController.client.userSearchController()

    /// The size of the channel avatar.
    open var channelAvatarSize: CGSize {
        CGSize(width: 32, height: 32)
    }

    public var client: ChatClient {
        channelController.client
    }

//    /// Component responsible for setting the correct offset when keyboard frame is changed.
//    open lazy var keyboardHandler: KeyboardHandler = ComposerKeyboardHandler(
//        composerParentVC: self,
//        composerBottomConstraint: messageComposerBottomConstraint
//    )

    open private(set) lazy var navigationSafeAreaView: UIView = {
        let view = UIView(frame: .zero).withoutAutoresizingMaskConstraints
        view.backgroundColor = appearance.colorPalette.walletTabbarBackground
        return view
    }()

    open private(set) lazy var navigationHeaderView: UIView = {
        let view = UIView(frame: .zero).withoutAutoresizingMaskConstraints
        view.backgroundColor = appearance.colorPalette.walletTabbarBackground
        return view
    }()

    open private(set) lazy var backButton: UIButton = {
        let button = UIButton()
        if #available(iOS 13.0, *) {
            button.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        } else {
            // Fallback on earlier versions
        }
        button.tintColor = .white
        button.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        return button.withoutAutoresizingMaskConstraints
    }()

    /// The message list component responsible to render the messages.
    open lazy var messageListVC: ChatMessageListVC = components
        .messageListVC
        .init()

    /// Controller that handles the composer view
    open private(set) lazy var messageComposerVC = components
        .messageComposerVC
        .init()

    /// Header View
    open private(set) lazy var headerView: ChatChannelHeaderView = components
        .channelHeaderView.init()
        .withoutAutoresizingMaskConstraints

    /// View for displaying the channel image in the navigation bar.
    open private(set) lazy var channelAvatarView = components
        .channelAvatarView.init()
        .withoutAutoresizingMaskConstraints

    public var messageComposerBottomConstraint: NSLayoutConstraint?

    private var loadingPreviousMessages: Bool = false

    override open func setUp() {
        super.setUp()

        messageListVC.delegate = self
        messageListVC.dataSource = self
        messageListVC.client = client

        messageComposerVC.channelController = channelController
        messageComposerVC.userSearchController = userSuggestionSearchController

        channelController.delegate = self
        channelController.synchronize { [weak self] _ in
            self?.messageComposerVC.updateContent()
        }
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.backgroundColor = appearance.colorPalette.background

        view.addSubview(navigationSafeAreaView)
        NSLayoutConstraint.activate([
            navigationSafeAreaView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            navigationSafeAreaView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            navigationSafeAreaView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            navigationSafeAreaView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0)
        ])

        view.addSubview(navigationHeaderView)
        NSLayoutConstraint.activate([
            navigationHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            navigationHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            navigationHeaderView.topAnchor.constraint(equalTo: navigationSafeAreaView.bottomAnchor, constant: 0),
            navigationHeaderView.heightAnchor.constraint(equalToConstant: 44)
        ])

        navigationHeaderView.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: navigationHeaderView.leadingAnchor, constant: 8),
            backButton.centerYAnchor.constraint(equalTo: navigationHeaderView.centerYAnchor, constant: 0),
            backButton.heightAnchor.constraint(equalToConstant: 32),
            backButton.widthAnchor.constraint(equalToConstant: 32)
        ])

        navigationHeaderView.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.centerYAnchor.constraint(equalTo: navigationHeaderView.centerYAnchor, constant: 0),
            headerView.centerXAnchor.constraint(equalTo: navigationHeaderView.centerXAnchor, constant: 0)
        ])
        addChildViewController(messageListVC, targetView: view)
        NSLayoutConstraint.activate([
            messageListVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            messageListVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            messageListVC.view.topAnchor.constraint(equalTo: navigationHeaderView.bottomAnchor, constant: 0),
            //messageListVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
        addChildViewController(messageComposerVC, targetView: view)
        messageComposerVC.view.pin(anchors: [.leading, .trailing], to: view)
        messageComposerVC.view.topAnchor.pin(equalTo: messageListVC.view.bottomAnchor).isActive = true
        messageComposerBottomConstraint = messageComposerVC.view.bottomAnchor.pin(equalTo: view.bottomAnchor)
        messageComposerBottomConstraint?.isActive = true

        navigationHeaderView.addSubview(channelAvatarView)
        channelAvatarView.content = (channelController.channel, client.currentUserId)
        NSLayoutConstraint.activate([
            channelAvatarView.widthAnchor.constraint(equalToConstant: channelAvatarSize.width),
            channelAvatarView.heightAnchor.constraint(equalToConstant: channelAvatarSize.height),
            channelAvatarView.trailingAnchor.constraint(equalTo: navigationHeaderView.trailingAnchor, constant: -8),
            channelAvatarView.centerYAnchor.constraint(equalTo: navigationHeaderView.centerYAnchor, constant: 0)
        ])

        if let cid = channelController.cid {
            headerView.channelController = client.channelController(for: cid)
        }
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        //keyboardHandler.start()
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        resignFirstResponder()

        //keyboardHandler.stop()
    }

    @objc func backAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - ChatMessageListVCDataSource
    
    open func channel(for vc: ChatMessageListVC) -> ChatChannel? {
        channelController.channel
    }

    open func numberOfMessages(in vc: ChatMessageListVC) -> Int {
        channelController.messages.count
    }

    open func chatMessageListVC(_ vc: ChatMessageListVC, messageAt indexPath: IndexPath) -> ChatMessage? {
        guard indexPath.item < channelController.messages.count else { return nil }
        return channelController.messages[indexPath.item]
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        messageLayoutOptionsAt indexPath: IndexPath
    ) -> ChatMessageLayoutOptions {
        guard let channel = channelController.channel else { return [] }

        return components.messageLayoutOptionsResolver.optionsForMessage(
            at: indexPath,
            in: channel,
            with: AnyRandomAccessCollection(channelController.messages),
            appearance: appearance
        )
    }

    // MARK: - ChatMessageListVCDelegate

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        willDisplayMessageAt indexPath: IndexPath
    ) {
        if channelController.state != .remoteDataFetched {
            return
        }

        if indexPath.row < channelController.messages.count - 10 {
            return
        }

        guard !loadingPreviousMessages else {
            return
        }
        loadingPreviousMessages = true

        channelController.loadPreviousMessages(completion: { [weak self] _ in
            self?.loadingPreviousMessages = false
        })
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        didTapOnAction actionItem: ChatMessageActionItem,
        for message: ChatMessage
    ) {
        switch actionItem {
        case is EditActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageComposerVC.content.editMessage(message)
            }
        case is InlineReplyActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageComposerVC.content.quoteMessage(message)
            }
        case is ThreadReplyActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageListVC.showThread(messageId: message.id)
            }
        default:
            return
        }
    }

    var didReadAllMessages: Bool {
        messageListVC.listView.isLastCellFullyVisible
    }

    open func chatMessageListVC(_ vc: ChatMessageListVC, scrollViewDidScroll scrollView: UIScrollView) {
        if didReadAllMessages {
            channelController.markRead()
        }

        if messageListVC.listView.isLastCellFullyVisible, channelController.channel?.isUnread == true {
            // Hide the badge immediately. Temporary solution until CIS-881 is implemented.
            messageListVC.scrollToLatestMessageButton.content = .noUnread
        }
    }

    // MARK: - ChatChannelControllerDelegate

    open func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) {
        if didReadAllMessages {
            channelController.markRead()
        }
        messageListVC.updateMessages(with: changes)
    }

    open func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    ) {
        let channelUnreadCount = channelController.channel?.unreadCount ?? .noUnread
        messageListVC.scrollToLatestMessageButton.content = channelUnreadCount
    }

    open func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingUsers typingUsers: Set<ChatUser>
    ) {
        guard channelController.areTypingEventsEnabled else { return }

        let typingUsersWithoutCurrentUser = typingUsers
            .sorted { $0.id < $1.id }
            .filter { $0.id != self.client.currentUserId }

        if typingUsersWithoutCurrentUser.isEmpty {
            messageListVC.hideTypingIndicator()
        } else {
            messageListVC.showTypingIndicator(typingUsers: typingUsersWithoutCurrentUser)
        }
    }
}
