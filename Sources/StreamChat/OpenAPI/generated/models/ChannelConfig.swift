//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelConfig: Codable, Hashable {
    public var automod: String
    public var automodBehavior: String
    public var connectEvents: Bool
    public var createdAt: Date
    public var customEvents: Bool
    public var markMessagesPending: Bool
    public var maxMessageLength: Int
    public var mutes: Bool
    public var name: String
    public var pushNotifications: Bool
    public var quotes: Bool
    public var reactions: Bool
    public var readEvents: Bool
    public var reminders: Bool
    public var replies: Bool
    public var search: Bool
    public var typingEvents: Bool
    public var updatedAt: Date
    public var uploads: Bool
    public var urlEnrichment: Bool
    public var commands: [String]
    public var blocklist: String? = nil
    public var blocklistBehavior: String? = nil
    public var allowedFlagReasons: [String]? = nil
    public var blocklists: [BlockListOptions]? = nil
    public var automodThresholds: Thresholds? = nil

    public init(automod: String, automodBehavior: String, connectEvents: Bool, createdAt: Date, customEvents: Bool, markMessagesPending: Bool, maxMessageLength: Int, mutes: Bool, name: String, pushNotifications: Bool, quotes: Bool, reactions: Bool, readEvents: Bool, reminders: Bool, replies: Bool, search: Bool, typingEvents: Bool, updatedAt: Date, uploads: Bool, urlEnrichment: Bool, commands: [String], blocklist: String? = nil, blocklistBehavior: String? = nil, allowedFlagReasons: [String]? = nil, blocklists: [BlockListOptions]? = nil, automodThresholds: Thresholds? = nil) {
        self.automod = automod
        self.automodBehavior = automodBehavior
        self.connectEvents = connectEvents
        self.createdAt = createdAt
        self.customEvents = customEvents
        self.markMessagesPending = markMessagesPending
        self.maxMessageLength = maxMessageLength
        self.mutes = mutes
        self.name = name
        self.pushNotifications = pushNotifications
        self.quotes = quotes
        self.reactions = reactions
        self.readEvents = readEvents
        self.reminders = reminders
        self.replies = replies
        self.search = search
        self.typingEvents = typingEvents
        self.updatedAt = updatedAt
        self.uploads = uploads
        self.urlEnrichment = urlEnrichment
        self.commands = commands
        self.blocklist = blocklist
        self.blocklistBehavior = blocklistBehavior
        self.allowedFlagReasons = allowedFlagReasons
        self.blocklists = blocklists
        self.automodThresholds = automodThresholds
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case automod
        case automodBehavior = "automod_behavior"
        case connectEvents = "connect_events"
        case createdAt = "created_at"
        case customEvents = "custom_events"
        case markMessagesPending = "mark_messages_pending"
        case maxMessageLength = "max_message_length"
        case mutes
        case name
        case pushNotifications = "push_notifications"
        case quotes
        case reactions
        case readEvents = "read_events"
        case reminders
        case replies
        case search
        case typingEvents = "typing_events"
        case updatedAt = "updated_at"
        case uploads
        case urlEnrichment = "url_enrichment"
        case commands
        case blocklist
        case blocklistBehavior = "blocklist_behavior"
        case allowedFlagReasons = "allowed_flag_reasons"
        case blocklists
        case automodThresholds = "automod_thresholds"
    }
}
