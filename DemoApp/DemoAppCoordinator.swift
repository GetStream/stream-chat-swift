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
        let channelVC = CustomChannelVC()
        channelVC.channelController = channelListVC.controller.client.channelController(
            for: ChannelId(type: .messaging, id: "unknown"),
            channelListQuery: channelListVC.controller.query
        )

        channelListVC.didSelectChannel = { channel in
            channelVC.channelController = channelListVC.controller.client.channelController(
                for: channel.cid,
                channelListQuery: channelListVC.controller.query
            )
            channelVC.messageListVC.listView.reloadData()
            channelVC.setUp()
        }

        let splitController = UISplitViewController()
        splitController.viewControllers = [channelListVC, UINavigationController(rootViewController: channelVC)]
        splitController.preferredDisplayMode = .oneBesideSecondary
        return splitController
    }
}

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
