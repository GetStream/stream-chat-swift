// LINK: https://getstream.io/chat/docs/ios-swift/ios_client_setup/?preview=1&language=swift#basic-setup

import StreamChat
import UIKit

private var chatClient: ChatClient!

func snippet_ux_client_setup_basic_setup() {
    // > import UIKit
    // > import StreamChat

    @UIApplicationMain
    class AppDelegate: UIResponder, UIApplicationDelegate {
        func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        ) -> Bool {
            /// 1: Create a static token provider. Use it for testing purposes.
            let token = Token("{{ chat_user_token }}")
            let tokenProvider = TokenProvider.static(token)

            /// 2: Create a `ChatClientConfig` with the API key.
            let config = ChatClientConfig(apiKeyString: "{{ api_key }}")

            /// 3: Create a `ChatClient` instance with the config and the token provider.
            chatClient = ChatClient(config: config, tokenProvider: tokenProvider)
            
            return true
        }
    }
}
