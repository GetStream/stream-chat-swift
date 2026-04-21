//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelConfigWithInfo: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum ChannelConfigWithInfoAutomod: String, Sendable, Codable, CaseIterable {
        case aI = "AI"
        case disabled
        case simple
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
    
    enum ChannelConfigWithInfoAutomodBehavior: String, Sendable, Codable, CaseIterable {
        case block
        case flag
        case shadowBlock = "shadow_block"
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
    
    enum ChannelConfigWithInfoBlocklistBehavior: String, Sendable, Codable, CaseIterable {
        case block
        case flag
        case shadowBlock = "shadow_block"
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
    
    enum ChannelConfigWithInfoPushLevel: String, Sendable, Codable, CaseIterable {
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

    var allowedFlagReasons: [String]?
    var automod: ChannelConfigWithInfoAutomod
    var automodBehavior: ChannelConfigWithInfoAutomodBehavior
    var automodThresholds: Thresholds?
    var blocklist: String?
    var blocklistBehavior: ChannelConfigWithInfoBlocklistBehavior?
    var blocklists: [BlockListOptions]?
    var chatPreferences: ChatPreferences?
    var commands: [Command]
    var connectEvents: Bool
    var countMessages: Bool
    var createdAt: Date
    var customEvents: Bool
    var deliveryEvents: Bool
    var grants: [String: [String]]?
    var markMessagesPending: Bool
    var maxMessageLength: Int
    var mutes: Bool
    var name: String
    var partitionSize: Int?
    var partitionTtl: String?
    var polls: Bool
    var pushLevel: ChannelConfigWithInfoPushLevel?
    var pushNotifications: Bool
    var quotes: Bool
    var reactions: Bool
    var readEvents: Bool
    var reminders: Bool
    var replies: Bool
    var search: Bool
    var sharedLocations: Bool
    var skipLastMsgUpdateForSystemMsgs: Bool
    var typingEvents: Bool
    var updatedAt: Date
    var uploads: Bool
    var urlEnrichment: Bool
    var userMessageReminders: Bool

    init(allowedFlagReasons: [String]? = nil, automod: ChannelConfigWithInfoAutomod, automodBehavior: ChannelConfigWithInfoAutomodBehavior, automodThresholds: Thresholds? = nil, blocklist: String? = nil, blocklistBehavior: ChannelConfigWithInfoBlocklistBehavior? = nil, blocklists: [BlockListOptions]? = nil, chatPreferences: ChatPreferences? = nil, commands: [Command], connectEvents: Bool, countMessages: Bool, createdAt: Date, customEvents: Bool, deliveryEvents: Bool, grants: [String: [String]]? = nil, markMessagesPending: Bool, maxMessageLength: Int, mutes: Bool, name: String, partitionSize: Int? = nil, partitionTtl: String? = nil, polls: Bool, pushLevel: ChannelConfigWithInfoPushLevel? = nil, pushNotifications: Bool, quotes: Bool, reactions: Bool, readEvents: Bool, reminders: Bool, replies: Bool, search: Bool, sharedLocations: Bool, skipLastMsgUpdateForSystemMsgs: Bool, typingEvents: Bool, updatedAt: Date, uploads: Bool, urlEnrichment: Bool, userMessageReminders: Bool) {
        self.allowedFlagReasons = allowedFlagReasons
        self.automod = automod
        self.automodBehavior = automodBehavior
        self.automodThresholds = automodThresholds
        self.blocklist = blocklist
        self.blocklistBehavior = blocklistBehavior
        self.blocklists = blocklists
        self.chatPreferences = chatPreferences
        self.commands = commands
        self.connectEvents = connectEvents
        self.countMessages = countMessages
        self.createdAt = createdAt
        self.customEvents = customEvents
        self.deliveryEvents = deliveryEvents
        self.grants = grants
        self.markMessagesPending = markMessagesPending
        self.maxMessageLength = maxMessageLength
        self.mutes = mutes
        self.name = name
        self.partitionSize = partitionSize
        self.partitionTtl = partitionTtl
        self.polls = polls
        self.pushLevel = pushLevel
        self.pushNotifications = pushNotifications
        self.quotes = quotes
        self.reactions = reactions
        self.readEvents = readEvents
        self.reminders = reminders
        self.replies = replies
        self.search = search
        self.sharedLocations = sharedLocations
        self.skipLastMsgUpdateForSystemMsgs = skipLastMsgUpdateForSystemMsgs
        self.typingEvents = typingEvents
        self.updatedAt = updatedAt
        self.uploads = uploads
        self.urlEnrichment = urlEnrichment
        self.userMessageReminders = userMessageReminders
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case allowedFlagReasons = "allowed_flag_reasons"
        case automod
        case automodBehavior = "automod_behavior"
        case automodThresholds = "automod_thresholds"
        case blocklist
        case blocklistBehavior = "blocklist_behavior"
        case blocklists
        case chatPreferences = "chat_preferences"
        case commands
        case connectEvents = "connect_events"
        case countMessages = "count_messages"
        case createdAt = "created_at"
        case customEvents = "custom_events"
        case deliveryEvents = "delivery_events"
        case grants
        case markMessagesPending = "mark_messages_pending"
        case maxMessageLength = "max_message_length"
        case mutes
        case name
        case partitionSize = "partition_size"
        case partitionTtl = "partition_ttl"
        case polls
        case pushLevel = "push_level"
        case pushNotifications = "push_notifications"
        case quotes
        case reactions
        case readEvents = "read_events"
        case reminders
        case replies
        case search
        case sharedLocations = "shared_locations"
        case skipLastMsgUpdateForSystemMsgs = "skip_last_msg_update_for_system_msgs"
        case typingEvents = "typing_events"
        case updatedAt = "updated_at"
        case uploads
        case urlEnrichment = "url_enrichment"
        case userMessageReminders = "user_message_reminders"
    }

    static func == (lhs: ChannelConfigWithInfo, rhs: ChannelConfigWithInfo) -> Bool {
        lhs.allowedFlagReasons == rhs.allowedFlagReasons &&
            lhs.automod == rhs.automod &&
            lhs.automodBehavior == rhs.automodBehavior &&
            lhs.automodThresholds == rhs.automodThresholds &&
            lhs.blocklist == rhs.blocklist &&
            lhs.blocklistBehavior == rhs.blocklistBehavior &&
            lhs.blocklists == rhs.blocklists &&
            lhs.chatPreferences == rhs.chatPreferences &&
            lhs.commands == rhs.commands &&
            lhs.connectEvents == rhs.connectEvents &&
            lhs.countMessages == rhs.countMessages &&
            lhs.createdAt == rhs.createdAt &&
            lhs.customEvents == rhs.customEvents &&
            lhs.deliveryEvents == rhs.deliveryEvents &&
            lhs.grants == rhs.grants &&
            lhs.markMessagesPending == rhs.markMessagesPending &&
            lhs.maxMessageLength == rhs.maxMessageLength &&
            lhs.mutes == rhs.mutes &&
            lhs.name == rhs.name &&
            lhs.partitionSize == rhs.partitionSize &&
            lhs.partitionTtl == rhs.partitionTtl &&
            lhs.polls == rhs.polls &&
            lhs.pushLevel == rhs.pushLevel &&
            lhs.pushNotifications == rhs.pushNotifications &&
            lhs.quotes == rhs.quotes &&
            lhs.reactions == rhs.reactions &&
            lhs.readEvents == rhs.readEvents &&
            lhs.reminders == rhs.reminders &&
            lhs.replies == rhs.replies &&
            lhs.search == rhs.search &&
            lhs.sharedLocations == rhs.sharedLocations &&
            lhs.skipLastMsgUpdateForSystemMsgs == rhs.skipLastMsgUpdateForSystemMsgs &&
            lhs.typingEvents == rhs.typingEvents &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.uploads == rhs.uploads &&
            lhs.urlEnrichment == rhs.urlEnrichment &&
            lhs.userMessageReminders == rhs.userMessageReminders
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(allowedFlagReasons)
        hasher.combine(automod)
        hasher.combine(automodBehavior)
        hasher.combine(automodThresholds)
        hasher.combine(blocklist)
        hasher.combine(blocklistBehavior)
        hasher.combine(blocklists)
        hasher.combine(chatPreferences)
        hasher.combine(commands)
        hasher.combine(connectEvents)
        hasher.combine(countMessages)
        hasher.combine(createdAt)
        hasher.combine(customEvents)
        hasher.combine(deliveryEvents)
        hasher.combine(grants)
        hasher.combine(markMessagesPending)
        hasher.combine(maxMessageLength)
        hasher.combine(mutes)
        hasher.combine(name)
        hasher.combine(partitionSize)
        hasher.combine(partitionTtl)
        hasher.combine(polls)
        hasher.combine(pushLevel)
        hasher.combine(pushNotifications)
        hasher.combine(quotes)
        hasher.combine(reactions)
        hasher.combine(readEvents)
        hasher.combine(reminders)
        hasher.combine(replies)
        hasher.combine(search)
        hasher.combine(sharedLocations)
        hasher.combine(skipLastMsgUpdateForSystemMsgs)
        hasher.combine(typingEvents)
        hasher.combine(updatedAt)
        hasher.combine(uploads)
        hasher.combine(urlEnrichment)
        hasher.combine(userMessageReminders)
    }
}
