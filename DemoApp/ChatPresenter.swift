//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

extension UIViewController {
    func handleDeepLink(
        userCredentials: UserCredentials = UserCredentials.getLatest() ?? UserCredentials.builtInUsers[0],
        deepLink: URL
    ) {
        LogConfig.level = .error

        // Get current client or create one from credentials (first launch)
        let client = ChatClient.current ?? {
            let client = ChatClient.forCredentials(userCredentials)
            ChatClient.current = client
            return client
        }()

        // Channels with the current user
        let controller = client.channelListController(query: .init(filter: .containMembers(userIds: [userCredentials.id])))
        let chatList = ChatChannelListVC()
        chatList.controller = controller
        
        let chatNavigationController = UINavigationController(rootViewController: chatList)
        
        // Move straight to deep-linked channel
        var host = deepLink.absoluteString
        host.removeFirst("demoapp://".count)
        let channelVC = ChatChannelVC()
        let channelId = ChannelId(type: .messaging, id: host)
        channelVC.channelController = client.channelController(for: channelId)
        channelVC.userSuggestionSearchController = client.userSearchController()
        
        if let window = view.window ?? UIApplication.shared.windows.first {
            chatNavigationController.pushViewController(channelVC, animated: false)
            window.rootViewController = chatNavigationController
            UIView.transition(with: window, duration: 0.3, options: .transitionFlipFromRight, animations: {
                window.rootViewController = chatNavigationController
            })
        }
        
        userCredentials.save()
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
