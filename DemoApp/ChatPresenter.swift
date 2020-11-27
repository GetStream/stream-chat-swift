//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

extension UIViewController {
    // TODO: Where to put this???
    func presentChat(userCredentials: UserCredentials) {
        // Create client
        let config = ChatClientConfig(apiKey: .init(userCredentials.apiKey))
        let client = ChatClient(config: config)
        
        // Log in the current user
        let currentUserController = client.currentUserController()
        currentUserController.setUser(userId: userCredentials.id, token: userCredentials.token) { error in
            if let error = error {
                print("User login failed: \(error)")
            }
        }
        
        // Channels with the current user
        let controller = client.channelListController(query: .init(filter: .containMembers(userIds: [userCredentials.id])))
        let chatList = ChatChannelListVC<DefaultExtraData>()
        chatList.controller = controller
        
        let chatNavigationController = UINavigationController(rootViewController: chatList)
        
        UIView.transition(with: view.window!, duration: 0.3, options: .transitionFlipFromRight, animations: {
            self.view.window!.rootViewController = chatNavigationController
        })
    }
}
