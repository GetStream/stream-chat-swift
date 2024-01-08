//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelConfig: Codable, Hashable {
    public var typingEvents: Bool
    
    public var customEvents: Bool
    
    public var blocklistBehavior: String?
    
    public var connectEvents: Bool
    
    public var updatedAt: String
    
    public var automod: String
    
    public var blocklists: [StreamChatBlockListOptions]?
    
    public var markMessagesPending: Bool
    
    public var readEvents: Bool
    
    public var reminders: Bool
    
    public var search: Bool
    
    public var allowedFlagReasons: [String]?
    
    public var messageRetention: String
    
    public var mutes: Bool
    
    public var maxMessageLength: Int
    
    public var pushNotifications: Bool
    
    public var quotes: Bool
    
    public var automodThresholds: StreamChatThresholds?
    
    public var createdAt: String
    
    public var name: String
    
    public var automodBehavior: String
    
    public var reactions: Bool
    
    public var uploads: Bool
    
    public var commands: [String]
    
    public var replies: Bool
    
    public var urlEnrichment: Bool
    
    public var blocklist: String?
    
    public init(typingEvents: Bool, customEvents: Bool, blocklistBehavior: String?, connectEvents: Bool, updatedAt: String, automod: String, blocklists: [StreamChatBlockListOptions]?, markMessagesPending: Bool, readEvents: Bool, reminders: Bool, search: Bool, allowedFlagReasons: [String]?, messageRetention: String, mutes: Bool, maxMessageLength: Int, pushNotifications: Bool, quotes: Bool, automodThresholds: StreamChatThresholds?, createdAt: String, name: String, automodBehavior: String, reactions: Bool, uploads: Bool, commands: [String], replies: Bool, urlEnrichment: Bool, blocklist: String?) {
        self.typingEvents = typingEvents
        
        self.customEvents = customEvents
        
        self.blocklistBehavior = blocklistBehavior
        
        self.connectEvents = connectEvents
        
        self.updatedAt = updatedAt
        
        self.automod = automod
        
        self.blocklists = blocklists
        
        self.markMessagesPending = markMessagesPending
        
        self.readEvents = readEvents
        
        self.reminders = reminders
        
        self.search = search
        
        self.allowedFlagReasons = allowedFlagReasons
        
        self.messageRetention = messageRetention
        
        self.mutes = mutes
        
        self.maxMessageLength = maxMessageLength
        
        self.pushNotifications = pushNotifications
        
        self.quotes = quotes
        
        self.automodThresholds = automodThresholds
        
        self.createdAt = createdAt
        
        self.name = name
        
        self.automodBehavior = automodBehavior
        
        self.reactions = reactions
        
        self.uploads = uploads
        
        self.commands = commands
        
        self.replies = replies
        
        self.urlEnrichment = urlEnrichment
        
        self.blocklist = blocklist
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case typingEvents = "typing_events"
        
        case customEvents = "custom_events"
        
        case blocklistBehavior = "blocklist_behavior"
        
        case connectEvents = "connect_events"
        
        case updatedAt = "updated_at"
        
        case automod
        
        case blocklists
        
        case markMessagesPending = "mark_messages_pending"
        
        case readEvents = "read_events"
        
        case reminders
        
        case search
        
        case allowedFlagReasons = "allowed_flag_reasons"
        
        case messageRetention = "message_retention"
        
        case mutes
        
        case maxMessageLength = "max_message_length"
        
        case pushNotifications = "push_notifications"
        
        case quotes
        
        case automodThresholds = "automod_thresholds"
        
        case createdAt = "created_at"
        
        case name
        
        case automodBehavior = "automod_behavior"
        
        case reactions
        
        case uploads
        
        case commands
        
        case replies
        
        case urlEnrichment = "url_enrichment"
        
        case blocklist
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(typingEvents, forKey: .typingEvents)
        
        try container.encode(customEvents, forKey: .customEvents)
        
        try container.encode(blocklistBehavior, forKey: .blocklistBehavior)
        
        try container.encode(connectEvents, forKey: .connectEvents)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(automod, forKey: .automod)
        
        try container.encode(blocklists, forKey: .blocklists)
        
        try container.encode(markMessagesPending, forKey: .markMessagesPending)
        
        try container.encode(readEvents, forKey: .readEvents)
        
        try container.encode(reminders, forKey: .reminders)
        
        try container.encode(search, forKey: .search)
        
        try container.encode(allowedFlagReasons, forKey: .allowedFlagReasons)
        
        try container.encode(messageRetention, forKey: .messageRetention)
        
        try container.encode(mutes, forKey: .mutes)
        
        try container.encode(maxMessageLength, forKey: .maxMessageLength)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(quotes, forKey: .quotes)
        
        try container.encode(automodThresholds, forKey: .automodThresholds)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(automodBehavior, forKey: .automodBehavior)
        
        try container.encode(reactions, forKey: .reactions)
        
        try container.encode(uploads, forKey: .uploads)
        
        try container.encode(commands, forKey: .commands)
        
        try container.encode(replies, forKey: .replies)
        
        try container.encode(urlEnrichment, forKey: .urlEnrichment)
        
        try container.encode(blocklist, forKey: .blocklist)
    }
}
