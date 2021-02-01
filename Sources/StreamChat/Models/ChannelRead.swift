//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a user's last read action on a channel.
///
/// - Note: `ChatChannelRead` is a typealias of `_ChatChannelRead` with default extra data. If you're using custom extra data,
/// create your own typealias of `ChatChannelRead`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias ChatChannelRead = _ChatChannelRead<NoExtraData>

/// A type representing a user's last read action on a channel.
///
/// - Note: `_ChatChannelRead` type is not meant to be used directly. If you're using default extra data, use `ChatChannelRead`
/// typealias instead. If you're using custom extra data, create your own typealias of `ChatChannelRead`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public struct _ChatChannelRead<ExtraData: ExtraDataTypes> {
    /// The last time the user has read the channel.
    public let lastReadAt: Date
    
    /// Number of unread messages the user has in this channel.
    public let unreadMessagesCount: Int
    
    /// The user who read the channel.
    public let user: _ChatUser<ExtraData.User>
    
    init(
        lastReadAt: Date,
        unreadMessagesCount: Int,
        user: _ChatUser<ExtraData.User>
    ) {
        self.lastReadAt = lastReadAt
        self.unreadMessagesCount = unreadMessagesCount
        self.user = user
    }
}
