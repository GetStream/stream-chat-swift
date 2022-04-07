//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Atlantis
import StreamChat
import StreamChatUI
import UIKit

extension ChatClient {
    static var shared: ChatClient!
}

private var isStreamInternalConfiguration: Bool {
    ProcessInfo.processInfo.environment["STREAM_DEV"] != nil
}

final class DemoAppCoordinator: NSObject, UNUserNotificationCenterDelegate {
    var connectionController: ChatConnectionController?
    let navigationController: UINavigationController
    let connectionDelegate: BannerShowingConnectionDelegate

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        connectionDelegate = BannerShowingConnectionDelegate(
            showUnder: navigationController.navigationBar
        )
        super.init()

        injectActions()
    }
    
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
        
        if let userId = UserDefaults(suiteName: applicationGroupIdentifier)?.string(forKey: currentUserIdRegisteredForPush),
           let userCredentials = UserCredentials.builtInUsersByID(id: userId) {
            presentChat(userType: .credentials(userCredentials), channelID: cid)
        }
    }

    func setupRemoteNotifications() {
        UNUserNotificationCenter
            .current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                if granted {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
    }
    
    func setUpChat() {
        // Set the log level
        LogConfig.level = .warning
        LogConfig.formatters = [
            PrefixLogFormatter(prefixes: [.info: "ℹ️", .debug: "🛠", .warning: "⚠️", .error: "🚨"])
        ]

        // HTTP and WebSocket Proxy with Proxyman.app
        if AppConfig.shared.demoAppConfig.isAtlantisEnabled {
            Atlantis.start()
        } else {
            Atlantis.stop()
        }
        
        // Create Client
        ChatClient.shared = ChatClient(config: AppConfig.shared.chatClientConfig)
        
        // Config
        Components.default.channelListRouter = DemoChatChannelListRouter.self
        Components.default.channelVC = CustomChannelVC.self
        Components.default.messageContentView = CustomMessageContentView.self
        Components.default.messageListDateSeparatorEnabled = true
        Components.default.messageListDateOverlayEnabled = true
        Components.default._messageListDiffingEnabled = isStreamInternalConfiguration
        Components.default.messageActionsVC = CustomChatMessageActionsVC.self

        StreamRuntimeCheck.assertionsEnabled = isStreamInternalConfiguration

        let localizationProvider = Appearance.default.localizationProvider
        Appearance.default.localizationProvider = { key, table in
            let localizedString = localizationProvider(key, table)
            
            return localizedString == key
                ? Bundle.main.localizedString(forKey: key, value: nil, table: table)
                : localizedString
        }
        
        // Setup connection observer
        connectionController = ChatClient.shared.connectionController()
        connectionController?.delegate = connectionDelegate
    }

    func presentChat(userType: DemoUserType, channelID: ChannelId? = nil) {
        if ChatClient.shared == nil {
            setUpChat()
        }
        
        let controller: ChatChannelListController
        
        switch userType {
        case let .credentials(userCredentials):
            // Create a token
            guard let token = try? Token(rawValue: userCredentials.token) else {
                fatalError("There has been a problem getting the token, please check Stream API status")
            }
            
            // Connect the User
            ChatClient.shared.connectUser(
                userInfo: userCredentials.userInfo,
                token: token
            ) { [weak self] error in
                if let error = error {
                    log.error("connecting the user failed \(error)")
                    return
                }
                self?.setupRemoteNotifications()
            }
            
            // Channels with the current user
            controller = ChatClient.shared
                .channelListController(query: .init(filter: .containMembers(userIds: [userCredentials.id])))
        case .anonymous:
            ChatClient.shared.connectAnonymousUser { [weak self] error in
                if let error = error {
                    log.error("connecting the user failed \(error)")
                    return
                }
                self?.setupRemoteNotifications()
            }
            controller = ChatClient.shared
                .channelListController(query: .init(filter: .equal(.type, to: .messaging)))
        case let .guest(userId):
            ChatClient.shared.connectGuestUser(userInfo: .init(id: userId)) { [weak self] error in
                if let error = error {
                    log.error("connecting the user failed \(error)")
                    return
                }
                self?.setupRemoteNotifications()
            }
            controller = ChatClient.shared
                .channelListController(query: .init(filter: .equal(.type, to: .messaging)))
        }
        
        let chatList = DemoChannelListVC.make(with: controller)

        navigationController.viewControllers = [chatList]
        navigationController.isNavigationBarHidden = false
        
        // Init the channel VC and navigate there directly
        if let cid = channelID {
            let channelVC = CustomChannelVC()
            channelVC.channelController = ChatClient.shared.channelController(for: cid)
            navigationController.viewControllers.append(channelVC)
        }

        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        let window = navigationController.view.window!
        let rootVC: UIViewController = isIpad
            ? makeSplitViewController(channelListVC: chatList)
            : navigationController

        UIView.transition(with: window, duration: 0.3, options: .transitionFlipFromRight, animations: {
            window.rootViewController = rootVC
        })
    }
    
    private func injectActions() {
        if let loginViewController = navigationController.topViewController as? LoginViewController {
            loginViewController.didRequestChatPresentation = { [weak self] in
                self?.presentChat(userType: $0)
            }
        }
    }

    private func makeSplitViewController(channelListVC: DemoChannelListVC) -> UISplitViewController {
        let makeChannelVC: (String) -> UIViewController = { cid in
            let channelVC = CustomChannelVC()
            let channelController = channelListVC.controller.client.channelController(
                for: ChannelId(type: .messaging, id: cid),
                channelListQuery: channelListVC.controller.query
            )
            channelVC.channelController = channelController
            return UINavigationController(rootViewController: channelVC)
        }

        let splitController = UISplitViewController()
        splitController.viewControllers = [channelListVC, UIViewController()]
        splitController.preferredDisplayMode = .oneBesideSecondary

        channelListVC.didSelectChannel = { channel in
            splitController.viewControllers[1] = makeChannelVC(channel.cid.id)
        }

        return splitController
    }
}

// MARK: Custom Components for the Demo App

class CustomChannelVC: ChatChannelVC {
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
    
    @objc func debugTap() {
        if let cid = channelController.cid {
            (navigationController?.viewControllers.first as? ChatChannelListVC)?.router.didTapMoreButton(for: cid)
        }
    }
}

class DemoChannelListVC: ChatChannelListVC, EventsControllerDelegate {
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

    let eventsController = ChatClient.shared.eventsController()

    override func viewDidLoad() {
        super.viewDidLoad()

        eventsController.delegate = self

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(customView: hiddenChannelsButton),
            UIBarButtonItem(customView: createChannelButton)
        ]
        createChannelButton.addTarget(self, action: #selector(didTapCreateNewChannel), for: .touchUpInside)
        hiddenChannelsButton.addTarget(self, action: #selector(didTapHiddenChannelsButton), for: .touchUpInside)
    }

    @objc private func didTapCreateNewChannel(_ sender: Any) {
        (router as! DemoChatChannelListRouter).showCreateNewChannelFlow()
    }

    @objc private func didTapHiddenChannelsButton(_ sender: Any) {
        let channelListVC = HiddenChannelListVC()
        channelListVC.controller = controller
            .client
            .channelListController(
                query: .init(
                    filter: .and(
                        [
                            .containMembers(userIds: [controller.client.currentUserId!]),
                            .equal(.hidden, to: true)
                        ]
                    )
                )
            )
        navigationController?.pushViewController(channelListVC, animated: true)
    }

    var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var didSelectChannel: ((ChatChannel) -> Void)?
    var selectedChannel: ChatChannel? {
        didSet {
            if selectedChannel != oldValue, let channel = selectedChannel {
                didSelectChannel?(channel)
            }
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isPad {
            let channel = controller.channels[indexPath.row]
            selectedChannel = channel
            return
        }

        super.collectionView(collectionView, didSelectItemAt: indexPath)
    }

    override func controller(_ controller: DataController, didChangeState state: DataController.State) {
        super.controller(controller, didChangeState: state)

        if isPad && (state == .remoteDataFetched || state == .localDataFetched) {
            guard let channel = self.controller.channels.first else { return }
            selectedChannel = channel
        }
    }

    override func controller(_ controller: ChatChannelListController, didChangeChannels changes: [ListChange<ChatChannel>]) {
        super.controller(controller, didChangeChannels: changes)

        guard isPad else { return }
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

class HiddenChannelListVC: ChatChannelListVC {
    override func setUpAppearance() {
        super.setUpAppearance()

        title = "Hidden Channels"
        navigationItem.leftBarButtonItem = nil
    }
}

class CustomChatMessageActionsVC: ChatMessageActionsVC {
    // For the propose of the demo app, we add an extra hard delete message to test it.
    override var messageActions: [ChatMessageActionItem] {
        var actions = super.messageActions
        if message?.isSentByCurrentUser == true && AppConfig.shared.demoAppConfig.isHardDeleteEnabled {
            actions.append(hardDeleteActionItem())
        }
        actions.append(translateActionItem())
        return actions
    }

    open func hardDeleteActionItem() -> ChatMessageActionItem {
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
    
    open func translateActionItem() -> ChatMessageActionItem {
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

    public struct HardDeleteActionItem: ChatMessageActionItem {
        public var title: String { "Hard Delete Message" }
        public var isDestructive: Bool { true }
        public let icon: UIImage
        public let action: (ChatMessageActionItem) -> Void

        public init(
            action: @escaping (ChatMessageActionItem) -> Void,
            appearance: Appearance = .default
        ) {
            self.action = action
            icon = appearance.images.messageActionDelete
        }
    }
    
    public struct TranslateActionitem: ChatMessageActionItem {
        public var title: String { "Translate to Turkish" }
        public var isDestructive: Bool { false }
        public let icon: UIImage
        public let action: (ChatMessageActionItem) -> Void
        
        public init(
            action: @escaping (ChatMessageActionItem) -> Void,
            appearance: Appearance = .default
        ) {
            self.action = action
            icon = UIImage(systemName: "flag.fill")!
        }
    }
}
