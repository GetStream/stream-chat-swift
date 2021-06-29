//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class DemoAppCoordinator {
    private var connectionController: ChatConnectionController?
    private let navigationController: UINavigationController
    private let connectionDelegate: BannerShowingConnectionDelegate
    
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
        let client = ChatClient(config: config)
        client.connectUser(token: token)
        
        // Config
        Components.default.channelListRouter = DemoChatChannelListRouter.self
        Components.default.messageListVC = CustomMessageListVC.self
        
        // Channels with the current user
        let controller = client.channelListController(query: .init(filter: .containMembers(userIds: [userCredentials.id])))
        let chatList = DemoChannelListVC()
        chatList.controller = controller
        
        connectionController = client.connectionController()
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
