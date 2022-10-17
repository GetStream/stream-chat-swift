//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI

extension StreamChatWrapper {
    
    func configureUI() {
        // Customization
        var components = Components.default
        components.channelListRouter = CustomChannelListRouter.self
        components.messageListRouter = CustomMessageListRouter.self
        components.channelVC = ChannelVC.self
        components.threadVC = ThreadVC.self
        Components.default = components
        Components.default.messageActionsVC = MessageActionsVC.self
    }
    
}
