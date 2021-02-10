//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

func snippet_ux_quick_start_messages_storyboard() {
    // > import UIKit
    // > import StreamChatUI
    // > import StreamChat
    
    class MyChannelVC: ChatChannelVC {}

    @available(iOS 13.0, *)
    class SceneDelegate: UIResponder, UIWindowSceneDelegate {
        var window: UIWindow?
         
        func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
            guard let _ = (scene as? UIWindowScene) else { return }
             
            // Find a UINavigationController from the window root view controller.
            if let navigationController = window?.rootViewController as? UINavigationController,
                // Get a MyChannelVC from the navigation controller.
                let channelVC = navigationController.viewControllers.first as? MyChannelVC {
                // Pass a ChatChannelController instance to channelVC:
                channelVC.channelController = chatClient.channelController(for: .init(type: .messaging, id: "general"))
            }
        }
    }
}
