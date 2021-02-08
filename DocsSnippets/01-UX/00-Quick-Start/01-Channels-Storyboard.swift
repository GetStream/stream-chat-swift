//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

func snippet_ux_quick_start_channels_storyboard() {
    // > import UIKit
    // > import StreamChatUI
    
    class MyChannelListVC: ChatChannelListVC {}

    @available(iOS 13.0, *)
    class SceneDelegate: UIResponder, UIWindowSceneDelegate {
        var window: UIWindow?
         
        func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
            guard let _ = (scene as? UIWindowScene) else { return }
             
            // Find a UINavigationController from the window root view controller.
            if let navigationController = window?.rootViewController as? UINavigationController,
                // Get MyChannelListVC from the navigation controller.
                let channelListVC = navigationController.viewControllers.first as? MyChannelListVC {
                // Filter channels by the current user.
                if let currentUserId = chatClient.currentUserId {
                    channelListVC.controller = chatClient
                        .channelListController(query: .init(filter: .containMembers(userIds: [currentUserId])))
                }
            }
        }
    }
}
