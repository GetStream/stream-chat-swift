//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// Coding keys for message-related JSON payloads
enum MessagePayloadsCodingKeys: String, CodingKey, CaseIterable {
    case id
    case type
    case user
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
    case mentionedUsers = "mentioned_users"
    case threadParticipants = "thread_participants"
    case replyCount = "reply_count"
    case latestReactions = "latest_reactions"
    case ownReactions = "own_reactions"
    case reactionScores = "reaction_scores"
    case reactionCounts = "reaction_counts"
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
}

extension MessagePayload {
    /// A object describing the incoming JSON format for message payload. Unfortunately, our backend is not consistent
    /// in this and the payload has the form: `{ "message": <message payload> }` rather than `{ <message payload> }`
    struct Boxed: Decodable {
        let message: MessagePayload
    }
}

struct MessageSearchResultsPayload: Decodable {
    let results: [MessagePayload.Boxed]
}

/// An object describing the incoming message JSON payload.
class MessagePayload: Decodable {
    let id: String
    let type: MessageType
    let user: UserPayload
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let text: String
    let command: String?
    let args: String?
    let parentId: String?
    let showReplyInChannel: Bool
    let quotedMessage: MessagePayload?
    let quotedMessageId: MessageId?
    let mentionedUsers: [UserPayload]
    let threadParticipants: [UserPayload]
    let replyCount: Int
    let extraData: [String: RawJSON]

    let latestReactions: [MessageReactionPayload]
    let ownReactions: [MessageReactionPayload]
    let reactionScores: [MessageReactionType: Int]
    let reactionCounts: [MessageReactionType: Int]
    let attachments: [MessageAttachmentPayload]
    let isSilent: Bool

    var pinned: Bool
    var pinnedBy: UserPayload?
    var pinnedAt: Date?
    var pinExpires: Date?

    /// Only message payload from `getMessage` endpoint contains channel data. It's a convenience workaround for having to
    /// make an extra call do get channel details.
    let channel: ChannelDetailPayload?
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: MessagePayloadsCodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(MessageType.self, forKey: .type)
        user = try container.decode(UserPayload.self, forKey: .user)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        text = try container.decode(String.self, forKey: .text).trimmingCharacters(in: .whitespacesAndNewlines)
        isSilent = try container.decodeIfPresent(Bool.self, forKey: .isSilent) ?? false
        command = try container.decodeIfPresent(String.self, forKey: .command)
        args = try container.decodeIfPresent(String.self, forKey: .args)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        showReplyInChannel = try container.decodeIfPresent(Bool.self, forKey: .showReplyInChannel) ?? false
        quotedMessage = try container.decodeIfPresent(MessagePayload.self, forKey: .quotedMessage)
        mentionedUsers = try container.decode([UserPayload].self, forKey: .mentionedUsers)
        // backend returns `thread_participants` only if message is a thread, we are fine with to have it on all messages
        threadParticipants = try container.decodeIfPresent([UserPayload].self, forKey: .threadParticipants) ?? []
        replyCount = try container.decode(Int.self, forKey: .replyCount)
        latestReactions = try container.decode([MessageReactionPayload].self, forKey: .latestReactions)
        ownReactions = try container.decode([MessageReactionPayload].self, forKey: .ownReactions)

        reactionScores = try container
            .decodeIfPresent([String: Int].self, forKey: .reactionScores)?
            .mapKeys { MessageReactionType(rawValue: $0) } ?? [:]

        reactionCounts = try container
            .decodeIfPresent([String: Int].self, forKey: .reactionCounts)?
            .mapKeys { MessageReactionType(rawValue: $0) } ?? [:]

        // Because attachment objects can be malformed, we wrap those into `OptionalDecodable`
        // and if decoding of those fail, it assignes `nil` instead of throwing whole MessagePayload away.
        attachments = try container.decode([OptionalDecodable].self, forKey: .attachments)
            .compactMap(\.base)

        if var payload = try? [String: RawJSON](from: decoder) {
            payload.removeValues(forKeys: MessagePayloadsCodingKeys.allCases.map(\.rawValue))
            extraData = payload
        } else {
            extraData = [:]
        }

        // Some endpoints return also channel payload data for convenience
        channel = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        pinned = try container.decodeIfPresent(Bool.self, forKey: .pinned) ?? false
        pinnedBy = try container.decodeIfPresent(UserPayload.self, forKey: .pinnedBy)
        pinnedAt = try container.decodeIfPresent(Date.self, forKey: .pinnedAt)
        pinExpires = try container.decodeIfPresent(Date.self, forKey: .pinExpires)
        quotedMessageId = try container.decodeIfPresent(MessageId.self, forKey: .quotedMessageId)
    }
    
    init(
        id: String,
        type: MessageType,
        user: UserPayload,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        text: String,
        command: String? = nil,
        args: String? = nil,
        parentId: String? = nil,
        showReplyInChannel: Bool,
        quotedMessageId: String? = nil,
        quotedMessage: MessagePayload? = nil,
        mentionedUsers: [UserPayload],
        threadParticipants: [UserPayload] = [],
        replyCount: Int,
        extraData: [String: RawJSON],
        latestReactions: [MessageReactionPayload] = [],
        ownReactions: [MessageReactionPayload] = [],
        reactionScores: [MessageReactionType: Int],
        reactionCounts: [MessageReactionType: Int],
        isSilent: Bool,
        attachments: [MessageAttachmentPayload],
        channel: ChannelDetailPayload? = nil,
        pinned: Bool = false,
        pinnedBy: UserPayload? = nil,
        pinnedAt: Date? = nil,
        pinExpires: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.user = user
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.text = text
        self.command = command
        self.args = args
        self.parentId = parentId
        self.showReplyInChannel = showReplyInChannel
        self.quotedMessage = quotedMessage
        self.mentionedUsers = mentionedUsers
        self.threadParticipants = threadParticipants
        self.replyCount = replyCount
        self.extraData = extraData
        self.latestReactions = latestReactions
        self.ownReactions = ownReactions
        self.reactionScores = reactionScores
        self.reactionCounts = reactionCounts
        self.isSilent = isSilent
        self.attachments = attachments
        self.channel = channel
        self.pinned = pinned
        self.pinnedBy = pinnedBy
        self.pinnedAt = pinnedAt
        self.pinExpires = pinExpires
        self.quotedMessageId = quotedMessageId
    }
}

/// An object describing the outgoing message JSON payload.
struct MessageRequestBody: Encodable {
    let id: String
    let user: UserRequestBody
    let text: String
    let command: String?
    let args: String?
    let parentId: String?
    let showReplyInChannel: Bool
    let isSilent: Bool
    let quotedMessageId: String?
    let attachments: [MessageAttachmentPayload]
    let mentionedUserIds: [UserId]
    var pinned: Bool
    var pinExpires: Date?
    let extraData: [String: RawJSON]

    init(
        id: String,
        user: UserRequestBody,
        text: String,
        command: String? = nil,
        args: String? = nil,
        parentId: String? = nil,
        showReplyInChannel: Bool = false,
        isSilent: Bool = false,
        quotedMessageId: String? = nil,
        attachments: [MessageAttachmentPayload] = [],
        mentionedUserIds: [UserId] = [],
        pinned: Bool = false,
        pinExpires: Date? = nil,
        extraData: [String: RawJSON]
    ) {
        self.id = id
        self.user = user
        self.text = text
        self.command = command
        self.args = args
        self.parentId = parentId
        self.showReplyInChannel = showReplyInChannel
        self.isSilent = isSilent
        self.quotedMessageId = quotedMessageId
        self.attachments = attachments
        self.mentionedUserIds = mentionedUserIds
        self.pinned = pinned
        self.pinExpires = pinExpires
        self.extraData = extraData
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: MessagePayloadsCodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(command, forKey: .command)
        try container.encodeIfPresent(args, forKey: .args)
        try container.encodeIfPresent(parentId, forKey: .parentId)
        try container.encodeIfPresent(showReplyInChannel, forKey: .showReplyInChannel)
        try container.encodeIfPresent(quotedMessageId, forKey: .quotedMessageId)
        try container.encode(pinned, forKey: .pinned)
        try container.encodeIfPresent(pinExpires, forKey: .pinExpires)
        try container.encode(isSilent, forKey: .isSilent)

        if !attachments.isEmpty {
            try container.encode(attachments, forKey: .attachments)
        }
        
        if !mentionedUserIds.isEmpty {
            try container.encode(mentionedUserIds, forKey: .mentionedUsers)
        }
        
        try extraData.encode(to: encoder)
    }
}

/// An object describing the message replies JSON payload.
struct MessageRepliesPayload: Decodable {
    let messages: [MessagePayload]
}

struct MessageReactionsPayload: Decodable {
    let reactions: [MessageReactionPayload]
}

// TODO: Command???

/// A command in a message, e.g. /giphy.
public struct Command: Codable, Hashable {
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
