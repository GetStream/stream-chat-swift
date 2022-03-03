//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// Coding keys channel related payloads.
public enum ChannelCodingKeys: String, CodingKey, CaseIterable {
    /// The id of the channel
    case id
    /// A combination of channel id and type.
    case cid
    /// Name for the channel.
    case name
    /// Optional image URL for the channel.
    case imageURL = "image"
    /// A type.
    case typeRawValue = "type"
    /// A last message date.
    case lastMessageAt = "last_message_at"
    /// A user created by.
    case createdBy = "created_by"
    /// A created date.
    case createdAt = "created_at"
    /// A created date.
    case updatedAt = "updated_at"
    /// A deleted date.
    case deletedAt = "deleted_at"
    /// A truncated date.
    case truncatedAt = "truncated_at"
    /// Hidden flag.
    case hidden
    /// A channel config.
    case config
    /// A frozen flag.
    case frozen
    /// Members.
    case members
    /// Invites.
    case invites
    /// The team the channel belongs to.
    case team
    case memberCount = "member_count"
    /// Cooldown duration for the channel, if it's in slow mode.
    /// This value will be 0 if the channel is not in slow mode.
    case cooldownDuration = "cooldown"
}
