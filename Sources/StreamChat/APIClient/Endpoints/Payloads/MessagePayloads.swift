//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Coding keys for message-related JSON payloads
enum MessagePayloadsCodingKeys: String, CodingKey, CaseIterable {
    case id
    case cid
    case channelId = "channel_cid"
    case type
    case user
    case userId = "user_id"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case deletedAt = "deleted_at"
    case text
    case command
    case args
    case attachments
    case parentId = "parent_id"
    case showReplyInChannel = "show_in_channel"
    case quotedMessageId = "quoted_message_id"
    case quotedMessage = "quoted_message"
    case parentMessage = "parent_message"
    case mentionedUsers = "mentioned_users"
    case mentionedChannelMembers = "mentioned_channel_members"
    case mentionedHere = "mentioned_here"
    case mentionedChannel = "mentioned_channel"
    case mentionedGroupIds = "mentioned_group_ids"
    case mentionedGroups = "mentioned_groups"
    case mentionedRoles = "mentioned_roles"
    case threadParticipants = "thread_participants"
    case replyCount = "reply_count"
    case latestReactions = "latest_reactions"
    case ownReactions = "own_reactions"
    case reactionScores = "reaction_scores"
    case reactionCounts = "reaction_counts"
    case reactionGroups = "reaction_groups"
    case isSilent = "silent"
    case channel
    case pinned
    case pinnedBy = "pinned_by"
    case pinnedAt = "pinned_at"
    case pinExpires = "pin_expires"
    case html
    case i18n
    case mml
    case imageLabels = "image_labels"
    case shadowed
    case moderationDetails = "moderation_details" // moderation v1 key
    case moderation // moderation v2 key
    case messageTextUpdatedAt = "message_text_updated_at"
    case message
    case poll
    case pollId = "poll_id"
    case set
    case unset
    case skipEnrichUrl = "skip_enrich_url"
    case restrictedVisibility = "restricted_visibility"
    case draft
    case location = "shared_location"
    case reminder
    case member
    case deletedForMe = "deleted_for_me"
}

extension MessageResponse {
    /// A object describing the incoming JSON format for message payload. Unfortunately, our backend is not consistent
    /// in this and the payload has the form: `{ "message": <message payload> }` rather than `{ <message payload> }`
    ///
    /// Replaced by the generated response types when the message CRUD/action endpoints move to v2 (IOS-1835).
    final class Boxed: Sendable, Decodable {
        let message: MessageResponse

        init(message: MessageResponse) {
            self.message = message
        }
    }
}

struct MessageListPayload: Decodable {
    let messages: [MessageResponse]
}

/// A command in a message, e.g. /giphy.
public struct Command: Codable, Hashable, Sendable {
    /// A command name.
    public let name: String
    /// A description.
    public let description: String
    public let set: String
    /// Args for the command.
    public let args: String

    public init(name: String = "", description: String = "", set: String = "", args: String = "") {
        self.name = name
        self.description = description
        self.set = set
        self.args = args
    }
}
