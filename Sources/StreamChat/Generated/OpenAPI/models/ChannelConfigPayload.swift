//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelConfigPayload: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum ChannelConfigBlocklistBehavior: String, Sendable, Codable, CaseIterable {
        case block
        case flag
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    enum ChannelConfigPushLevel: String, Sendable, Codable, CaseIterable {
        case all
        case allMentions = "all_mentions"
        case directMentions = "direct_mentions"
        case mentions
        case none
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }

    var blocklist: String?
    var blocklistBehavior: ChannelConfigBlocklistBehavior?
    var chatPreferences: ChatPreferences?
    /// List of commands that channel supports
    var commands: [String]?
    /// Enable/disable message counting
    var countMessages: Bool?
    var grants: [String: [String]]?
    /// Overrides max message length
    var maxMessageLength: Int?
    /// Overrides the push notification level for this channel
    var pushLevel: ChannelConfigPushLevel?
    /// Enables message quotes
    var quotes: Bool?
    /// Enables or disables reactions
    var reactions: Bool?
    /// Enables message replies (threads)
    var replies: Bool?
    /// Enable/disable shared locations
    var sharedLocations: Bool?
    /// Enables or disables typing events
    var typingEvents: Bool?
    /// Enables or disables file uploads
    var uploads: Bool?
    /// Enables or disables URL enrichment
    var urlEnrichment: Bool?
    /// Enable/disable user message reminders
    var userMessageReminders: Bool?

    init(blocklist: String? = nil, blocklistBehavior: ChannelConfigBlocklistBehavior? = nil, chatPreferences: ChatPreferences? = nil, commands: [String]? = nil, countMessages: Bool? = nil, grants: [String: [String]]? = nil, maxMessageLength: Int? = nil, pushLevel: ChannelConfigPushLevel? = nil, quotes: Bool? = nil, reactions: Bool? = nil, replies: Bool? = nil, sharedLocations: Bool? = nil, typingEvents: Bool? = nil, uploads: Bool? = nil, urlEnrichment: Bool? = nil, userMessageReminders: Bool? = nil) {
        self.blocklist = blocklist
        self.blocklistBehavior = blocklistBehavior
        self.chatPreferences = chatPreferences
        self.commands = commands
        self.countMessages = countMessages
        self.grants = grants
        self.maxMessageLength = maxMessageLength
        self.pushLevel = pushLevel
        self.quotes = quotes
        self.reactions = reactions
        self.replies = replies
        self.sharedLocations = sharedLocations
        self.typingEvents = typingEvents
        self.uploads = uploads
        self.urlEnrichment = urlEnrichment
        self.userMessageReminders = userMessageReminders
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case blocklist
        case blocklistBehavior = "blocklist_behavior"
        case chatPreferences = "chat_preferences"
        case commands
        case countMessages = "count_messages"
        case grants
        case maxMessageLength = "max_message_length"
        case pushLevel = "push_level"
        case quotes
        case reactions
        case replies
        case sharedLocations = "shared_locations"
        case typingEvents = "typing_events"
        case uploads
        case urlEnrichment = "url_enrichment"
        case userMessageReminders = "user_message_reminders"
    }

    static func == (lhs: ChannelConfigPayload, rhs: ChannelConfigPayload) -> Bool {
        lhs.blocklist == rhs.blocklist &&
            lhs.blocklistBehavior == rhs.blocklistBehavior &&
            lhs.chatPreferences == rhs.chatPreferences &&
            lhs.commands == rhs.commands &&
            lhs.countMessages == rhs.countMessages &&
            lhs.grants == rhs.grants &&
            lhs.maxMessageLength == rhs.maxMessageLength &&
            lhs.pushLevel == rhs.pushLevel &&
            lhs.quotes == rhs.quotes &&
            lhs.reactions == rhs.reactions &&
            lhs.replies == rhs.replies &&
            lhs.sharedLocations == rhs.sharedLocations &&
            lhs.typingEvents == rhs.typingEvents &&
            lhs.uploads == rhs.uploads &&
            lhs.urlEnrichment == rhs.urlEnrichment &&
            lhs.userMessageReminders == rhs.userMessageReminders
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(blocklist)
        hasher.combine(blocklistBehavior)
        hasher.combine(chatPreferences)
        hasher.combine(commands)
        hasher.combine(countMessages)
        hasher.combine(grants)
        hasher.combine(maxMessageLength)
        hasher.combine(pushLevel)
        hasher.combine(quotes)
        hasher.combine(reactions)
        hasher.combine(replies)
        hasher.combine(sharedLocations)
        hasher.combine(typingEvents)
        hasher.combine(uploads)
        hasher.combine(urlEnrichment)
        hasher.combine(userMessageReminders)
    }
}
