//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelConfig: Codable, Hashable {
    public var commands: [String]
    
    public var pushNotifications: Bool
    
    public var replies: Bool
    
    public var connectEvents: Bool
    
    public var maxMessageLength: Int
    
    public var typingEvents: Bool
    
    public var reminders: Bool
    
    public var updatedAt: String
    
    public var uploads: Bool
    
    public var automodThresholds: StreamChatThresholds?
    
    public var blocklistBehavior: String?
    
    public var blocklists: [StreamChatBlockListOptions]?
    
    public var messageRetention: String
    
    public var quotes: Bool
    
    public var reactions: Bool
    
    public var blocklist: String?
    
    public var name: String
    
    public var allowedFlagReasons: [String]?
    
    public var customEvents: Bool
    
    public var markMessagesPending: Bool
    
    public var readEvents: Bool
    
    public var mutes: Bool
    
    public var search: Bool
    
    public var urlEnrichment: Bool
    
    public var automod: String
    
    public var automodBehavior: String
    
    public var createdAt: String
    
    public init(commands: [String], pushNotifications: Bool, replies: Bool, connectEvents: Bool, maxMessageLength: Int, typingEvents: Bool, reminders: Bool, updatedAt: String, uploads: Bool, automodThresholds: StreamChatThresholds?, blocklistBehavior: String?, blocklists: [StreamChatBlockListOptions]?, messageRetention: String, quotes: Bool, reactions: Bool, blocklist: String?, name: String, allowedFlagReasons: [String]?, customEvents: Bool, markMessagesPending: Bool, readEvents: Bool, mutes: Bool, search: Bool, urlEnrichment: Bool, automod: String, automodBehavior: String, createdAt: String) {
        self.commands = commands
        
        self.pushNotifications = pushNotifications
        
        self.replies = replies
        
        self.connectEvents = connectEvents
        
        self.maxMessageLength = maxMessageLength
        
        self.typingEvents = typingEvents
        
        self.reminders = reminders
        
        self.updatedAt = updatedAt
        
        self.uploads = uploads
        
        self.automodThresholds = automodThresholds
        
        self.blocklistBehavior = blocklistBehavior
        
        self.blocklists = blocklists
        
        self.messageRetention = messageRetention
        
        self.quotes = quotes
        
        self.reactions = reactions
        
        self.blocklist = blocklist
        
        self.name = name
        
        self.allowedFlagReasons = allowedFlagReasons
        
        self.customEvents = customEvents
        
        self.markMessagesPending = markMessagesPending
        
        self.readEvents = readEvents
        
        self.mutes = mutes
        
        self.search = search
        
        self.urlEnrichment = urlEnrichment
        
        self.automod = automod
        
        self.automodBehavior = automodBehavior
        
        self.createdAt = createdAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case commands
        
        case pushNotifications = "push_notifications"
        
        case replies
        
        case connectEvents = "connect_events"
        
        case maxMessageLength = "max_message_length"
        
        case typingEvents = "typing_events"
        
        case reminders
        
        case updatedAt = "updated_at"
        
        case uploads
        
        case automodThresholds = "automod_thresholds"
        
        case blocklistBehavior = "blocklist_behavior"
        
        case blocklists
        
        case messageRetention = "message_retention"
        
        case quotes
        
        case reactions
        
        case blocklist
        
        case name
        
        case allowedFlagReasons = "allowed_flag_reasons"
        
        case customEvents = "custom_events"
        
        case markMessagesPending = "mark_messages_pending"
        
        case readEvents = "read_events"
        
        case mutes
        
        case search
        
        case urlEnrichment = "url_enrichment"
        
        case automod
        
        case automodBehavior = "automod_behavior"
        
        case createdAt = "created_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(commands, forKey: .commands)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(replies, forKey: .replies)
        
        try container.encode(connectEvents, forKey: .connectEvents)
        
        try container.encode(maxMessageLength, forKey: .maxMessageLength)
        
        try container.encode(typingEvents, forKey: .typingEvents)
        
        try container.encode(reminders, forKey: .reminders)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(uploads, forKey: .uploads)
        
        try container.encode(automodThresholds, forKey: .automodThresholds)
        
        try container.encode(blocklistBehavior, forKey: .blocklistBehavior)
        
        try container.encode(blocklists, forKey: .blocklists)
        
        try container.encode(messageRetention, forKey: .messageRetention)
        
        try container.encode(quotes, forKey: .quotes)
        
        try container.encode(reactions, forKey: .reactions)
        
        try container.encode(blocklist, forKey: .blocklist)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(allowedFlagReasons, forKey: .allowedFlagReasons)
        
        try container.encode(customEvents, forKey: .customEvents)
        
        try container.encode(markMessagesPending, forKey: .markMessagesPending)
        
        try container.encode(readEvents, forKey: .readEvents)
        
        try container.encode(mutes, forKey: .mutes)
        
        try container.encode(search, forKey: .search)
        
        try container.encode(urlEnrichment, forKey: .urlEnrichment)
        
        try container.encode(automod, forKey: .automod)
        
        try container.encode(automodBehavior, forKey: .automodBehavior)
        
        try container.encode(createdAt, forKey: .createdAt)
    }
}
