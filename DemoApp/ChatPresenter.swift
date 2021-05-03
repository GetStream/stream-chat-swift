//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
// We use @testable import here because router motification is currently available only in beta
@testable import StreamChatUI
import UIKit

class DemoChatChannelListRouter: _ChatChannelListRouter<NoExtraData> {
    override func openCreateNewChannel() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        
        let chatViewController = storyboard.instantiateViewController(withIdentifier: "CreateChatViewController")
            as! CreateChatViewController
        chatViewController.searchController = rootViewController?.controller.client.userSearchController()
        
        navigationController?.pushViewController(chatViewController, animated: true)
    }
}
