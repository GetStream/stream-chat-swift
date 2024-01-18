//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelConfig: Codable, Hashable {
    public var allowedFlagReasons: [String]?
    
    public var connectEvents: Bool
    
    public var maxMessageLength: Int
    
    public var reactions: Bool
    
    public var readEvents: Bool
    
    public var uploads: Bool
    
    public var updatedAt: Date
    
    public var automodThresholds: StreamChatThresholds?
    
    public var commands: [String]
    
    public var search: Bool
    
    public var typingEvents: Bool
    
    public var automodBehavior: String
    
    public var blocklist: String?
    
    public var blocklists: [StreamChatBlockListOptions]?
    
    public var name: String
    
    public var quotes: Bool
    
    public var urlEnrichment: Bool
    
    public var blocklistBehavior: String?
    
    public var messageRetention: String
    
    public var pushNotifications: Bool
    
    public var reminders: Bool
    
    public var automod: String
    
    public var createdAt: Date
    
    public var customEvents: Bool
    
    public var mutes: Bool
    
    public var replies: Bool
    
    public var markMessagesPending: Bool
    
    public init(allowedFlagReasons: [String]?, connectEvents: Bool, maxMessageLength: Int, reactions: Bool, readEvents: Bool, uploads: Bool, updatedAt: Date, automodThresholds: StreamChatThresholds?, commands: [String], search: Bool, typingEvents: Bool, automodBehavior: String, blocklist: String?, blocklists: [StreamChatBlockListOptions]?, name: String, quotes: Bool, urlEnrichment: Bool, blocklistBehavior: String?, messageRetention: String, pushNotifications: Bool, reminders: Bool, automod: String, createdAt: Date, customEvents: Bool, mutes: Bool, replies: Bool, markMessagesPending: Bool) {
        self.allowedFlagReasons = allowedFlagReasons
        
        self.connectEvents = connectEvents
        
        self.maxMessageLength = maxMessageLength
        
        self.reactions = reactions
        
        self.readEvents = readEvents
        
        self.uploads = uploads
        
        self.updatedAt = updatedAt
        
        self.automodThresholds = automodThresholds
        
        self.commands = commands
        
        self.search = search
        
        self.typingEvents = typingEvents
        
        self.automodBehavior = automodBehavior
        
        self.blocklist = blocklist
        
        self.blocklists = blocklists
        
        self.name = name
        
        self.quotes = quotes
        
        self.urlEnrichment = urlEnrichment
        
        self.blocklistBehavior = blocklistBehavior
        
        self.messageRetention = messageRetention
        
        self.pushNotifications = pushNotifications
        
        self.reminders = reminders
        
        self.automod = automod
        
        self.createdAt = createdAt
        
        self.customEvents = customEvents
        
        self.mutes = mutes
        
        self.replies = replies
        
        self.markMessagesPending = markMessagesPending
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case allowedFlagReasons = "allowed_flag_reasons"
        
        case connectEvents = "connect_events"
        
        case maxMessageLength = "max_message_length"
        
        case reactions
        
        case readEvents = "read_events"
        
        case uploads
        
        case updatedAt = "updated_at"
        
        case automodThresholds = "automod_thresholds"
        
        case commands
        
        case search
        
        case typingEvents = "typing_events"
        
        case automodBehavior = "automod_behavior"
        
        case blocklist
        
        case blocklists
        
        case name
        
        case quotes
        
        case urlEnrichment = "url_enrichment"
        
        case blocklistBehavior = "blocklist_behavior"
        
        case messageRetention = "message_retention"
        
        case pushNotifications = "push_notifications"
        
        case reminders
        
        case automod
        
        case createdAt = "created_at"
        
        case customEvents = "custom_events"
        
        case mutes
        
        case replies
        
        case markMessagesPending = "mark_messages_pending"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(allowedFlagReasons, forKey: .allowedFlagReasons)
        
        try container.encode(connectEvents, forKey: .connectEvents)
        
        try container.encode(maxMessageLength, forKey: .maxMessageLength)
        
        try container.encode(reactions, forKey: .reactions)
        
        try container.encode(readEvents, forKey: .readEvents)
        
        try container.encode(uploads, forKey: .uploads)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(automodThresholds, forKey: .automodThresholds)
        
        try container.encode(commands, forKey: .commands)
        
        try container.encode(search, forKey: .search)
        
        try container.encode(typingEvents, forKey: .typingEvents)
        
        try container.encode(automodBehavior, forKey: .automodBehavior)
        
        try container.encode(blocklist, forKey: .blocklist)
        
        try container.encode(blocklists, forKey: .blocklists)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(quotes, forKey: .quotes)
        
        try container.encode(urlEnrichment, forKey: .urlEnrichment)
        
        try container.encode(blocklistBehavior, forKey: .blocklistBehavior)
        
        try container.encode(messageRetention, forKey: .messageRetention)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(reminders, forKey: .reminders)
        
        try container.encode(automod, forKey: .automod)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(customEvents, forKey: .customEvents)
        
        try container.encode(mutes, forKey: .mutes)
        
        try container.encode(replies, forKey: .replies)
        
        try container.encode(markMessagesPending, forKey: .markMessagesPending)
    }
}
