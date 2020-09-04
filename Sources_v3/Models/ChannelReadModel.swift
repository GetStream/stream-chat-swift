//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type reprsenting a user's last read action on a channel.
public struct ChannelReadModel<ExtraData: ExtraDataTypes> {
    /// The last time the user has read the channel.
    public let lastReadAt: Date
    
    /// Number of unread messages the user has in this channel.
    public let unreadMessagesCount: Int
    
    /// The user who read the channel.
    public let user: UserModel<ExtraData.User>
    
    init(
        lastReadAt: Date,
        unreadMessagesCount: Int,
        user: UserModel<ExtraData.User>
    ) {
        self.lastReadAt = lastReadAt
        self.unreadMessagesCount = unreadMessagesCount
        self.user = user
    }
}

public typealias ChannelRead = ChannelReadModel<DefaultDataTypes>
