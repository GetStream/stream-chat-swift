//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelListRouter<ExtraData: ExtraDataTypes>: ChatRouter<ChatChannelListVC<ExtraData>> {
    open func openCurrentUserProfile(for currentUser: _CurrentChatUser<ExtraData.User>) {
        debugPrint(currentUser)
    }
    
    open func openChat(for channel: _ChatChannel<ExtraData>) {
        guard let client = rootViewController?.controller.client else {
            log.error("Can't open chat detail, the root controller is `nil`.")
            return
        }
        
        let vc = ChatChannelVC<ExtraData>()
        vc.controller = client.channelController(for: channel.cid)
        
        guard let navController = rootViewController?.navigationController else {
            log.error("Can't push chat detail, no navigation controller available")
            return
        }
        
        navController.show(vc, sender: self)
    }
    
    open func openCreateNewChannel() {
        debugPrint("openCreateNewChannel")
    }
}
