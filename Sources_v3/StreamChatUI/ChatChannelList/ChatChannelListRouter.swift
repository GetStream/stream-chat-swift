//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelListRouter<ExtraData: UIExtraDataTypes>: ChatRouter<ChatChannelListVC<ExtraData>> {
    open func openCurrentUserProfile(for currentUser: _CurrentChatUser<ExtraData.User>) {
        debugPrint(currentUser)
    }
    
    open func openChat(for channel: _ChatChannel<ExtraData>) {
        debugPrint(channel)
    }
    
    open func openCreateNewChannel() {
        debugPrint("openCreateNewChannel")
    }
}
