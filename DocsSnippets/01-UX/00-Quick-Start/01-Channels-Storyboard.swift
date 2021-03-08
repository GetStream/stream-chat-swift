// LINK: https://getstream.io/chat/docs/ios-swift/ios_quick_start/?preview=1&language=swift#1.-using-a-storyboard

import StreamChat
import StreamChatUI
import UIKit

private var chatClient: ChatClient!

@available(iOS 13, *)
func snippet_ux_quick_start_channels_storyboard() {
    // > import UIKit
    // > import StreamChat
    // > import StreamChatUI
    
    class MyChannelListVC: ChatChannelListVC {}

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
