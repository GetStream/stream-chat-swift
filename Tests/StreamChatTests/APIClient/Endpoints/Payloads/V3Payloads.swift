//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

struct QueryChannels_V3: Decodable {
    let entities: Entity_V3
    let channels: [ChannelPayload_V3]
    let duration: String
}

struct Entity_V3: Decodable {
    let users: [String: User_V3]
    let configs: [String: Config_V3]
    let own_capabilities: [String: [String]]
}

struct User_V3: Decodable {
    let id: String
    let role: String
    let created_at: TimeInterval
    let updated_at: TimeInterval?
    let last_active: TimeInterval?
    let banned: Bool
    let online: Bool
    let custom: [String: RawJSON]
}

struct Config_V3: Decodable {
    let created_at: TimeInterval
    let updated_at: TimeInterval?
    let name: String
    let typing_events: Bool
    let read_events: Bool
    let connect_events: Bool
    let search: Bool
    let reactions: Bool
    let replies: Bool
    let quotes: Bool
    let mutes: Bool
    let uploads: Bool
    let url_enrichment: Bool
    let custom_events: Bool
    let push_notifications: Bool
    let reminders: Bool
    let mark_messages_pending: Bool?
    let message_retention: String
    let max_message_length: Int
    let automod: String
    let automod_behavior: String
    let blocklist_behavior: String
    let commands: [[String: String]]
}

struct Channel_V3: Decodable {
    let id: String
    let type: String
    let cid: String
    let last_message_at: TimeInterval?
    let created_at: TimeInterval
    let updated_at: TimeInterval?
    let frozen: Bool
    let disabled: Bool
    let member_count: Int
    let config: String
    let own_capabilities: String
    let hidden: Bool
    let custom: [String: RawJSON]
}

struct Message_V3: Decodable {
    let id: String
    let text: String
    let html: String
    let type: String
    let attachments: [MessageAttachmentPayload]
    let latest_reactions: [Reaction_V3]
    let own_reactions: [Reaction_V3]
    let reaction_counts: [String: Int]
    let reaction_scores: [String: Int]
    let reply_count: Int
    let deleted_reply_count: Int?
    let created_at: TimeInterval
    let updated_at: TimeInterval?
    let shadowed: Bool
    let mentioned_users: [String]
    let silent: Bool
    let pinned: Bool
    let pinned_at: TimeInterval?
    let pinned_by: String?
    let pin_expires: TimeInterval?
}

struct Read_V3: Decodable {
    let user_id: String
    let last_read: TimeInterval
    let unread_messages: Int
}

struct Member_V3: Decodable {
    let user_id: String
    let status: String?
    let created_at: TimeInterval
    let updated_at: TimeInterval?
    let banned: Bool
    let shadow_banned: Bool
    let role: String
    let channel_role: String
    let notifications_muted: Bool?
}

struct ChannelPayload_V3: Decodable {
    let channel: Channel_V3
    let messages: [Message_V3]
    let pinned_messages: [Message_V3]
    let watcher_count: Int
    let read: [Read_V3]
    let members: [Member_V3]
    let membership: Membership_V3?
}

struct Membership_V3: Decodable {
    let created_at: TimeInterval
    let updated_at: TimeInterval?
    let banned: Bool
    let shadow_banned: Bool
    let channel_role: String
}

struct Reaction_V3: Decodable, Hashable {
    let user_id: String
    let type: String
    let score: Int
    let created_at: TimeInterval
    let updated_at: TimeInterval?
}
