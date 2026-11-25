//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A summary of the channel a scheduled message is sent to.
public final class ScheduledMessageChannel: Equatable, Sendable {
    /// The identifier of the channel.
    public let cid: ChannelId

    /// The type of the channel.
    public var type: ChannelType { cid.type }

    /// The identifier of the channel, without its type.
    public var id: String { cid.id }

    /// The name of the channel, if it has one. Channels without a name, like most direct messages, are named after their members.
    public let name: String?

    /// The image of the channel, if it has one.
    public let imageURL: URL?

    /// The number of members of the channel. It is 0 when the channel was deleted.
    public let memberCount: Int

    /// The first members of the channel, oldest first. It is empty when the channel was deleted.
    public let members: [ChatChannelMember]

    init(cid: ChannelId, name: String?, imageURL: URL?, memberCount: Int = 0, members: [ChatChannelMember] = []) {
        self.cid = cid
        self.name = name
        self.imageURL = imageURL
        self.memberCount = memberCount
        self.members = members
    }

    public static func == (lhs: ScheduledMessageChannel, rhs: ScheduledMessageChannel) -> Bool {
        lhs.cid == rhs.cid && lhs.name == rhs.name && lhs.imageURL == rhs.imageURL
            && lhs.memberCount == rhs.memberCount && lhs.members == rhs.members
    }
}
