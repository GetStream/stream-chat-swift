//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
    let next: String?
}

/// An object describing the incoming message JSON payload.
final class MessagePayload: Decodable, Sendable {
    let id: String
    /// Only messages from `translate` endpoint contain `cid`
    let cid: ChannelId?
    let type: MessageType
    let user: UserPayload
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let messageTextUpdatedAt: Date?
    let text: String
    let command: String?
    let args: String?
    let parentId: String?
    let showReplyInChannel: Bool
    let quotedMessage: MessagePayload?
    let quotedMessageId: MessageId?
    let mentionedUsers: [UserPayload]
    let restrictedVisibility: [UserId]
    let threadParticipants: [UserPayload]
    let replyCount: Int
    let extraData: [String: RawJSON]

    let latestReactions: [MessageReactionPayload]
    let ownReactions: [MessageReactionPayload]
    let reactionScores: [MessageReactionType: Int]
    let reactionCounts: [MessageReactionType: Int]
    let reactionGroups: [MessageReactionType: MessageReactionGroupPayload]
    let attachments: [MessageAttachmentPayload]
    let isSilent: Bool
    let isShadowed: Bool
    let translations: [TranslationLanguage: String]?
    let originalLanguage: String?
    let moderationDetails: MessageModerationDetailsPayload? // moderation v1 payload
    let moderation: MessageModerationDetailsPayload? // moderation v2 payload

    let pinned: Bool
    let pinnedBy: UserPayload?
    let pinnedAt: Date?
    let pinExpires: Date?
    
    let poll: PollPayload?
    let draft: DraftPayload?
    let location: SharedLocationPayload?
    let reminder: ReminderPayload?

    /// Only message payload from `getMessage` endpoint contains channel data. It's a convenience workaround for having to
    /// make an extra call do get channel details.
    let channel: ChannelDetailPayload?

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: MessagePayloadsCodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        cid = try container.decodeIfPresent(ChannelId.self, forKey: .cid)
        type = try container.decode(MessageType.self, forKey: .type)
        user = try container.decode(UserPayload.self, forKey: .user)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        text = try container.decode(String.self, forKey: .text).trimmingCharacters(in: .whitespacesAndNewlines)
        isSilent = try container.decodeIfPresent(Bool.self, forKey: .isSilent) ?? false
        isShadowed = try container.decodeIfPresent(Bool.self, forKey: .shadowed) ?? false
        command = try container.decodeIfPresent(String.self, forKey: .command)
        args = try container.decodeIfPresent(String.self, forKey: .args)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        showReplyInChannel = try container.decodeIfPresent(Bool.self, forKey: .showReplyInChannel) ?? false
        quotedMessage = try container.decodeIfPresent(MessagePayload.self, forKey: .quotedMessage)
        mentionedUsers = try container.decodeArrayIgnoringFailures([UserPayload].self, forKey: .mentionedUsers)
        // backend returns `thread_participants` only if message is a thread, we are fine with to have it on all messages
        threadParticipants = try container.decodeIfPresent([UserPayload].self, forKey: .threadParticipants) ?? []
        replyCount = try container.decode(Int.self, forKey: .replyCount)
        latestReactions = try container.decodeArrayIgnoringFailures([MessageReactionPayload].self, forKey: .latestReactions)
        ownReactions = try container.decodeArrayIgnoringFailures([MessageReactionPayload].self, forKey: .ownReactions)
        restrictedVisibility = try container.decodeArrayIfPresentIgnoringFailures([UserId].self, forKey: .restrictedVisibility) ?? []

        reactionScores = try container
            .decodeIfPresent([String: Int].self, forKey: .reactionScores)?
            .mapKeys { MessageReactionType(rawValue: $0) } ?? [:]
        reactionCounts = try container
            .decodeIfPresent([String: Int].self, forKey: .reactionCounts)?
            .mapKeys { MessageReactionType(rawValue: $0) } ?? [:]
        reactionGroups = try container
            .decodeIfPresent([String: MessageReactionGroupPayload].self, forKey: .reactionGroups)?
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
        let i18n = try container.decodeIfPresent(MessageTranslationsPayload.self, forKey: .i18n)
        translations = i18n?.translated
        originalLanguage = i18n?.originalLanguage
        moderation = try container.decodeIfPresent(MessageModerationDetailsPayload.self, forKey: .moderation)
        moderationDetails = try container.decodeIfPresent(MessageModerationDetailsPayload.self, forKey: .moderationDetails)
        messageTextUpdatedAt = try container.decodeIfPresent(Date.self, forKey: .messageTextUpdatedAt)
        poll = try container.decodeIfPresent(PollPayload.self, forKey: .poll)
        draft = try container.decodeIfPresent(DraftPayload.self, forKey: .draft)
        location = try container.decodeIfPresent(SharedLocationPayload.self, forKey: .location)
        reminder = try container.decodeIfPresent(ReminderPayload.self, forKey: .reminder)
    }

    init(
        id: String,
        cid: ChannelId? = nil,
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
        restrictedVisibility: [UserId] = [],
        extraData: [String: RawJSON],
        latestReactions: [MessageReactionPayload] = [],
        ownReactions: [MessageReactionPayload] = [],
        reactionScores: [MessageReactionType: Int],
        reactionCounts: [MessageReactionType: Int],
        reactionGroups: [MessageReactionType: MessageReactionGroupPayload] = [:],
        isSilent: Bool,
        isShadowed: Bool,
        attachments: [MessageAttachmentPayload],
        channel: ChannelDetailPayload? = nil,
        pinned: Bool = false,
        pinnedBy: UserPayload? = nil,
        pinnedAt: Date? = nil,
        pinExpires: Date? = nil,
        translations: [TranslationLanguage: String]? = nil,
        originalLanguage: String? = nil,
        moderation: MessageModerationDetailsPayload? = nil,
        moderationDetails: MessageModerationDetailsPayload? = nil,
        messageTextUpdatedAt: Date? = nil,
        poll: PollPayload? = nil,
        draft: DraftPayload? = nil,
        reminder: ReminderPayload? = nil,
        location: SharedLocationPayload? = nil
    ) {
        self.id = id
        self.cid = cid
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
        self.restrictedVisibility = restrictedVisibility
        self.extraData = extraData
        self.latestReactions = latestReactions
        self.ownReactions = ownReactions
        self.reactionScores = reactionScores
        self.reactionCounts = reactionCounts
        self.reactionGroups = reactionGroups
        self.isSilent = isSilent
        self.isShadowed = isShadowed
        self.attachments = attachments
        self.channel = channel
        self.pinned = pinned
        self.pinnedBy = pinnedBy
        self.pinnedAt = pinnedAt
        self.pinExpires = pinExpires
        self.quotedMessageId = quotedMessageId
        self.translations = translations
        self.originalLanguage = originalLanguage
        self.moderation = moderation
        self.moderationDetails = moderationDetails
        self.messageTextUpdatedAt = messageTextUpdatedAt
        self.poll = poll
        self.draft = draft
        self.location = location
        self.reminder = reminder
    }
}

/// An object describing the outgoing message JSON payload.
struct MessageRequestBody: Encodable, Sendable {
    let id: String
    let user: UserRequestBody
    let text: String

    // Used at the moment only for creating a system a message.
    let type: String?

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
    var pollId: String?
    var location: NewLocationRequestPayload?
    var restrictedVisibility: [UserId]?
    let extraData: [String: RawJSON]

    init(
        id: String,
        user: UserRequestBody,
        text: String,
        type: String? = nil,
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
        pollId: String? = nil,
        restrictedVisibility: [UserId]? = nil,
        location: NewLocationRequestPayload? = nil,
        extraData: [String: RawJSON]
    ) {
        self.id = id
        self.user = user
        self.text = text
        self.type = type
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
        self.pollId = pollId
        self.restrictedVisibility = restrictedVisibility
        self.location = location
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
        try container.encodeIfPresent(pollId, forKey: .pollId)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(restrictedVisibility, forKey: .restrictedVisibility)
        try container.encodeIfPresent(location, forKey: .location)

        if !attachments.isEmpty {
            try container.encode(attachments, forKey: .attachments)
        }

        if !mentionedUserIds.isEmpty {
            try container.encode(mentionedUserIds, forKey: .mentionedUsers)
        }

        try extraData.encode(to: encoder)
    }
}

/// An object describing pinned messages JSON payload.
typealias PinnedMessagesPayload = MessageListPayload

/// An object describing the message list JSON payload.
typealias MessageRepliesPayload = MessageListPayload

struct MessageListPayload: Decodable {
    let messages: [MessagePayload]
}

struct MessageReactionsPayload: Decodable {
    let reactions: [MessageReactionPayload]
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
