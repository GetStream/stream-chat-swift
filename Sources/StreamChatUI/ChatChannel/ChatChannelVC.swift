//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit
import StreamChatUI
extension Notification.Name {
    public static let showTabbar = Notification.Name("kStreamChatshowTabbar")
    public static let hideTabbar = Notification.Name("kStreamHideTabbar")
    public static let showDaoShareScreen = Notification.Name("showDaoShareScreen")
    public static let hidePaymentOptions = Notification.Name("kStreamHidePaymentOptions")
    public static let showFriendScreen = Notification.Name("showFriendScreen")
}

public let kExtraDataChannelDescription = "channelDescription"
public let kExtraDataOneToOneChat = "OneToOneChat"
public let kExtraDataIsGroupChat = "DataIsGroupChat"

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

    /// boolean flag for first time navigate here after creating new channel
    open var isChannelCreated = false

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

    open private(set) lazy var shareView: UIStackView = {
        let view = UIStackView(frame: .zero).withoutAutoresizingMaskConstraints
        view.backgroundColor = appearance.colorPalette.walletTabbarBackground
        view.distribution = .fill
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

    private(set) lazy var addFriendButton: UIButton = {
        let button = UIButton()
        button.setImage(appearance.images.personBadgePlus, for: .normal)
        button.tintColor = appearance.colorPalette.themeBlue
        button.setTitle(" ADD FRIENDS", for: .normal)
        button.setTitleColor(appearance.colorPalette.themeBlue, for: .normal)
        button.titleLabel?.font =  UIFont.systemFont(ofSize: 15, weight: .semibold)
        button.addTarget(self, action: #selector(addFriendAction), for: .touchUpInside)
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

    lazy var groupCreateMessageView: AdminMessageTVCell? = {
        return Bundle.main.loadNibNamed("AdminMessageTVCell", owner: nil, options: nil)?.first as? AdminMessageTVCell
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
        channelAvatarView.content = (channelController.channel, client.currentUserId)
        rightStackView.addArrangedSubview(moreButton)
        moreButton.widthAnchor.constraint(equalToConstant: 30).isActive = true

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
            //shareView.heightAnchor.constraint(equalToConstant: 52),
            shareView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            shareView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            shareView.topAnchor.constraint(equalTo: navigationHeaderView.bottomAnchor, constant: 0)
        ])

        //shareView.addSubview(shareButton)
        shareView.addArrangedSubview(shareButton)
        shareView.addArrangedSubview(addFriendButton)
        //        NSLayoutConstraint.activate([
        //            shareButton.centerXAnchor.constraint(equalTo: shareView.centerXAnchor, constant: 0),
        //            shareButton.centerYAnchor.constraint(equalTo: shareView.centerYAnchor, constant: 0),
        //            shareButton.heightAnchor.constraint(equalToConstant: 25),
        //        ])

        NSLayoutConstraint.activate([
            shareButton.heightAnchor.constraint(equalToConstant: 52),
            addFriendButton.heightAnchor.constraint(equalToConstant: 52),
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
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.headerViewAction(_:)))
        tapGesture.numberOfTapsRequired = 1
        headerView.addGestureRecognizer(tapGesture)

        let avatarTapGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.avatarViewAction(_:)))
        avatarTapGesture.numberOfTapsRequired = 1
        channelAvatarView.addGestureRecognizer(avatarTapGesture)
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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
    @objc func headerViewAction(_ sender: Any) {
        
        if self.channelController.channel?.isDirectMessageChannel ?? true {
            return
        }
        guard let controller: ChatGroupDetailsVC = ChatGroupDetailsVC.instantiateController(storyboard: .GroupChat) else {
            return
        }
        controller.channelController = channelController
        self.navigationController?.pushViewController(controller, animated: true)
    }

    @objc func avatarViewAction(_ sender: Any) {
        shareView.isHidden = false
        showPinViewButton()
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
    @objc func addFriendAction(_ sender: Any) {
        
        guard let controller = ChatAddFriendVC
                .instantiateController(storyboard: .GroupChat)  as? ChatAddFriendVC else {
            return
        }
        //
        controller.bCallbackAddUser = { [weak self] users in
            guard let weakSelf = self else { return }
            let ids = users.map{ $0.id}
            weakSelf.channelController?.addMembers(userIds: Set(ids), completion: { error in
                if error == nil {
                    // nothing
                    DispatchQueue.main.async {
                        Snackbar.show(text: "Group Member updated")
                    }
                } else {
                    Snackbar.show(text: error!.localizedDescription)
                }
            })
        }
        //
        controller.modalPresentationStyle = .overCurrentContext
        controller.modalTransitionStyle = .crossDissolve
        
        self.present(controller, animated: true, completion: nil)
    }
    
    @objc func moreButtonAction(_ sender: Any) {
        CM.nibView = UINib(nibName: "ContextMenuCell", bundle: nil)
        CM.items = getMenuItems()
        CM.showMenu(viewTargeted: moreButton, delegate: self)
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

    private func setupUI() {
        KeyboardService.shared.observeKeyboard(self.view)
        if channelController.channel?.isDirectMessageChannel ?? false {
            shareView.isHidden = true
            moreButton.isHidden = true
        } else {
            shareView.isHidden = isChannelCreated ? false : true
            if isChannelCreated {
                showPinViewButton()
            }
        }
        channelController.markRead()
    }

    private func showPinViewButton() {
        if channelController.channel?.type == .dao {
            shareButton.isHidden = false
            addFriendButton.isHidden = true
        } else {
            addFriendButton.isHidden = false
            shareButton.isHidden = true
            
            
            let members = channelController.channel?.lastActiveMembers ?? []
            let randomUser = members.filter({ $0.id != ChatClient.shared.currentUserId}).randomElement()
            //
            var joiningText = "You created this group with \(randomUser?.name ?? "")"
            //
            if members.count > 2 {
                joiningText.append(" and \(members.count - 2) other.")
            }
            joiningText.append("\nTry using the menu item to share with others.")
            //
            let memberShip = channelController.channel?.membership
            if let groupCreateMessageView = groupCreateMessageView , let memberRole =  memberShip?.memberRole , memberRole == .owner  && memberShip?.id == ChatClient.shared.currentUserId! {
                
                let suggestionsView = groupCreateMessageView.contentView
                self.messageComposerVC.view.addSubview(suggestionsView)
                
                suggestionsView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    suggestionsView.leadingAnchor.constraint(equalTo: self.messageComposerVC.view.leadingAnchor, constant: 0),
                    suggestionsView.trailingAnchor.constraint(equalTo: self.messageComposerVC.view.trailingAnchor, constant: 0),
                    suggestionsView.topAnchor.pin(greaterThanOrEqualTo: self.view.topAnchor),
                    suggestionsView.bottomAnchor.pin(equalTo: self.messageComposerVC.view.topAnchor),
                    //suggestionsView.heightAnchor.constraint(equalToConstant: 300),
                ])
                
                groupCreateMessageView.configCell(with: self.channelController.channel?.createdAt, message: joiningText)
            }
        
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
        if channelController.messages.count > 0 {
            self.groupCreateMessageView?.contentView.removeFromSuperview()
            self.groupCreateMessageView = nil
        }
    }

    open func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    ) {
        let channelUnreadCount = channelController.channel?.unreadCount ?? .noUnread
        messageListVC.scrollToLatestMessageButton.content = channelUnreadCount
        if channelController.messages.count > 0 {
            self.groupCreateMessageView?.contentView.removeFromSuperview()
            self.groupCreateMessageView = nil
        }
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

    func getMenuItems() -> [ContextMenuItemWithImage] {
        let privateGroup = ContextMenuItemWithImage(title: "Group QR", image: appearance.images.qrCodeViewFinder, type: .privateGroup)
        let search = ContextMenuItemWithImage(title: "Search", image: appearance.images.qrCode, type: .searchMessage)
        let invite = ContextMenuItemWithImage(title: "Invite", image: appearance.images.personBadgePlus, type: .invite)
        let groupQR = ContextMenuItemWithImage(title: "QR", image: appearance.images.qrCode, type: .groupQR)
        let mute = ContextMenuItemWithImage(title: "Mute", image: appearance.images.mute, type: .mute)
        let unmute = ContextMenuItemWithImage(title: "Unmute", image: appearance.images.unMute, type: .unmute)
        let leaveGroup = ContextMenuItemWithImage(title: "Leave Group", image: appearance.images.rectangleArrowRight, type: .leaveGroup)
        let deleteAndLeave = ContextMenuItemWithImage(title: "Delete and Leave", image: appearance.images.rectangleArrowRight, type: .deleteAndLeave)
        let deleteChat = ContextMenuItemWithImage(title: "Delete Chat", image: appearance.images.trash, type: .deleteChat)
        let groupImage = ContextMenuItemWithImage(title: "Group Image", image: appearance.images.photo, type: .groupImage)
        if channelController.channel?.type == .privateMessaging {
            return [privateGroup]
        } else {
            if channelController.channel?.isDirectMessageChannel ?? false {
                var actions: [ContextMenuItemWithImage] = []
                actions.append(search)
                if channelController.channel?.isMuted ?? false {
                    actions.append(unmute)
                } else {
                    actions.append(mute)
                }
                actions.append(deleteChat)
                return actions
            } else {
                if channelController.channel?.membership?.userRole == .admin {
                    var actions: [ContextMenuItemWithImage] = []
                    actions.append(contentsOf: [groupImage, search, invite, groupQR])
                    if channelController.channel?.isMuted ?? false {
                        actions.append(unmute)
                    } else {
                        actions.append(mute)
                    }
                    actions.append(deleteAndLeave)
                    return actions
                } else {
                    var actions: [ContextMenuItemWithImage] = []
                    actions.append(contentsOf: [search, invite, groupQR])
                    if channelController.channel?.isMuted ?? false {
                        actions.append(unmute)
                    } else {
                        actions.append(mute)
                    }
                    actions.append(leaveGroup)
                    return actions
                }
            }
        }
    }
}

extension ChatChannelVC: ContextMenuDelegate {
    public func contextMenuDidSelect(
        _ contextMenu: ContextMenu,
        cell: ContextMenuCell,
        targetedView: UIView,
        didSelect item: ContextMenuItem,
        forRowAt index: Int) -> Bool {
            switch item.type {
            case .privateGroup:
                guard let qrCodeVc: GroupQRCodeVC = GroupQRCodeVC.instantiateController(storyboard: .PrivateGroup) else {
                    return true
                }
                qrCodeVc.strContent = self.getGroupLink()
                self.navigationController?.pushViewController(qrCodeVc, animated: true)
            case .searchMessage:
                break
            case .invite:
                break
            case .groupQR:
                self.shareAction(UIButton())
            case .mute:
                channelController.muteChannel(completion: nil)
            case .unmute:
                channelController.unmuteChannel(completion: nil)
            case .leaveGroup:
                let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    self.channelController.removeMembers(userIds: [ChatClient.shared.currentUserId ?? ""]) { [weak self] error in
                        guard error == nil, let self = self else {
                            Snackbar.show(text: error?.localizedDescription ?? "")
                            return
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                            guard let self = self else { return }
                            self.backAction(UIButton())
                        }
                    }
                }
                let noAction = UIAlertAction(title: "No", style: .default) { _ in }
                presentAlert(
                    title: "Are you sure you want to leave group?",
                    message: nil, actions: [yesAction, noAction])
            case .deleteAndLeave:
                let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    self.channelController.deleteChannel { error in
                        guard error == nil else {
                            Snackbar.show(text: error?.localizedDescription ?? "")
                            return
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                            guard let self = self else { return }
                            self.backAction(UIButton())
                        }
                    }
                }
                let noAction = UIAlertAction(title: "No", style: .default) { _ in }
                self.presentAlert(
                    title: "Are you sure you want to delete group?",
                    message: nil, actions: [yesAction, noAction])
            case .deleteChat:
                let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    self.channelController.hideChannel(clearHistory: true) { error in
                        guard error == nil else {
                            Snackbar.show(text: error?.localizedDescription ?? "")
                            return
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                            guard let self = self else { return }
                            self.backAction(UIButton())
                        }
                    }
                }
                let noAction = UIAlertAction(title: "No", style: .default) { _ in }
                presentAlert(
                    title: "Are you sure you want to delete chat?",
                    message: nil, actions: [yesAction, noAction])
            case .groupImage:
                break
            }
        return true
    }

    public func contextMenuDidDeselect(
        _ contextMenu: ContextMenu,
        cell: ContextMenuCell,
        targetedView: UIView,
        didSelect item: ContextMenuItem,
        forRowAt index: Int) {
    }

    public func contextMenuDidAppear(_ contextMenu: ContextMenu) {
    }

    public func contextMenuDidDisappear(_ contextMenu: ContextMenu) {
    }

}
