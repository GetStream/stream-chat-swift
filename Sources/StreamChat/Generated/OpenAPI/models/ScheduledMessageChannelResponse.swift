//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The channel of a scheduled message
final class ScheduledMessageChannelResponse: Sendable, Decodable {
    /// Channel CID (<type>:<id>)
    let cid: String
    /// Channel ID
    let id: String
    /// Channel image, from its custom data
    let image: String?
    /// Number of members of the channel. 0 when the channel is deleted
    let memberCount: Int
    /// Up to 4 members of the channel, oldest first. Empty when the channel is deleted
    let members: [MemberPayload]
    /// Channel name, from its custom data
    let name: String?
    /// Channel type
    let type: String

    init(
        cid: String,
        id: String,
        image: String? = nil,
        memberCount: Int,
        members: [MemberPayload],
        name: String? = nil,
        type: String
    ) {
        self.cid = cid
        self.id = id
        self.image = image
        self.memberCount = memberCount
        self.members = members
        self.name = name
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.cid = try container.decode(String.self, forKey: .cid)
        self.id = try container.decode(String.self, forKey: .id)
        self.image = try container.decodeIfPresent(String.self, forKey: .image)
        self.memberCount = try container.decode(Int.self, forKey: .memberCount)
        self.members = try container.decode([MemberPayload].self, forKey: .members)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.type = try container.decode(String.self, forKey: .type)
    }
}
