//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelConfigWithInfo: Codable, Hashable {
    public var blocklistBehavior: String?
    
    public var markMessagesPending: Bool
    
    public var automod: String
    
    public var name: String
    
    public var messageRetention: String
    
    public var uploads: Bool
    
    public var reactions: Bool
    
    public var readEvents: Bool
    
    public var customEvents: Bool
    
    public var mutes: Bool
    
    public var pushNotifications: Bool
    
    public var quotes: Bool
    
    public var replies: Bool
    
    public var search: Bool
    
    public var updatedAt: String
    
    public var automodThresholds: StreamChatThresholds?
    
    public var blocklist: String?
    
    public var blocklists: [StreamChatBlockListOptions]?
    
    public var maxMessageLength: Int
    
    public var allowedFlagReasons: [String]?
    
    public var connectEvents: Bool
    
    public var createdAt: String
    
    public var automodBehavior: String
    
    public var commands: [StreamChatCommand?]
    
    public var typingEvents: Bool
    
    public var urlEnrichment: Bool
    
    public var grants: [String: RawJSON]?
    
    public var reminders: Bool
    
    public init(blocklistBehavior: String?, markMessagesPending: Bool, automod: String, name: String, messageRetention: String, uploads: Bool, reactions: Bool, readEvents: Bool, customEvents: Bool, mutes: Bool, pushNotifications: Bool, quotes: Bool, replies: Bool, search: Bool, updatedAt: String, automodThresholds: StreamChatThresholds?, blocklist: String?, blocklists: [StreamChatBlockListOptions]?, maxMessageLength: Int, allowedFlagReasons: [String]?, connectEvents: Bool, createdAt: String, automodBehavior: String, commands: [StreamChatCommand?], typingEvents: Bool, urlEnrichment: Bool, grants: [String: RawJSON]?, reminders: Bool) {
        self.blocklistBehavior = blocklistBehavior
        
        self.markMessagesPending = markMessagesPending
        
        self.automod = automod
        
        self.name = name
        
        self.messageRetention = messageRetention
        
        self.uploads = uploads
        
        self.reactions = reactions
        
        self.readEvents = readEvents
        
        self.customEvents = customEvents
        
        self.mutes = mutes
        
        self.pushNotifications = pushNotifications
        
        self.quotes = quotes
        
        self.replies = replies
        
        self.search = search
        
        self.updatedAt = updatedAt
        
        self.automodThresholds = automodThresholds
        
        self.blocklist = blocklist
        
        self.blocklists = blocklists
        
        self.maxMessageLength = maxMessageLength
        
        self.allowedFlagReasons = allowedFlagReasons
        
        self.connectEvents = connectEvents
        
        self.createdAt = createdAt
        
        self.automodBehavior = automodBehavior
        
        self.commands = commands
        
        self.typingEvents = typingEvents
        
        self.urlEnrichment = urlEnrichment
        
        self.grants = grants
        
        self.reminders = reminders
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case blocklistBehavior = "blocklist_behavior"
        
        case markMessagesPending = "mark_messages_pending"
        
        case automod
        
        case name
        
        case messageRetention = "message_retention"
        
        case uploads
        
        case reactions
        
        case readEvents = "read_events"
        
        case customEvents = "custom_events"
        
        case mutes
        
        case pushNotifications = "push_notifications"
        
        case quotes
        
        case replies
        
        case search
        
        case updatedAt = "updated_at"
        
        case automodThresholds = "automod_thresholds"
        
        case blocklist
        
        case blocklists
        
        case maxMessageLength = "max_message_length"
        
        case allowedFlagReasons = "allowed_flag_reasons"
        
        case connectEvents = "connect_events"
        
        case createdAt = "created_at"
        
        case automodBehavior = "automod_behavior"
        
        case commands
        
        case typingEvents = "typing_events"
        
        case urlEnrichment = "url_enrichment"
        
        case grants
        
        case reminders
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(blocklistBehavior, forKey: .blocklistBehavior)
        
        try container.encode(markMessagesPending, forKey: .markMessagesPending)
        
        try container.encode(automod, forKey: .automod)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(messageRetention, forKey: .messageRetention)
        
        try container.encode(uploads, forKey: .uploads)
        
        try container.encode(reactions, forKey: .reactions)
        
        try container.encode(readEvents, forKey: .readEvents)
        
        try container.encode(customEvents, forKey: .customEvents)
        
        try container.encode(mutes, forKey: .mutes)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(quotes, forKey: .quotes)
        
        try container.encode(replies, forKey: .replies)
        
        try container.encode(search, forKey: .search)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(automodThresholds, forKey: .automodThresholds)
        
        try container.encode(blocklist, forKey: .blocklist)
        
        try container.encode(blocklists, forKey: .blocklists)
        
        try container.encode(maxMessageLength, forKey: .maxMessageLength)
        
        try container.encode(allowedFlagReasons, forKey: .allowedFlagReasons)
        
        try container.encode(connectEvents, forKey: .connectEvents)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(automodBehavior, forKey: .automodBehavior)
        
        try container.encode(commands, forKey: .commands)
        
        try container.encode(typingEvents, forKey: .typingEvents)
        
        try container.encode(urlEnrichment, forKey: .urlEnrichment)
        
        try container.encode(grants, forKey: .grants)
        
        try container.encode(reminders, forKey: .reminders)
    }
}
