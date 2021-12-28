//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

extension ChatClient {
    static var shared: ChatClient!
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
            presentChat(userCredentials: userCredentials, channelID: cid)
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

    func presentChat(userCredentials: UserCredentials, channelID: ChannelId? = nil) {
        // Create a token
        guard let token = try? Token(rawValue: userCredentials.token) else {
            fatalError("There has been a problem getting the token, please check Stream API status")
        }
        
        // Set the log level
        LogConfig.level = .warning
        LogConfig.formatters = [
            PrefixLogFormatter(prefixes: [.info: "ℹ️", .debug: "🛠", .warning: "⚠️", .error: "🚨"])
        ]
        
        // Define the Config
        var config = ChatClientConfig(apiKey: .init(apiKeyString))
//        config.isLocalStorageEnabled = true
        config.shouldShowShadowedMessages = true
        config.applicationGroupIdentifier = applicationGroupIdentifier

        // Connect the User
        ChatClient.shared = ChatClient(config: config)
        ChatClient.shared.connectUser(
            userInfo: .init(id: userCredentials.id, name: userCredentials.name, imageURL: userCredentials.avatarURL),
            token: token
        ) { error in
            if let error = error {
                log.error("connecting the user failed \(error)")
                return
            }
            self.setupRemoteNotifications()
        }
        
        // Config
        Components.default.channelListRouter = DemoChatChannelListRouter.self
        Components.default.channelVC = CustomChannelVC.self
        Components.default.messageContentView = CustomMessageContentView.self
        Components.default.messageListDateSeparatorEnabled = true
        Components.default.messageListDateOverlayEnabled = true
        
        let localizationProvider = Appearance.default.localizationProvider
        Appearance.default.localizationProvider = { key, table in
            let localizedString = localizationProvider(key, table)
            
            return localizedString == key
                ? Bundle.main.localizedString(forKey: key, value: nil, table: table)
                : localizedString
        }

        // Channels with the current user
        let controller = ChatClient.shared
            .channelListController(query: .init(filter: .containMembers(userIds: [userCredentials.id])))
        let chatList = DemoChannelListVC.make(with: controller)
        
        connectionController = ChatClient.shared.connectionController()
        connectionController?.delegate = connectionDelegate
        
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
                self?.presentChat(userCredentials: $0)
            }
        }
    }

    private func makeSplitViewController(channelListVC: DemoChannelListVC) -> UISplitViewController {
        let makeChannelController: (String) -> ChatChannelController = { cid in
            channelListVC.controller.client.channelController(
                for: ChannelId(type: .messaging, id: cid),
                channelListQuery: channelListVC.controller.query
            )
        }

        let channelVC = CustomChannelVC()
        channelVC.channelController = makeChannelController("unknown")

        channelListVC.didSelectChannel = { channel in
            channelVC.channelController = makeChannelController(channel.cid.id)
            channelVC.messageListVC.listView.reloadData()
            channelVC.setUp()
        }

        let splitController = UISplitViewController()
        splitController.viewControllers = [channelListVC, UINavigationController(rootViewController: channelVC)]
        splitController.preferredDisplayMode = .oneBesideSecondary
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

class DemoChannelListVC: ChatChannelListVC {
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

    override func viewDidLoad() {
        super.viewDidLoad()

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

    override func controller(_ controller: ChatChannelListController, shouldListUpdatedChannel channel: ChatChannel) -> Bool {
        channel.lastActiveMembers.contains(where: { $0.id == controller.client.currentUserId })
    }

    override func controller(_ controller: ChatChannelListController, shouldAddNewChannelToList channel: ChatChannel) -> Bool {
        channel.lastActiveMembers.contains(where: { $0.id == controller.client.currentUserId })
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
}

class HiddenChannelListVC: ChatChannelListVC {
    override func setUpAppearance() {
        super.setUpAppearance()

        title = "Hidden Channels"
        navigationItem.leftBarButtonItem = nil
    }
}
