//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelConfig: Codable, Hashable {
    public var automodThresholds: StreamChatThresholds?
    
    public var blocklistBehavior: String?
    
    public var blocklists: [StreamChatBlockListOptions]?
    
    public var connectEvents: Bool
    
    public var reminders: Bool
    
    public var search: Bool
    
    public var reactions: Bool
    
    public var typingEvents: Bool
    
    public var createdAt: String
    
    public var markMessagesPending: Bool
    
    public var messageRetention: String
    
    public var name: String
    
    public var pushNotifications: Bool
    
    public var quotes: Bool
    
    public var updatedAt: String
    
    public var urlEnrichment: Bool
    
    public var blocklist: String?
    
    public var commands: [String]
    
    public var maxMessageLength: Int
    
    public var replies: Bool
    
    public var automodBehavior: String
    
    public var mutes: Bool
    
    public var readEvents: Bool
    
    public var uploads: Bool
    
    public var allowedFlagReasons: [String]?
    
    public var customEvents: Bool
    
    public var automod: String
    
    public init(automodThresholds: StreamChatThresholds?, blocklistBehavior: String?, blocklists: [StreamChatBlockListOptions]?, connectEvents: Bool, reminders: Bool, search: Bool, reactions: Bool, typingEvents: Bool, createdAt: String, markMessagesPending: Bool, messageRetention: String, name: String, pushNotifications: Bool, quotes: Bool, updatedAt: String, urlEnrichment: Bool, blocklist: String?, commands: [String], maxMessageLength: Int, replies: Bool, automodBehavior: String, mutes: Bool, readEvents: Bool, uploads: Bool, allowedFlagReasons: [String]?, customEvents: Bool, automod: String) {
        self.automodThresholds = automodThresholds
        
        self.blocklistBehavior = blocklistBehavior
        
        self.blocklists = blocklists
        
        self.connectEvents = connectEvents
        
        self.reminders = reminders
        
        self.search = search
        
        self.reactions = reactions
        
        self.typingEvents = typingEvents
        
        self.createdAt = createdAt
        
        self.markMessagesPending = markMessagesPending
        
        self.messageRetention = messageRetention
        
        self.name = name
        
        self.pushNotifications = pushNotifications
        
        self.quotes = quotes
        
        self.updatedAt = updatedAt
        
        self.urlEnrichment = urlEnrichment
        
        self.blocklist = blocklist
        
        self.commands = commands
        
        self.maxMessageLength = maxMessageLength
        
        self.replies = replies
        
        self.automodBehavior = automodBehavior
        
        self.mutes = mutes
        
        self.readEvents = readEvents
        
        self.uploads = uploads
        
        self.allowedFlagReasons = allowedFlagReasons
        
        self.customEvents = customEvents
        
        self.automod = automod
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case automodThresholds = "automod_thresholds"
        
        case blocklistBehavior = "blocklist_behavior"
        
        case blocklists
        
        case connectEvents = "connect_events"
        
        case reminders
        
        case search
        
        case reactions
        
        case typingEvents = "typing_events"
        
        case createdAt = "created_at"
        
        case markMessagesPending = "mark_messages_pending"
        
        case messageRetention = "message_retention"
        
        case name
        
        case pushNotifications = "push_notifications"
        
        case quotes
        
        case updatedAt = "updated_at"
        
        case urlEnrichment = "url_enrichment"
        
        case blocklist
        
        case commands
        
        case maxMessageLength = "max_message_length"
        
        case replies
        
        case automodBehavior = "automod_behavior"
        
        case mutes
        
        case readEvents = "read_events"
        
        case uploads
        
        case allowedFlagReasons = "allowed_flag_reasons"
        
        case customEvents = "custom_events"
        
        case automod
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(automodThresholds, forKey: .automodThresholds)
        
        try container.encode(blocklistBehavior, forKey: .blocklistBehavior)
        
        try container.encode(blocklists, forKey: .blocklists)
        
        try container.encode(connectEvents, forKey: .connectEvents)
        
        try container.encode(reminders, forKey: .reminders)
        
        try container.encode(search, forKey: .search)
        
        try container.encode(reactions, forKey: .reactions)
        
        try container.encode(typingEvents, forKey: .typingEvents)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(markMessagesPending, forKey: .markMessagesPending)
        
        try container.encode(messageRetention, forKey: .messageRetention)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(quotes, forKey: .quotes)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(urlEnrichment, forKey: .urlEnrichment)
        
        try container.encode(blocklist, forKey: .blocklist)
        
        try container.encode(commands, forKey: .commands)
        
        try container.encode(maxMessageLength, forKey: .maxMessageLength)
        
        try container.encode(replies, forKey: .replies)
        
        try container.encode(automodBehavior, forKey: .automodBehavior)
        
        try container.encode(mutes, forKey: .mutes)
        
        try container.encode(readEvents, forKey: .readEvents)
        
        try container.encode(uploads, forKey: .uploads)
        
        try container.encode(allowedFlagReasons, forKey: .allowedFlagReasons)
        
        try container.encode(customEvents, forKey: .customEvents)
        
        try container.encode(automod, forKey: .automod)
    }
}
