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
    public static let generalGroupInviteLink = Notification.Name("kGeneralGoupeInviteLink")
}

public let kExtraDataChannelDescription = "channelDescription"
public let kExtraDataOneToOneChat = "OneToOneChat"
public let kExtraDataIsGroupChat = "DataIsGroupChat"

public let kInviteGroupID = "kInviteGroupID"
public let kInviteExpiryDate = "kInviteExpiryDate"


/// Controller responsible for displaying the channel messages.
@available(iOSApplicationExtension, unavailable)
open class ChatChannelVC:
    _ViewController,
    ThemeProvider,
    ChatMessageListVCDataSource,
    ChatMessageListVCDelegate,
    ChatChannelControllerDelegate {
    /// Controller for observing data changes within the channel.
    open var channelController: ChatChannelController?

    /// boolean flag for first time navigate here after creating new channel
    open var isChannelCreated = false

    /// Listen to keyboard observer or not
    open var enableKeyboardObserver = false
    
    /// Local variable to toggle channel mute flag
    private var isChannelMuted = false

    /// User search controller for suggestion users when typing in the composer.
    open lazy var userSuggestionSearchController: ChatUserSearchController? =
    channelController?.client.userSearchController()

    /// The size of the channel avatar.
    open var channelAvatarSize: CGSize {
        CGSize(width: 32, height: 32)
    }

    public var client: ChatClient? {
        channelController?.client
    }

//    /// Component responsible for setting the correct offset when keyboard frame is changed.
    open lazy var keyboardHandler: KeyboardHandler = ComposerKeyboardHandler(
        composerParentVC: self,
        composerBottomConstraint: messageComposerBottomConstraint
    )

    open private(set) lazy var navigationSafeAreaView: UIView = {
        let view = UIView(frame: .zero).withoutAutoresizingMaskConstraints
        view.backgroundColor =  Appearance.default.colorPalette.walletTabbarBackground
        return view
    }()

    open private(set) lazy var navigationHeaderView: UIView = {
        let view = UIView(frame: .zero).withoutAutoresizingMaskConstraints
        view.backgroundColor =  Appearance.default.colorPalette.walletTabbarBackground
        return view
    }()

    open private(set) lazy var moreButton: UIButton = {
        let button = UIButton()
        button.setImage(appearance.images.moreVertical, for: .normal)
        button.tintColor = .white
        button.backgroundColor = .clear
        return button.withoutAutoresizingMaskConstraints
    }()

    open private(set) lazy var channelAction: UIView = {
        let actionView = UIView()
        actionView.backgroundColor = Appearance.default.colorPalette.walletTabbarBackground
        return actionView.withoutAutoresizingMaskConstraints
    }()

    open private(set) lazy var btnAction: UIButton = {
        let button = UIButton()
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
        view.backgroundColor =  Appearance.default.colorPalette.walletTabbarBackground
        view.distribution = .fill
        return view
    }()

    private(set) lazy var shareButton: UIButton = {
        let button = UIButton()
        button.setImage(appearance.images.arrowUpRightSquare, for: .normal)
        button.tintColor =  Appearance.default.colorPalette.themeBlue
        button.setTitle(" SHARE", for: .normal)
        button.setTitleColor( Appearance.default.colorPalette.themeBlue, for: .normal)
        button.titleLabel?.font =  UIFont.systemFont(ofSize: 15, weight: .semibold)
        button.addTarget(self, action: #selector(shareAction), for: .touchUpInside)
        return button.withoutAutoresizingMaskConstraints
    }()

    private(set) lazy var addFriendButton: UIButton = {
        let button = UIButton()
        button.setImage(appearance.images.personBadgePlus, for: .normal)
        button.tintColor =  Appearance.default.colorPalette.themeBlue
        button.setTitle(" ADD FRIENDS", for: .normal)
        button.setTitleColor(Appearance.default.colorPalette.themeBlue, for: .normal)
        button.titleLabel?.font =  UIFont.systemFont(ofSize: 15, weight: .semibold)
        button.addTarget(self, action: #selector(addFriendAction), for: .touchUpInside)
        return button.withoutAutoresizingMaskConstraints
    }()
    
    open private(set) lazy var backButton: UIButton = {
        let button = UIButton()
        button.setImage(appearance.images.backCircle, for: .normal)
        button.tintColor = .white
        button.contentEdgeInsets = UIEdgeInsets.init(top: 8, left: 8, bottom: 8, right: 8)
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
    open lazy var messageListVC: ChatMessageListVC? = components
        .messageListVC
        .init()

    /// Controller that handles the composer view
    open private(set) lazy var messageComposerVC: ComposerVC? = components
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
    
    /// A boolean value indicating wether the last message is fully visible or not.
    /// If the value is `true` it means the message list is fully scrolled to the bottom.
    open var isLastMessageFullyVisible: Bool {
        messageListVC?.listView.isLastCellFullyVisible ?? false
    }

    private var isLoadingPreviousMessages: Bool = false

    override open func setUp() {
        super.setUp()

        messageListVC?.delegate = self
        messageListVC?.dataSource = self
        if let client = channelController?.client {
            messageListVC?.client = client
        }
        messageComposerVC?.channelController = channelController
        messageComposerVC?.userSearchController = userSuggestionSearchController

        channelController?.delegate = self
        channelController?.synchronize { [weak self] _ in
            self?.messageComposerVC?.updateContent()
        }
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.backgroundColor = appearance.colorPalette.chatViewBackground

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
            backButton.leadingAnchor.constraint(equalTo: navigationHeaderView.leadingAnchor, constant: 12),
            backButton.centerYAnchor.constraint(equalTo: navigationHeaderView.centerYAnchor, constant: 0),
            backButton.heightAnchor.constraint(equalToConstant: 46),
            backButton.widthAnchor.constraint(equalToConstant: 46)
        ])

        navigationHeaderView.addSubview(rightStackView)
        rightStackView.addArrangedSubview(channelAvatarView)
        channelAvatarView.content = (channelController?.channel, client?.currentUserId)
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
        if let messageListVC = messageListVC {
            addChildViewController(messageListVC, targetView: view)
            NSLayoutConstraint.activate([
                messageListVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
                messageListVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
                messageListVC.view.topAnchor.constraint(equalTo: navigationHeaderView.bottomAnchor, constant: 0),
            ])
            if let messageComposerVC = messageComposerVC {
                addChildViewController(messageComposerVC, targetView: view)
                messageComposerVC.view.pin(anchors: [.leading, .trailing], to: view)
                messageComposerVC.view.topAnchor.pin(equalTo: messageListVC.view.bottomAnchor).isActive = true
                messageComposerBottomConstraint = messageComposerVC.view.bottomAnchor.pin(equalTo: view.bottomAnchor)
                messageComposerBottomConstraint?.isActive = true
            }
            if channelController?.channel?.type == .announcement, let mute = channelController?.channel?.isMuted {
                self.navigationController?.isToolbarHidden = true
                btnAction.setTitle(mute ? "Unmute" : "Mute", for: .normal)
                btnAction.addTarget(self, action: #selector(muteAction), for: .touchUpInside)
                messageComposerVC?.view.isHidden = true

                view.insertSubview(channelAction, aboveSubview: messageComposerVC?.view ?? .init())
                channelAction.pin(anchors: [.leading, .trailing], to: view)
                channelAction.topAnchor.pin(equalTo: messageListVC.view.bottomAnchor).isActive = true
                channelAction.bottomAnchor.pin(equalTo: view.bottomAnchor).isActive = true
                channelAction.embed(btnAction)
                btnAction.pin(to: channelAction)
            } else {
                self.messageComposerVC?.view.isHidden = false
                self.navigationController?.isToolbarHidden = true
            }
        }
        
        view.addSubview(shareView)
        NSLayoutConstraint.activate([
            shareView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            shareView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            shareView.topAnchor.constraint(equalTo: navigationHeaderView.bottomAnchor, constant: 0)
        ])

        shareView.addArrangedSubview(shareButton)
        shareView.addArrangedSubview(addFriendButton)

        NSLayoutConstraint.activate([
            shareButton.heightAnchor.constraint(equalToConstant: 52),
            addFriendButton.heightAnchor.constraint(equalToConstant: 52),
        ])

        shareView.addSubview(closePinButton)
        NSLayoutConstraint.activate([
            closePinButton.trailingAnchor.constraint(equalTo: shareView.trailingAnchor, constant: -20),
            closePinButton.centerYAnchor.constraint(equalTo: shareView.centerYAnchor, constant: 0),
            closePinButton.widthAnchor.constraint(equalToConstant: 30),
            closePinButton.heightAnchor.constraint(equalToConstant: 30)
        ])

        if let cid = channelController?.cid {
            headerView.channelController = client?.channelController(for: cid)
        }
        if channelController?.channelQuery.type == .announcement {
            messageComposerVC?.composerView.isUserInteractionEnabled = false
            messageComposerVC?.composerView.alpha = 0.5
            headerView.titleContainerView.subtitleLabel.isHidden = true
            messageComposerVC?.composerView.inputMessageView.textView.resignFirstResponder()
            channelAvatarView.isHidden = true
            moreButton.isHidden = true
        } else {
            messageComposerVC?.composerView.isUserInteractionEnabled = true
            messageComposerVC?.composerView.alpha = 1.0
            channelAvatarView.isHidden = false
            messageComposerVC?.composerView.isUserInteractionEnabled = true
            moreButton.isHidden = false
        }
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.headerViewAction(_:)))
        tapGesture.numberOfTapsRequired = 1
        headerView.addGestureRecognizer(tapGesture)

        let avatarTapGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.avatarViewAction(_:)))
        avatarTapGesture.numberOfTapsRequired = 1
        channelAvatarView.addGestureRecognizer(avatarTapGesture)

        headerView.titleContainerView.titleLabel.setChatNavTitleColor()
        headerView.titleContainerView.subtitleLabel.setChatNavSubtitleColor()
        
        navigationHeaderView.backgroundColor = Appearance.default.colorPalette.chatNavBarBackgroundColor
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: .hideTabbar, object: nil)
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isToolbarHidden = true
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
        deallocManually()
        self.popWithAnimation()
        self.dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: .showTabbar, object: nil)
    }

    @objc func muteAction(_ sender: UIButton) {
        guard let isMute = channelController?.channel?.isMuted,
              let currentUserId = ChatClient.shared.currentUserId
        else { return }
        if isMute {
            self.channelController?.unmuteChannel(completion: nil)
            // Add user in channel to enable notification
            self.channelController?.addMembers(userIds: [currentUserId], completion: nil)
            sender.setTitle("Mute", for: .normal)
            return;
        }
        self.channelController?.muteChannel(completion: nil)
        // Remove user from channel to disable notification
        self.channelController?.removeMembers(userIds: [currentUserId], completion: nil)
        sender.setTitle("Unmute", for: .normal)
    }
    
    @objc func headerViewAction(_ sender: Any) {
        guard channelController?.channel?.type != .announcement else { return }
        if self.channelController?.channel?.isDirectMessageChannel ?? true {
            return
        }
        guard let controller: ChatGroupDetailsVC = ChatGroupDetailsVC.instantiateController(storyboard: .GroupChat) else {
            return
        }
        controller.groupInviteLink = self.getGroupLink()
        controller.channelController = channelController
        self.pushWithAnimation(controller: controller)
    }

    @objc func avatarViewAction(_ sender: Any) {
        if self.channelController?.channel?.isDirectMessageChannel ?? true {
            return
        }
        showPinViewButton()
    }

    @objc func shareAction(_ sender: Any) {
        guard let extraData = channelController?.channel?.extraData,
              channelController?.channel?.type == .dao else {
            return
        }
        var userInfo = [AnyHashable: Any]()
        userInfo["extraData"] = channelController?.channel?.extraData
        NotificationCenter.default.post(name: .showDaoShareScreen, object: nil, userInfo: userInfo)
    }
    
    @objc func addFriendAction(_ sender: Any) {
        guard let channelVC = self.channelController else { return }
        guard let controller = ChatAddFriendVC
                .instantiateController(storyboard: .GroupChat)  as? ChatAddFriendVC else {
            return
        }
        controller.groupInviteLink = self.getGroupLink()
        controller.existingUsers = channelVC.channel?.lastActiveMembers as? [ChatUser] ?? []
        controller.channelController = channelVC
        controller.bCallbackInviteFriend = { [weak self] users in
            guard let weakSelf = self else { return }
            let ids = users.map{ $0.id}
            weakSelf.channelController?.inviteMembers(userIds: Set(ids), completion: { error in
                if error == nil {
                    DispatchQueue.main.async {
                        Snackbar.show(text: "Group invite sent")
                    }
                } else {
                    Snackbar.show(text: "Error while sending invitation link")
                }
            })
        }
        
        controller.bCallbackAddFriend = { [weak self] users in
            guard let weakSelf = self else { return }
            let ids = users.map{ $0.id}
            weakSelf.channelController?.addMembers(userIds: Set(ids), completion: { error in
                if error == nil {
                    // nothing
                    DispatchQueue.main.async {
                        Snackbar.show(text: "Group Member updated")
                    }
                } else {
                    Snackbar.show(text: "Error operation could be completed")
                }
            })
        }
    
        presentPanModal(controller)
    }

    @objc func closePinViewAction(_ sender: Any) {
        shareView.isHidden = true
    }

    private func deallocManually() {
        channelController = nil
        NotificationCenter.default.removeObserver(self)
        messageListVC?.client = nil
        messageListVC?.delegate = nil
        messageListVC?.dataSource = nil
        messageListVC = nil
        messageComposerVC = nil
        userSuggestionSearchController = nil
    }
    
    private func getGroupLink() -> String? {
        guard let extraData = channelController?.channel?.extraData["joinLink"] else {
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
        isChannelMuted = channelController?.channel?.isMuted ?? false
        reloadMenu()
        KeyboardService.shared.observeKeyboard(self.view)
        if channelController?.channel?.isDirectMessageChannel ?? false {
            shareView.isHidden = true
        } else {
            shareView.isHidden = isChannelCreated ? false : true
            if isChannelCreated {
                showPinViewButton()
            }
        }
        channelController?.markRead()
    }

    private func showPinViewButton() {
        if channelController?.channel?.type == .dao {
            shareView.isHidden = false
            shareButton.isHidden = false
            addFriendButton.isHidden = true
        } else if self.isChannelCreated {
            shareView.isHidden = false
            addFriendButton.isHidden = false
            shareButton.isHidden = true
            guard self.isChannelCreated == true else { return  }
            self.isChannelCreated = false
            let members = (channelController?.channel?.lastActiveMembers ?? []).reduce(into: [String: RawJSON](), { $0[$1.id] = .string($1.name ?? "")})
            let joiningText = "Group Created\nTry using the menu item to share with others."
            //
            var extraData = [String: RawJSON]()
            extraData["adminMessage"] = .string(joiningText)
            extraData["members"] = .dictionary(members)
            channelController?.createNewMessage(
                text: "",
                pinning: nil,
                attachments: [],
                extraData: ["adminMessage": .dictionary(extraData),
                            "messageType": .string(AdminMessageType.simpleGroupChat.rawValue)],
                completion: nil)
        }
    }
    
    private func reloadMenu() {
        if #available(iOS 14.0, *) {
            let menu = UIMenu(title: "",
                              options: .displayInline,
                              children: getMenuItems())
            moreButton.menu = menu
            moreButton.showsMenuAsPrimaryAction = true
        }
    }
    
    // MARK: - Menu actions
    public func inviteUserAction() {
        guard let channelVC = self.channelController else { return }
        guard let controller = ChatAddFriendVC
                .instantiateController(storyboard: .GroupChat)  as? ChatAddFriendVC else {
            return
        }
        controller.channelController = channelVC
        controller.groupInviteLink = self.getGroupLink()
        controller.selectionType = .inviteUser
        controller.existingUsers = channelVC.channel?.lastActiveMembers as? [ChatUser] ?? []
        controller.bCallbackInviteFriend = { [weak self] users in
            guard let weakSelf = self else { return }
            let ids = users.map{ $0.id}
            weakSelf.channelController?.inviteMembers(userIds: Set(ids), completion: { error in
                if error == nil {
                    DispatchQueue.main.async {
                        Snackbar.show(text: "Group invite sent")
                    }
                } else {
                    Snackbar.show(text: "Error while sending invitation link")
                }
            })
        }
        presentPanModal(controller)
    }
    public func showGroupQRAction() {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            guard let qrCodeVc: GroupQRCodeVC = GroupQRCodeVC.instantiateController(storyboard: .PrivateGroup) else {
                return
            }
            qrCodeVc.strContent = weakSelf.getGroupLink()
            weakSelf.pushWithAnimation(controller: qrCodeVc)
        }
    }
    
    public func leaveGroupAction() {
        guard let controller = ChatAlertVC
                .instantiateController(storyboard: .GroupChat)  as? ChatAlertVC else {
            return
        }
        controller.alertType = .leaveChatRoom
        controller.bCallbackActionHandler = { [weak self] in
            guard let weakSelf = self else { return }
            
            weakSelf.channelController?.removeMembers(userIds: [ChatClient.shared.currentUserId ?? ""]) { [weak self] error in
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
        controller.modalPresentationStyle = .overCurrentContext
        controller.modalTransitionStyle = .crossDissolve
        self.present(controller, animated: true, completion: nil)
    }
    
    public func leaveGroupDeleteGroupAction() {
        guard let controller = ChatAlertVC
                .instantiateController(storyboard: .GroupChat)  as? ChatAlertVC else {
            return
        }
        controller.alertType = .deleteGroup
        controller.bCallbackActionHandler = { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.deleteThisChannel()
        }
        controller.modalPresentationStyle = .overCurrentContext
        controller.modalTransitionStyle = .crossDissolve
        self.present(controller, animated: true, completion: nil)
    }
    
    private func deleteThisChannel() {
        guard let channelController = channelController,
              let channelId = channelController.channel?.cid else {
                  Snackbar.show(text: "Error when deleting the channel")
            return
        }
        let memberListController = channelController.client.memberListController(query: .init(cid: channelId))
        memberListController.synchronize { error in
            guard error == nil else {
                Snackbar.show(text: "Error when deleting the channel")
                return
            }
            let userIds: [UserId] = memberListController.members.map({ member in
                return member.id
            })
            channelController.removeMembers(userIds: Set(userIds)) { _ in
                channelController.deleteChannel { [weak self] error in
                    guard error == nil, let self = self else {
                        Snackbar.show(text: error?.localizedDescription ?? "")
                        return
                    }
                    Snackbar.show(text: "Group deleted successfully")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                        guard let self = self else { return }
                        self.backAction(UIButton())
                    }
                }
            }
        }
        
    }
    
    public func muteNotification() {
        channelController?.muteChannel(completion: { [weak self] error in
            guard let weakSelf = self else { return }
            guard error == nil else {
                Snackbar.show(text: "Error while mute group notifications")
                weakSelf.isChannelMuted = false
                weakSelf.reloadMenu()
                return
            }
            weakSelf.isChannelMuted = true
            weakSelf.reloadMenu()
            Snackbar.show(text: "Notifications muted", messageType: StreamChatMessageType.ChatGroupMute)
        })
    }
    
    public func unMuteNotification() {
        channelController?.unmuteChannel(completion: { [weak self] error in
            guard let weakSelf = self else { return }
            guard error == nil else {
                Snackbar.show(text: "Error while unmute group notifications")
                weakSelf.isChannelMuted = true
                weakSelf.reloadMenu()
                return
            }
            weakSelf.isChannelMuted = false
            weakSelf.reloadMenu()
            Snackbar.show(text: "Notifications unmuted", messageType: StreamChatMessageType.ChatGroupMute)
        })
    }
    
    public func deleteChat() {
        let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.channelController?.hideChannel(clearHistory: true) { [weak self] error in
                guard let weakSelf = self else { return }
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
    }
    // MARK: - ChatMessageListVCDataSource
    public var messages: [ChatMessage] {
        Array(channelController?.messages ?? [])
    }
    
    open func channel(for vc: ChatMessageListVC) -> ChatChannel? {
        channelController?.channel
    }

    open func numberOfMessages(in vc: ChatMessageListVC) -> Int {
        channelController?.messages.count ?? 0
    }

    open func chatMessageListVC(_ vc: ChatMessageListVC, messageAt indexPath: IndexPath) -> ChatMessage? {
        guard indexPath.item < channelController?.messages.count ?? 0 else { return nil }
        return channelController?.messages[indexPath.item]
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        messageLayoutOptionsAt indexPath: IndexPath
    ) -> ChatMessageLayoutOptions {
        guard let channel = channelController?.channel,
              let message = channelController?.messages else { return [] }

        return components.messageLayoutOptionsResolver.optionsForMessage(
            at: indexPath,
            in: channel,
            with: AnyRandomAccessCollection(message),
            appearance: appearance
        )
    }

    // MARK: - ChatMessageListVCDelegate

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        willDisplayMessageAt indexPath: IndexPath
    ) {
        if channelController?.state != .remoteDataFetched {
            return
        }
        if indexPath.row < (channelController?.messages.count ?? 0) - 10 {
            return
        }
        guard !loadingPreviousMessages else {
            return
        }
        loadingPreviousMessages = true
        channelController?.loadPreviousMessages { [weak self] _ in
            self?.isLoadingPreviousMessages = false
        }
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        didTapOnAction actionItem: ChatMessageActionItem,
        for message: ChatMessage
    ) {
        switch actionItem {
        case is EditActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageComposerVC?.content.editMessage(message)
            }
        case is InlineReplyActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageComposerVC?.content.quoteMessage(message)
            }
        case is ThreadReplyActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageListVC?.showThread(messageId: message.id)
            }
        default:
            return
        }
    }

    var didReadAllMessages: Bool {
        messageListVC?.listView.isLastCellFullyVisible ?? false
    }

    open func chatMessageListVC(_ vc: ChatMessageListVC, scrollViewDidScroll scrollView: UIScrollView) {
        if didReadAllMessages {
            channelController?.markRead()
        }
        if messageListVC?.listView.isLastCellFullyVisible ?? false, channelController?.channel?.isUnread == true {
            // Hide the badge immediately. Temporary solution until CIS-881 is implemented.
            messageListVC?.scrollToLatestMessageButton.content = .noUnread
        }
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        didTapOnMessageListView messageListView: ChatMessageListView,
        with gestureRecognizer: UITapGestureRecognizer
    ) {
        messageComposerVC?.dismissSuggestions()
    }

    // MARK: - ChatChannelControllerDelegate

    open func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) {
        if didReadAllMessages {
            channelController.markRead()
        }
        messageListVC?.updateMessages(with: changes)
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
        messageListVC?.scrollToLatestMessageButton.content = channelUnreadCount
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
            .filter { $0.id != self.client?.currentUserId }

        if typingUsersWithoutCurrentUser.isEmpty {
            messageListVC?.hideTypingIndicator()
        } else {
            messageListVC?.showTypingIndicator(typingUsers: typingUsersWithoutCurrentUser)
        }
    }

    // TODO: - Invite and other action need to implement
    @available(iOS 13.0, *)
    func getMenuItems() -> [UIAction] {
        // private group
        let privateGroup = UIAction(title: "Group QR", image: appearance.images.qrCodeViewFinder) { [weak self] _ in
            guard let self = self else {
                return
            }
            guard let qrCodeVc: GroupQRCodeVC = GroupQRCodeVC.instantiateController(storyboard: .PrivateGroup) else {
                return
            }
            qrCodeVc.strContent = self.getGroupLink()
            self.pushWithAnimation(controller: qrCodeVc)
        }
        // search
        // To do:- will add in future release
//        let search = UIAction(title: "Search", image: Appearance.Images.systemMagnifying) { [weak self] _ in
//            Snackbar.show(text: "Not available on alpha release")
//        }
        // invite
        let invite = UIAction(title: "Invite", image: appearance.images.personBadgePlus) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.inviteUserAction()
        }
        // groupQR
        let groupQR = UIAction(title: "QR", image: appearance.images.qrCode) { [weak self] _ in
            guard let self = self else {
                return
            }
            if self.channelController?.channel?.type == .dao {
                self.shareAction(UIButton())
            } else {
                self.showGroupQRAction()
            }
            
        }
        // mute
        let mute = UIAction(title: "Mute", image: appearance.images.mute) { _ in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.muteNotification()
            }
        }
        // unmute
        let unmute = UIAction(title: "Unmute", image: appearance.images.unMute) { _ in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.unMuteNotification()
            }
        }
        // leaveGroup
        let leaveGroup = UIAction(title: "Leave Group", image: appearance.images.rectangleArrowRight) { [weak self] _ in
            guard let self = self else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.leaveGroupAction()
            }
        }
        // delete and leave
        let deleteAndLeave = UIAction(title: "Delete and Leave", image: appearance.images.rectangleArrowRight) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.leaveGroupDeleteGroupAction()
        }
        // deleteChat
        let deleteChat = UIAction(title: "Delete Chat", image: appearance.images.trash) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.deleteChat()
        }
        // group Image
        // To do:- will add in future release
//        let groupImage = UIAction(title: "Group Image", image: appearance.images.photo) { _ in
//        }
        if channelController?.channel?.type == .privateMessaging {
            //return [privateGroup]
            var actions: [UIAction] = []
            actions.append(privateGroup)
            if channelController?.channel?.membership?.userRole == .admin {
                actions.append(deleteAndLeave)
            } else {
                actions.append(leaveGroup)
            }
            return actions
        } else {
            if channelController?.channel?.isDirectMessageChannel ?? false {
                var actions: [UIAction] = []
                // To do:- will add in future release
                //actions.append(search)
                if isChannelMuted {
                    actions.append(unmute)
                } else {
                    actions.append(mute)
                }
                actions.append(deleteChat)
                return actions
            } else {
                let isAdmin = channelController?.channel?.createdBy?.id == ChatClient.shared.currentUserId
                if isAdmin {
                    var actions: [UIAction] = []
                    // To do:- will add in future release
                    //actions.append(contentsOf: [groupImage, search,invite,groupQR])
                    actions.append(contentsOf: [invite, groupQR])
                    if isChannelMuted {
                        actions.append(unmute)
                    } else {
                        actions.append(mute)
                    }
                    actions.append(deleteAndLeave)
                    return actions
                } else {
                    var actions: [UIAction] = []
                    // To do:- will add in future release
                    //actions.append(contentsOf: [search,groupQR])
                    actions.append(contentsOf: [groupQR])
                    if isChannelMuted {
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
