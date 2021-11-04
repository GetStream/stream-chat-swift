// LINK: https://getstream.io/chat/docs/ios-swift/ios_quick_start/?preview=1&language=swift#2.-using-code

import StreamChat
import StreamChatUI
import UIKit

private var chatClient: ChatClient!

@available(iOS 13, *)
func snippet_ux_quick_start_channels_code() {
    // > import UIKit
    // > import StreamChatUI
    // > import StreamChat
    
    class SceneDelegate: UIResponder, UIWindowSceneDelegate {
        var window: UIWindow?
        
        func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
            guard let scene = scene as? UIWindowScene else { return }
            
            let channelListController = chatClient
                .channelListController(
                    query: ChannelListQuery(
                        filter: .containMembers(
                            userIds: [chatClient.currentUserId!]
                        )
                    )
                )
            let channelList = ChatChannelListVC.createChannelVC(channelListController, storyboard: nil, storyboardId: nil)
            
            let window = UIWindow(windowScene: scene)
            window.rootViewController = UINavigationController(rootViewController: channelList)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
