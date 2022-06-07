//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

#if !XCODE_BETA_1
import Atlantis
#endif
import GDPerformanceView_Swift
import StreamChat
import StreamChatUI
import UIKit

extension ChatClient {
    static var shared: ChatClient!
}

private var isStreamInternalConfiguration: Bool {
    ProcessInfo.processInfo.environment["STREAM_DEV"] != nil
}

final class DemoAppCoordinator: NSObject {
    let window: UIWindow

    init(window: UIWindow) {
        self.window = window
        
        super.init()
        
        UNUserNotificationCenter.current().delegate = self
    }
    
    func start(cid: ChannelId? = nil) {
        if let user = UserDefaults.shared.currentUser {
            showChat(for: .credentials(user), cid: cid, animated: false)
        } else {
            showLogin(animated: false)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension DemoAppCoordinator: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer {
            completionHandler()
        }

        guard let notificationInfo = try? ChatPushNotificationInfo(content: response.notification.request.content) else {
            return
        }

        guard let cid = notificationInfo.cid else {
            return
        }

        guard case UNNotificationDefaultActionIdentifier = response.actionIdentifier else {
            return
        }
        
        start(cid: cid)
    }
}

// MARK: - Navigation

private extension DemoAppCoordinator {
    func showChat(for user: DemoUserType, cid: ChannelId? = nil, animated: Bool) {
        logIn(as: user)
        
        let chatVC = makeChatVC(for: user, startOn: cid) { [weak self] in
            guard let self = self else { return }
            
            self.logOut()
        }
        
        set(rootViewController: chatVC, animated: animated)
    }
    
    func showLogin(animated: Bool) {
        let loginVC = makeLoginVC { [weak self] user in
            self?.showChat(for: user, animated: true)
        }
        
        set(rootViewController: loginVC, animated: animated)
    }
    
    func set(rootViewController: UIViewController, animated: Bool) {
        if animated {
            UIView.transition(with: window, duration: 0.3, options: .transitionFlipFromLeft) {
                self.window.rootViewController = rootViewController
            }
        } else {
            window.rootViewController = rootViewController
        }
    }
}

// MARK: - Screens factory

private extension DemoAppCoordinator {
    func makeLoginVC(onUserSelection: @escaping (DemoUserType) -> Void) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginNVC = storyboard.instantiateInitialViewController() as! UINavigationController
        
        let loginVC = loginNVC.viewControllers.first as! LoginViewController
        loginVC.onUserSelection = onUserSelection
        
        return loginNVC
    }
    
    func makeChatVC(for user: DemoUserType, startOn cid: ChannelId?, onLogout: @escaping () -> Void) -> UIViewController {
        let channelListQuery: ChannelListQuery
        switch user {
        case let .credentials(userCredentials):
            channelListQuery = .init(filter: .containMembers(userIds: [userCredentials.id]))
        case .anonymous, .guest:
            channelListQuery = .init(filter: .equal(.type, to: .messaging))
        }
        
        let channelController = cid.map { ChatClient.shared.channelController(for: $0) }
        let channelVC = channelController.map { makeChannelVC(controller: $0) }
        let channelNVC = channelVC.map { UINavigationController(rootViewController: $0) }
        
        let selectedChannel = channelController?.channel
        let channelListController = ChatClient.shared.channelListController(query: channelListQuery)
        let channelListVC = makeChannelListVC(
            controller: channelListController,
            selectedChannel: selectedChannel,
            onLogout: onLogout
        )
        let channelListNVC = UINavigationController(rootViewController: channelListVC)
        
        let splitVC = UISplitViewController()
        splitVC.preferredDisplayMode = .oneBesideSecondary
        splitVC.viewControllers = [channelListNVC, channelNVC].compactMap { $0 }
        return splitVC
    }
    
    func makeChannelListVC(
        controller: ChatChannelListController,
        selectedChannel: ChatChannel?,
        onLogout: @escaping () -> Void
    ) -> UIViewController {
        let channelListVC = DemoChatChannelListVC.make(with: controller)
        channelListVC.demoRouter.onLogout = onLogout
        channelListVC.selectedChannel = selectedChannel
        return channelListVC
    }
    
    func makeChannelVC(controller: ChatChannelController) -> UIViewController {
        let channelVC = DemoChatChannelVC()
        channelVC.channelController = controller
        return channelVC
    }
}

// MARK: - Auth

private extension DemoAppCoordinator {
    func setUpChat() {
        guard ChatClient.shared == nil else { return }
        
        // Set the log level
        LogConfig.level = .warning
        LogConfig.formatters = [
            PrefixLogFormatter(prefixes: [.info: "ℹ️", .debug: "🛠", .warning: "⚠️", .error: "🚨"])
        ]

        #if !XCODE_BETA_1
        // HTTP and WebSocket Proxy with Proxyman.app
        if isStreamInternalConfiguration || AppConfig.shared.demoAppConfig.isAtlantisEnabled {
            Atlantis.start()
        } else {
            Atlantis.stop()
        }
        #endif
        
        // Create Client
        ChatClient.shared = ChatClient(config: AppConfig.shared.chatClientConfig)
        
        // Config
        Components.default.channelListRouter = DemoChatChannelListRouter.self
        Components.default.channelVC = DemoChatChannelVC.self
        Components.default.messageContentView = DemoChatMessageContentView.self
        Components.default.messageListDateSeparatorEnabled = true
        Components.default.messageListDateOverlayEnabled = true
        Components.default._messageListDiffingEnabled = isStreamInternalConfiguration
        Components.default.messageActionsVC = DemoChatMessageActionsVC.self
        Components.default.reactionsSorting = { $0.type.position < $1.type.position }

        StreamRuntimeCheck.assertionsEnabled = isStreamInternalConfiguration
        StreamRuntimeCheck._isLazyMappingEnabled = !isStreamInternalConfiguration

        // Performance tracker
        if isStreamInternalConfiguration {
            PerformanceMonitor.shared().performanceViewConfigurator.options = [.performance]
            PerformanceMonitor.shared().start()
        }

        let localizationProvider = Appearance.default.localizationProvider
        Appearance.default.localizationProvider = { key, table in
            let localizedString = localizationProvider(key, table)
            
            return localizedString == key
                ? Bundle.main.localizedString(forKey: key, value: nil, table: table)
                : localizedString
        }
    }
    
    func connect(user: DemoUserType, completion: @escaping (Error?) -> Void) {
        switch user {
        case let .credentials(userCredentials):
            ChatClient.shared.connectUser(
                userInfo: userCredentials.userInfo,
                token: userCredentials.token,
                completion: completion
            )
        case let .guest(userId):
            ChatClient.shared.connectGuestUser(userInfo: .init(id: userId), completion: completion)
        case .anonymous:
            ChatClient.shared.connectAnonymousUser(completion: completion)
        }
    }
    
    func logIn(as user: DemoUserType) {
        UserDefaults.shared.currentUserId = user.staticUserId
        
        setUpChat()
        
        connect(user: user) { [weak self] in
            if let error = $0 {
                log.warning(error.localizedDescription)
            } else {
                self?.setupRemoteNotifications()
            }
        }
    }
    
    func logOut() {
        let currentUserController = ChatClient.shared.currentUserController()
        if let deviceId = currentUserController.currentUser?.currentDevice?.id {
            currentUserController.removeDevice(id: deviceId) { error in
                if let error = error {
                    log.warning("removing the device failed with an error \(error)")
                }
            }
        }
        
        ChatClient.shared.disconnect()
        ChatClient.shared = nil
        
        UserDefaults.shared.currentUserId = nil
        
        showLogin(animated: true)
    }
    
    func setupRemoteNotifications() {
        UNUserNotificationCenter
            .current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                guard granted else { return }
                
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
    }
}

// MARK: Custom Components for the Demo App

final class DemoChatChannelVC: ChatChannelVC {
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let debugButton = UIBarButtonItem(
            image: UIImage(systemName: "ladybug.fill")!,
            style: .plain,
            target: self,
            action: #selector(debugTap)
        )
        navigationItem.rightBarButtonItems?.append(debugButton)
    }
    
    @objc private func debugTap() {
        guard
            let cid = channelController.cid,
            let mainVC = splitViewController?.viewControllers.first as? UINavigationController,
            let channelListVC = mainVC.viewControllers.first as? DemoChatChannelListVC
        else { return }
        
        channelListVC.demoRouter.didTapMoreButton(for: cid)
    }
}

final class DemoChatChannelListVC: ChatChannelListVC, EventsControllerDelegate {
    /// The `UIButton` instance used for navigating to new channel screen creation.
    lazy var createChannelButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "plus.message")!, for: .normal)
        return button
    }()

    lazy var hiddenChannelsButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "archivebox")!, for: .normal)
        return button
    }()

    private lazy var eventsController = controller.client.eventsController()
    private lazy var connectionController = controller.client.connectionController()
    private lazy var connectionDelegate = BannerShowingConnectionDelegate(
        showUnder: navigationController!.navigationBar
    )
    
    var demoRouter: DemoChatChannelListRouter {
        router as! DemoChatChannelListRouter
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        eventsController.delegate = self
        connectionController.delegate = connectionDelegate

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(customView: hiddenChannelsButton),
            UIBarButtonItem(customView: createChannelButton)
        ]
        createChannelButton.addTarget(self, action: #selector(didTapCreateNewChannel), for: .touchUpInside)
        hiddenChannelsButton.addTarget(self, action: #selector(didTapHiddenChannelsButton), for: .touchUpInside)
    }

    @objc private func didTapCreateNewChannel(_ sender: Any) {
        demoRouter.showCreateNewChannelFlow()
    }

    @objc private func didTapHiddenChannelsButton(_ sender: Any) {
        demoRouter.showHiddenChannels()
    }
    
    var highlightSelectedChannel: Bool { splitViewController?.isCollapsed == false }
    var selectedChannel: ChatChannel?

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let channel = controller.channels[indexPath.row]
        selectedChannel = controller.channels[indexPath.row]
        router.showChannel(for: channel.cid)
    }

    override func controller(_ controller: DataController, didChangeState state: DataController.State) {
        super.controller(controller, didChangeState: state)

        if highlightSelectedChannel && (state == .remoteDataFetched || state == .localDataFetched) && selectedChannel == nil {
            guard let channel = self.controller.channels.first else { return }
            
            router.showChannel(for: channel.cid)
            
            selectedChannel = channel
        }
    }

    override func controller(_ controller: ChatChannelListController, didChangeChannels changes: [ListChange<ChatChannel>]) {
        super.controller(controller, didChangeChannels: changes)

        guard highlightSelectedChannel else { return }
        guard let selectedChannel = selectedChannel else { return }
        guard let selectedChannelRow = controller.channels.firstIndex(of: selectedChannel) else {
            return
        }

        let selectedItemIndexPath = IndexPath(row: selectedChannelRow, section: 0)

        collectionView.selectItem(
            at: selectedItemIndexPath,
            animated: false,
            scrollPosition: .centeredHorizontally
        )
    }

    func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
        if let newMessageEvent = event as? MessageNewEvent {
            // This is a DemoApp integration test to make sure there are no deadlocks when
            // accessing CoreDataLazy properties from the EventsController.delegate
            _ = newMessageEvent.message.author
        }
    }
}

final class HiddenChannelListVC: ChatChannelListVC {
    override func setUpAppearance() {
        super.setUpAppearance()

        title = "Hidden Channels"
        navigationItem.leftBarButtonItem = nil
    }
}

final class DemoChatMessageContentView: ChatMessageContentView {
    override func updateContent() {
        super.updateContent()

        if content?.isShadowed == true {
            textView?.textColor = appearance.colorPalette.textLowEmphasis
            textView?.text = "This message is from a shadow banned user"
        }

        if let translations = content?.translations, let turkishTranslation = translations[.turkish] {
            textView?.text = turkishTranslation
            if let timestampLabelText = timestampLabel?.text {
                timestampLabel?.text = "\(timestampLabelText) - Translated to Turkish"
            }
        }

        guard let authorNameLabel = authorNameLabel, authorNameLabel.text?.isEmpty == true else {
            return
        }

        guard let birthLand = content?.author.birthLand else {
            return
        }

        authorNameLabel.text?.append(" \(birthLand)")
    }
}

final class DemoChatMessageActionsVC: ChatMessageActionsVC {
    // For the propose of the demo app, we add an extra hard delete message to test it.
    override var messageActions: [ChatMessageActionItem] {
        var actions = super.messageActions
        if message?.isSentByCurrentUser == true && AppConfig.shared.demoAppConfig.isHardDeleteEnabled {
            actions.append(hardDeleteActionItem())
        }
        actions.append(translateActionItem())
        return actions
    }

    func hardDeleteActionItem() -> ChatMessageActionItem {
        HardDeleteActionItem(
            action: { [weak self] _ in
                guard let self = self else { return }
                self.alertsRouter.showMessageDeletionConfirmationAlert { confirmed in
                    guard confirmed else { return }

                    self.messageController.deleteMessage(hard: true) { _ in
                        self.delegate?.chatMessageActionsVCDidFinish(self)
                    }
                }
            },
            appearance: appearance
        )
    }
    
    func translateActionItem() -> ChatMessageActionItem {
        TranslateActionitem(
            action: { [weak self] _ in
                guard let self = self else { return }
                self.messageController.translate(to: .turkish) { _ in
                    self.delegate?.chatMessageActionsVCDidFinish(self)
                }
                
            },
            appearance: appearance
        )
    }

    struct HardDeleteActionItem: ChatMessageActionItem {
        var title: String { "Hard Delete Message" }
        var isDestructive: Bool { true }
        let icon: UIImage
        let action: (ChatMessageActionItem) -> Void

        init(
            action: @escaping (ChatMessageActionItem) -> Void,
            appearance: Appearance = .default
        ) {
            self.action = action
            icon = appearance.images.messageActionDelete
        }
    }
    
    struct TranslateActionitem: ChatMessageActionItem {
        var title: String { "Translate to Turkish" }
        var isDestructive: Bool { false }
        let icon: UIImage
        let action: (ChatMessageActionItem) -> Void
        
        init(
            action: @escaping (ChatMessageActionItem) -> Void,
            appearance: Appearance = .default
        ) {
            self.action = action
            icon = UIImage(systemName: "flag.fill")!
        }
    }
}

extension MessageReactionType {
    var position: Int {
        switch rawValue {
        case "love": return 0
        case "haha": return 1
        case "like": return 2
        case "sad": return 3
        case "wow": return 4
        default: return 5
        }
    }
}

private extension DemoUserType {
    var staticUserId: UserId? {
        guard case let .credentials(user) = self else { return nil }
        
        return user.id
    }
}
