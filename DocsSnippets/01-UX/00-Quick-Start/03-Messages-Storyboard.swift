// LINK: https://getstream.io/chat/docs/ios-swift/ios_quick_start/?preview=1&language=swift#messages

import StreamChat
import StreamChatUI
import UIKit

private var chatClient: ChatClient!

@available(iOS 13, *)
func snippet_ux_quick_start_messages_storyboard() {
    // > import UIKit
    // > import StreamChatUI
    // > import StreamChat
    
    class MyChannelVC: ChatChannelVC {}

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
