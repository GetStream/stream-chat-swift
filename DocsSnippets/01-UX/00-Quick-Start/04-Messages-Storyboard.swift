// LINK: https://getstream.io/chat/docs/ios-swift/ios_quick_start/?preview=1&language=swift#messages

import StreamChat
import StreamChatUI
import UIKit

private var chatClient: ChatClient!

@available(iOS 13, *)
func snippet_ux_quick_start_messages_code() {
    // > import UIKit
    // > import StreamChatUI
    // > import StreamChat

    class MyChannelVC: ChatChannelVC {}

    class SceneDelegate: UIResponder, UIWindowSceneDelegate {
        var window: UIWindow?
        
        func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
            guard let scene = scene as? UIWindowScene else { return }
        
            let channelVC = ChatChannelVC()
            channelVC.channelController = chatClient.channelController(for: .init(type: .messaging, id: "general"))
            
            let window = UIWindow(windowScene: scene)
            window.rootViewController = UINavigationController(rootViewController: channelVC)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
