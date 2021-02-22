// LINK: https://getstream.io/chat/docs/ios-swift/ios_styles/?preview=1&language=swift#changing-main-color

import StreamChatUI
import UIKit

@available(iOS 13, *)
func snippets_ux_customizing_views_changing_main_color() {
    // > import UIKit
    // > import StreamChatUI

    class SceneDelegate: UIResponder, UIWindowSceneDelegate {
        func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
            guard let scene = scene as? UIWindowScene else { return }
            scene.windows.forEach { $0.tintColor = .systemPink }
        }
    }
}
