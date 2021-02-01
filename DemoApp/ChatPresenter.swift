//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

extension UIViewController {
    func handleDeepLink(
        userCredentials: UserCredentials = UserCredentials.getLatest() ?? UserCredentials.builtInUsers[0],
        deepLink: URL? = nil
    ) {
        LogConfig.level = .error
        
        // Create a token
        let token = try! Token(rawValue: userCredentials.token)
        
        // Create config
        var config = ChatClientConfig(apiKey: .init(userCredentials.apiKey))
        // Set database to app group location to share data with chat widget
        config.localStorageFolderURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: UserDefaults.groupId)
        // Create client
        let client = ChatClient.current! // ?? ChatClient(config: config, tokenProvider: .static(token))

        // Config
        UIConfig.default.navigation.channelListRouter = DemoChatChannelListRouter.self

        // Channels with the current user
        let controller = client.channelListController(query: .init(filter: .containMembers(userIds: [userCredentials.id])))
        let chatList = ChatChannelListVC()
        chatList.controller = controller
        
        let chatNavigationController = UINavigationController(rootViewController: chatList)
        
        // If deep linking, move straight to channel
        if let deepLink = deepLink {
            var host = deepLink.absoluteString
            host.removeFirst("demoapp://".count)
            let channelVC = ChatChannelVC()
            let channelId = ChannelId(type: .messaging, id: host)
            channelVC.channelController = client.channelController(for: channelId)
            channelVC.userSuggestionSearchController = client.userSearchController()
            
            chatNavigationController.pushViewController(channelVC, animated: false)
            view.window!.rootViewController = chatNavigationController
        } else {
            UIView.transition(with: view.window!, duration: 0.3, options: .transitionFlipFromRight, animations: {
                self.view.window!.rootViewController = chatNavigationController
            })
        }
        
        userCredentials.save()
        
        ChatClient.current = client
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
