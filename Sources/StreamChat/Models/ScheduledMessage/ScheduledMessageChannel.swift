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

    init(cid: ChannelId, name: String?, imageURL: URL?) {
        self.cid = cid
        self.name = name
        self.imageURL = imageURL
    }

    public static func == (lhs: ScheduledMessageChannel, rhs: ScheduledMessageChannel) -> Bool {
        lhs.cid == rhs.cid && lhs.name == rhs.name && lhs.imageURL == rhs.imageURL
    }
}
