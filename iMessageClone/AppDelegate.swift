//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UIConfig.default.channelList.itemView = iMessageChatChannelListItemView.self
        UIConfig.default.channelList.cellSeparatorReusableView = iMessageCellSeparatorView.self
        
        UIConfig.default.navigation.channelListRouter = iMessageChatChannelListRouter.self
        UIConfig.default.images.newChat = UIImage(systemName: "square.and.pencil")!
        UIConfig.default.messageComposer.messageComposerView = iMessageChatMessageComposerView.self
        UIConfig.default.messageList.messageContentView = iMessageChatMessageContentView.self
        UIConfig.default.messageList.outgoingMessageCell = iMessageСhatMessageCollectionViewCell.self
        UIConfig.default.messageList.incomingMessageCell = iMessageСhatMessageCollectionViewCell.self
        UIConfig.default.messageComposer.messageComposerViewController = iMessageChatComposerViewController.self
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        window?.rootViewController = UINavigationController(
            rootViewController: iMessageChatChannelListViewController()
        )

        return true
    }
}

extension ChatClient {
    /// The singleton instance of `ChatClient`
    static let shared: ChatClient = {
        let config = ChatClientConfig(apiKey: APIKey("q95x9hkbyd6p"))
        return ChatClient(
            config: config,
            tokenProvider: .static(
                "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiY2lsdmlhIn0.jHi2vjKoF02P9lOog0kDVhsIrGFjuWJqZelX5capR30"
            )
        )
    }()
}
