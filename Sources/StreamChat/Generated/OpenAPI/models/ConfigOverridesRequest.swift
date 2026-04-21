//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ConfigOverridesRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum ConfigOverridesRequestBlocklistBehavior: String, Sendable, Codable, CaseIterable {
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
    
    enum ConfigOverridesRequestPushLevel: String, Sendable, Codable, CaseIterable {
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

    /// Blocklist name
    var blocklist: String?
    /// Blocklist behavior. One of: flag, block
    var blocklistBehavior: ConfigOverridesRequestBlocklistBehavior?
    var chatPreferences: ChatPreferences?
    /// List of available commands
    var commands: [String]?
    /// Enable/disable message counting
    var countMessages: Bool?
    /// Permission grants modifiers
    var grants: [String: [String]]?
    /// Maximum message length
    var maxMessageLength: Int?
    var pushLevel: ConfigOverridesRequestPushLevel?
    /// Enable/disable quotes
    var quotes: Bool?
    /// Enable/disable reactions
    var reactions: Bool?
    /// Enable/disable replies
    var replies: Bool?
    /// Enable/disable shared locations
    var sharedLocations: Bool?
    /// Enable/disable typing events
    var typingEvents: Bool?
    /// Enable/disable uploads
    var uploads: Bool?
    /// Enable/disable URL enrichment
    var urlEnrichment: Bool?
    /// Enable/disable user message reminders
    var userMessageReminders: Bool?

    init(blocklist: String? = nil, blocklistBehavior: ConfigOverridesRequestBlocklistBehavior? = nil, chatPreferences: ChatPreferences? = nil, commands: [String]? = nil, countMessages: Bool? = nil, grants: [String: [String]]? = nil, maxMessageLength: Int? = nil, pushLevel: ConfigOverridesRequestPushLevel? = nil, quotes: Bool? = nil, reactions: Bool? = nil, replies: Bool? = nil, sharedLocations: Bool? = nil, typingEvents: Bool? = nil, uploads: Bool? = nil, urlEnrichment: Bool? = nil, userMessageReminders: Bool? = nil) {
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

    static func == (lhs: ConfigOverridesRequest, rhs: ConfigOverridesRequest) -> Bool {
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
