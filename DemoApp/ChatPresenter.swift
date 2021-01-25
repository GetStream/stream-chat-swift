//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

extension UIViewController {
    // TODO: Where to put this???
    func presentChat(userCredentials: UserCredentials) {
        LogConfig.level = .error

        // Create a token
        let token = try! Token(rawValue: userCredentials.token)
        
        // Create client
        let config = ChatClientConfig(apiKey: .init(userCredentials.apiKey))
        let client = ChatClient(config: config, tokenProvider: .static(token))

        // Config
        var uiConfig = UIConfig<NoExtraData>()
        uiConfig.navigation.channelListRouter = DemoChatChannelListRouter.self
        
        // Channels with the current user
        let controller = client.channelListController(query: .init(filter: .containMembers(userIds: [userCredentials.id])))
        let chatList = ChatChannelListVC<NoExtraData>()
        chatList.controller = controller
        chatList.uiConfig = uiConfig
        
        let chatNavigationController = UINavigationController(rootViewController: chatList)
        
        UIView.transition(with: view.window!, duration: 0.3, options: .transitionFlipFromRight, animations: {
            self.view.window!.rootViewController = chatNavigationController
        })
    }
}

class DemoChatChannelListRouter: _ChatChannelListRouter<NoExtraData> {
    override func openCreateNewChannel() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        
        let chatViewController = storyboard.instantiateViewController(withIdentifier: "CreateChatViewController")
            as! CreateChatViewController
        chatViewController.searchController = rootViewController.controller.client.userSearchController()
        
        navigationController?.pushViewController(chatViewController, animated: true)
    }
}
