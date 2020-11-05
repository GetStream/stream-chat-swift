//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

open class ChatUIChannelRead {
    /// The last time the user has read the channel.
    public let lastReadAt: Date
    
    /// Number of unread messages the user has in this channel.
    public let unreadMessagesCount: Int
    
    /// The user who read the channel.
    public let user: ChatUIUser
    
    public required init<ExtraData: ExtraDataTypes>(config: UIModelConfig = .default, channelRead: _ChatChannelRead<ExtraData>) {
        lastReadAt = channelRead.lastReadAt
        unreadMessagesCount = channelRead.unreadMessagesCount
        user = config.userModelType.init(user: channelRead.user, name: channelRead.user.name, imageURL: channelRead.user.imageURL)
    }
}
