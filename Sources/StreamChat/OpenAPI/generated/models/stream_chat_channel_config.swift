//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelConfig: Codable, Hashable {
    public var automodBehavior: String
    
    public var connectEvents: Bool
    
    public var uploads: Bool
    
    public var automod: String
    
    public var messageRetention: String
    
    public var name: String
    
    public var maxMessageLength: Int
    
    public var mutes: Bool
    
    public var quotes: Bool
    
    public var reactions: Bool
    
    public var allowedFlagReasons: [String]?
    
    public var automodThresholds: StreamChatThresholds?
    
    public var readEvents: Bool
    
    public var typingEvents: Bool
    
    public var updatedAt: Date
    
    public var blocklistBehavior: String?
    
    public var commands: [String]
    
    public var markMessagesPending: Bool
    
    public var pushNotifications: Bool
    
    public var reminders: Bool
    
    public var blocklists: [StreamChatBlockListOptions]?
    
    public var createdAt: Date
    
    public var search: Bool
    
    public var urlEnrichment: Bool
    
    public var blocklist: String?
    
    public var customEvents: Bool
    
    public var replies: Bool
    
    public init(automodBehavior: String, connectEvents: Bool, uploads: Bool, automod: String, messageRetention: String, name: String, maxMessageLength: Int, mutes: Bool, quotes: Bool, reactions: Bool, allowedFlagReasons: [String]?, automodThresholds: StreamChatThresholds?, readEvents: Bool, typingEvents: Bool, updatedAt: Date, blocklistBehavior: String?, commands: [String], markMessagesPending: Bool, pushNotifications: Bool, reminders: Bool, blocklists: [StreamChatBlockListOptions]?, createdAt: Date, search: Bool, urlEnrichment: Bool, blocklist: String?, customEvents: Bool, replies: Bool) {
        self.automodBehavior = automodBehavior
        
        self.connectEvents = connectEvents
        
        self.uploads = uploads
        
        self.automod = automod
        
        self.messageRetention = messageRetention
        
        self.name = name
        
        self.maxMessageLength = maxMessageLength
        
        self.mutes = mutes
        
        self.quotes = quotes
        
        self.reactions = reactions
        
        self.allowedFlagReasons = allowedFlagReasons
        
        self.automodThresholds = automodThresholds
        
        self.readEvents = readEvents
        
        self.typingEvents = typingEvents
        
        self.updatedAt = updatedAt
        
        self.blocklistBehavior = blocklistBehavior
        
        self.commands = commands
        
        self.markMessagesPending = markMessagesPending
        
        self.pushNotifications = pushNotifications
        
        self.reminders = reminders
        
        self.blocklists = blocklists
        
        self.createdAt = createdAt
        
        self.search = search
        
        self.urlEnrichment = urlEnrichment
        
        self.blocklist = blocklist
        
        self.customEvents = customEvents
        
        self.replies = replies
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case automodBehavior = "automod_behavior"
        
        case connectEvents = "connect_events"
        
        case uploads
        
        case automod
        
        case messageRetention = "message_retention"
        
        case name
        
        case maxMessageLength = "max_message_length"
        
        case mutes
        
        case quotes
        
        case reactions
        
        case allowedFlagReasons = "allowed_flag_reasons"
        
        case automodThresholds = "automod_thresholds"
        
        case readEvents = "read_events"
        
        case typingEvents = "typing_events"
        
        case updatedAt = "updated_at"
        
        case blocklistBehavior = "blocklist_behavior"
        
        case commands
        
        case markMessagesPending = "mark_messages_pending"
        
        case pushNotifications = "push_notifications"
        
        case reminders
        
        case blocklists
        
        case createdAt = "created_at"
        
        case search
        
        case urlEnrichment = "url_enrichment"
        
        case blocklist
        
        case customEvents = "custom_events"
        
        case replies
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(automodBehavior, forKey: .automodBehavior)
        
        try container.encode(connectEvents, forKey: .connectEvents)
        
        try container.encode(uploads, forKey: .uploads)
        
        try container.encode(automod, forKey: .automod)
        
        try container.encode(messageRetention, forKey: .messageRetention)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(maxMessageLength, forKey: .maxMessageLength)
        
        try container.encode(mutes, forKey: .mutes)
        
        try container.encode(quotes, forKey: .quotes)
        
        try container.encode(reactions, forKey: .reactions)
        
        try container.encode(allowedFlagReasons, forKey: .allowedFlagReasons)
        
        try container.encode(automodThresholds, forKey: .automodThresholds)
        
        try container.encode(readEvents, forKey: .readEvents)
        
        try container.encode(typingEvents, forKey: .typingEvents)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(blocklistBehavior, forKey: .blocklistBehavior)
        
        try container.encode(commands, forKey: .commands)
        
        try container.encode(markMessagesPending, forKey: .markMessagesPending)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(reminders, forKey: .reminders)
        
        try container.encode(blocklists, forKey: .blocklists)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(search, forKey: .search)
        
        try container.encode(urlEnrichment, forKey: .urlEnrichment)
        
        try container.encode(blocklist, forKey: .blocklist)
        
        try container.encode(customEvents, forKey: .customEvents)
        
        try container.encode(replies, forKey: .replies)
    }
}
