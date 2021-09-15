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
        // Since log is first touched in `BannerShowingConnectionDelegate`,
        // we need to set log level here
        LogConfig.level = .warning
        
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
        let token = try! Token(rawValue: userCredentials.token)
        
        // Create client
        var config = ChatClientConfig(apiKey: .init(apiKeyString))
//        config.isLocalStorageEnabled = true
        config.applicationGroupIdentifier = applicationGroupIdentifier

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
        Components.default.reactionsBubbleView = CustomChatMessageReactionsBubbleView.self
        Components.default.channelListRouter = DemoChatChannelListRouter.self
        Components.default.messageListVC = CustomMessageListVC.self
        Components.default.messageContentView = CustomMessageContentView.self
        Appearance.default.localizationProvider = { key, table in
            Bundle.main.localizedString(forKey: key, value: nil, table: table)
        }

        // Channels with the current user
        let controller = ChatClient.shared
            .channelListController(query: .init(filter: .containMembers(userIds: [userCredentials.id])))
        let chatList = DemoChannelListVC()
        chatList.controller = controller
        
        connectionController = ChatClient.shared.connectionController()
        connectionController?.delegate = connectionDelegate
        
        navigationController.viewControllers = [chatList]
        navigationController.isNavigationBarHidden = false
        
        // Init the channel VC and navigate there directly
        if let cid = channelID {
            let channelVC = ChatChannelVC()
            channelVC.channelController = ChatClient.shared.channelController(for: cid)
            navigationController.viewControllers.append(channelVC)
        }
        
        let window = navigationController.view.window!
        UIView.transition(with: window, duration: 0.3, options: .transitionFlipFromRight, animations: {
            window.rootViewController = self.navigationController
            
        })
    }
    
    private func injectActions() {
        if let loginViewController = navigationController.topViewController as? LoginViewController {
            loginViewController.didRequestChatPresentation = { [weak self] in
                self?.presentChat(userCredentials: $0)
            }
        }
    }
}

class CustomChatMessageReactionsBubbleView: ChatMessageDefaultReactionsBubbleView {
    override open func layoutSubviews() {
        super.layoutSubviews()
        contentViewBackground.layer.cornerRadius = 0
    }

    override open var contentBackgroundColor: UIColor {
        .init(red: 0.96, green: 0.92, blue: 0.017, alpha: 1.0)
    }

    override open var contentBorderColor: UIColor {
        .init(red: 0.054, green: 0.36, blue: 0.39, alpha: 1.0)
    }

    override open var tailBackImage: UIImage? { nil }
    
    override open var tailFrontImage: UIImage? { nil }
}

class CustomMessageListVC: ChatMessageListVC {
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
        if let cid = dataSource?.channel(for: self)?.cid {
            (navigationController?.viewControllers.first as? ChatChannelListVC)?.router.didTapMoreButton(for: cid)
        }
    }
}
