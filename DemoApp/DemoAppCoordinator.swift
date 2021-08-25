//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

extension ChatClient {
    static var shared: ChatClient!
}

final class DemoAppCoordinator {
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
        injectActions()
    }
    
    func presentChat(userCredentials: UserCredentials) {
        // Create a token
        let token = try! Token(rawValue: userCredentials.token)
        
        // Create client
        let config = ChatClientConfig(apiKey: .init(userCredentials.apiKey))
        ChatClient.shared = ChatClient(config: config)
        ChatClient.shared.connectUser(
            userInfo: .init(id: userCredentials.id, extraData: [ChatUser.birthLandFieldName: .string(userCredentials.birthLand)]),
            token: token
        ) { error in
            print("debugging: connectUser completion called")
            if let error = error {
                print("debugging: connectUser completion errored")
                log.error("connecting the user failed \(error)")
                return
            }

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
        
        // Config
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
        if let cid = channelController.cid {
            (navigationController?.viewControllers.first as? ChatChannelListVC)?.router.didTapMoreButton(for: cid)
        }
    }
}
