//
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import StreamChatUI

final class SlackChatChannelListRouter: ChatChannelListRouter {
    override func openChat(for channel: _ChatChannel<NoExtraData>) {
        let vc = SlackChatChannelViewController()
        vc.channelController = rootViewController.controller.client.channelController(for: channel.cid)
        
        guard let navController = navigationController else {
            log.error("Can't push chat detail, no navigation controller available")
            return
        }
        
        navController.show(vc, sender: self)
    }
    
    override func openCreateNewChannel() {
    }
}

