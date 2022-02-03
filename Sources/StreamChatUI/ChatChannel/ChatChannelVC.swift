//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension Notification.Name {
    public static let showTabbar = Notification.Name("kStreamChatshowTabbar")
    public static let hideTabbar = Notification.Name("kStreamHideTabbar")
    public static let showDaoShareScreen = Notification.Name("showDaoShareScreen")
}

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

    /// Listen to keyboard observer or not
    open var enableKeyboardObserver = false

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
    open lazy var keyboardHandler: KeyboardHandler = ComposerKeyboardHandler(
        composerParentVC: self,
        composerBottomConstraint: messageComposerBottomConstraint
    )

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

    open private(set) lazy var moreButton: UIButton = {
        let button = UIButton()
        button.setImage(appearance.images.moreVertical, for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(moreButtonAction), for: .touchUpInside)
        return button.withoutAutoresizingMaskConstraints
    }()

    open private(set) lazy var rightStackView: UIStackView = {
        let stack = UIStackView().withoutAutoresizingMaskConstraints
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        stack.distribution = .fillProportionally
        return stack
    }()

    open private(set) lazy var shareView: UIView = {
        let view = UIView(frame: .zero).withoutAutoresizingMaskConstraints
        view.backgroundColor = appearance.colorPalette.walletTabbarBackground
        return view
    }()

    private(set) lazy var shareButton: UIButton = {
        let button = UIButton()
        button.setImage(appearance.images.arrowUpRightSquare, for: .normal)
        button.tintColor = appearance.colorPalette.themeBlue
        button.setTitle(" SHARE", for: .normal)
        button.setTitleColor(appearance.colorPalette.themeBlue, for: .normal)
        button.titleLabel?.font =  UIFont.systemFont(ofSize: 15, weight: .semibold)
        button.addTarget(self, action: #selector(shareAction), for: .touchUpInside)
        return button.withoutAutoresizingMaskConstraints
    }()

    open private(set) lazy var backButton: UIButton = {
        let button = UIButton()
        button.setImage(appearance.images.backCircle, for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        return button.withoutAutoresizingMaskConstraints
    }()

    open private(set) lazy var closePinButton: UIButton = {
        let button = UIButton()
        button.setImage(appearance.images.closeBold, for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(closePinViewAction), for: .touchUpInside)
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

        navigationHeaderView.addSubview(rightStackView)
        rightStackView.addArrangedSubview(channelAvatarView)
        if channelController.channel?.type == .dao {
            rightStackView.addArrangedSubview(moreButton)
            moreButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        }

        NSLayoutConstraint.activate([
            rightStackView.centerYAnchor.constraint(equalTo: navigationHeaderView.centerYAnchor, constant: 0),
            rightStackView.trailingAnchor.constraint(equalTo: navigationHeaderView.trailingAnchor, constant: -8),
            channelAvatarView.widthAnchor.constraint(equalToConstant: channelAvatarSize.width),
            channelAvatarView.heightAnchor.constraint(equalToConstant: channelAvatarSize.height),
        ])

        navigationHeaderView.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.centerYAnchor.constraint(equalTo: navigationHeaderView.centerYAnchor, constant: 0),
            headerView.centerXAnchor.constraint(equalTo: navigationHeaderView.centerXAnchor, constant: 0),
            headerView.widthAnchor.constraint(equalTo: navigationHeaderView.widthAnchor, multiplier: 0.6)
        ])

        addChildViewController(messageListVC, targetView: view)
        NSLayoutConstraint.activate([
            messageListVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            messageListVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            messageListVC.view.topAnchor.constraint(equalTo: navigationHeaderView.bottomAnchor, constant: 0),
        ])
        addChildViewController(messageComposerVC, targetView: view)
        messageComposerVC.view.pin(anchors: [.leading, .trailing], to: view)
        messageComposerVC.view.topAnchor.pin(equalTo: messageListVC.view.bottomAnchor).isActive = true
        messageComposerBottomConstraint = messageComposerVC.view.bottomAnchor.pin(equalTo: view.bottomAnchor)
        messageComposerBottomConstraint?.isActive = true

        view.addSubview(shareView)
        NSLayoutConstraint.activate([
            shareView.heightAnchor.constraint(equalToConstant: 52),
            shareView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            shareView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            shareView.topAnchor.constraint(equalTo: navigationHeaderView.bottomAnchor, constant: 0)
        ])

        shareView.addSubview(shareButton)
        NSLayoutConstraint.activate([
            shareButton.centerXAnchor.constraint(equalTo: shareView.centerXAnchor, constant: 0),
            shareButton.centerYAnchor.constraint(equalTo: shareView.centerYAnchor, constant: 0),
            shareButton.heightAnchor.constraint(equalToConstant: 25),
        ])

        shareView.addSubview(closePinButton)
        NSLayoutConstraint.activate([
            closePinButton.trailingAnchor.constraint(equalTo: shareView.trailingAnchor, constant: -20),
            closePinButton.centerYAnchor.constraint(equalTo: shareView.centerYAnchor, constant: 0),
            closePinButton.widthAnchor.constraint(equalToConstant: 20),
            closePinButton.heightAnchor.constraint(equalToConstant: 20)
        ])

        if let cid = channelController.cid {
            headerView.channelController = client.channelController(for: cid)
        }
        if channelController.channelQuery.type == .announcement {
            messageComposerVC.composerView.isUserInteractionEnabled = false
            messageComposerVC.composerView.alpha = 0.5
            headerView.titleContainerView.subtitleLabel.isHidden = true
            channelAvatarView.isHidden = true
        } else {
            messageComposerVC.composerView.isUserInteractionEnabled = true
            messageComposerVC.composerView.alpha = 1.0
            channelAvatarView.isHidden = false
        }
        if #available(iOS 13.0, *) {
            if channelController.channel?.type == .privateMessaging {
                let interaction = UIContextMenuInteraction(delegate: self)
                channelAvatarView.addInteraction(interaction)
            }
        }
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        shareView.isHidden = true
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: .hideTabbar, object: nil)
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if enableKeyboardObserver {
            keyboardHandler.start()
        }
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        resignFirstResponder()
        if enableKeyboardObserver {
            keyboardHandler.stop()
        }
    }

    @objc func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: .showTabbar, object: nil)
    }

    @objc func shareAction(_ sender: Any) {
        guard let extraData = channelController.channel?.extraData,
              channelController.channel?.type == .dao else {
            return
        }
        var userInfo = [AnyHashable: Any]()
        userInfo["extraData"] = channelController.channel?.extraData
        NotificationCenter.default.post(name: .showDaoShareScreen, object: nil, userInfo: userInfo)
    }

    @objc func moreButtonAction(_ sender: Any) {
        shareView.isHidden = false
    }

    @objc func closePinViewAction(_ sender: Any) {
        shareView.isHidden = true
    }

    private func getGroupLink() -> String? {
        guard let extraData = channelController.channel?.extraData["joinLink"] else {
            return nil
        }
        switch extraData {
        case .string(let link):
            return link
        default:
            return nil
        }
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

extension ChatChannelVC: UIContextMenuInteractionDelegate {
    @available(iOS 13.0, *)
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let qrCode = UIAction(title: "Group QR", image: UIImage(systemName: "qrcode.viewfinder")) { [weak self] action in
            guard let self = self else {
                return
            }
            guard let qrCodeVc: GroupQRCodeVC = GroupQRCodeVC.instantiateController(storyboard: .PrivateGroup) else {
                return
            }
            qrCodeVc.strContent = self.getGroupLink()
            self.navigationController?.pushViewController(qrCodeVc, animated: true)
        }
        return UIContextMenuConfiguration(identifier: nil,
            previewProvider: nil) { _ in
            UIMenu(title: "", children: [qrCode])
          }
    }
}
