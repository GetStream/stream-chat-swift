//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelConfigWithInfo: Codable, Hashable {
    public var reactions: Bool
    
    public var updatedAt: Date
    
    public var urlEnrichment: Bool
    
    public var allowedFlagReasons: [String]?
    
    public var blocklist: String?
    
    public var replies: Bool
    
    public var uploads: Bool
    
    public var automodBehavior: String
    
    public var pushNotifications: Bool
    
    public var maxMessageLength: Int
    
    public var name: String
    
    public var reminders: Bool
    
    public var automodThresholds: StreamChatThresholds?
    
    public var createdAt: Date
    
    public var connectEvents: Bool
    
    public var customEvents: Bool
    
    public var quotes: Bool
    
    public var search: Bool
    
    public var automod: String
    
    public var blocklistBehavior: String?
    
    public var mutes: Bool
    
    public var blocklists: [StreamChatBlockListOptions]?
    
    public var commands: [StreamChatCommand?]
    
    public var messageRetention: String
    
    public var readEvents: Bool
    
    public var grants: [String: RawJSON]?
    
    public var markMessagesPending: Bool
    
    public var typingEvents: Bool
    
    public init(reactions: Bool, updatedAt: Date, urlEnrichment: Bool, allowedFlagReasons: [String]?, blocklist: String?, replies: Bool, uploads: Bool, automodBehavior: String, pushNotifications: Bool, maxMessageLength: Int, name: String, reminders: Bool, automodThresholds: StreamChatThresholds?, createdAt: Date, connectEvents: Bool, customEvents: Bool, quotes: Bool, search: Bool, automod: String, blocklistBehavior: String?, mutes: Bool, blocklists: [StreamChatBlockListOptions]?, commands: [StreamChatCommand?], messageRetention: String, readEvents: Bool, grants: [String: RawJSON]?, markMessagesPending: Bool, typingEvents: Bool) {
        self.reactions = reactions
        
        self.updatedAt = updatedAt
        
        self.urlEnrichment = urlEnrichment
        
        self.allowedFlagReasons = allowedFlagReasons
        
        self.blocklist = blocklist
        
        self.replies = replies
        
        self.uploads = uploads
        
        self.automodBehavior = automodBehavior
        
        self.pushNotifications = pushNotifications
        
        self.maxMessageLength = maxMessageLength
        
        self.name = name
        
        self.reminders = reminders
        
        self.automodThresholds = automodThresholds
        
        self.createdAt = createdAt
        
        self.connectEvents = connectEvents
        
        self.customEvents = customEvents
        
        self.quotes = quotes
        
        self.search = search
        
        self.automod = automod
        
        self.blocklistBehavior = blocklistBehavior
        
        self.mutes = mutes
        
        self.blocklists = blocklists
        
        self.commands = commands
        
        self.messageRetention = messageRetention
        
        self.readEvents = readEvents
        
        self.grants = grants
        
        self.markMessagesPending = markMessagesPending
        
        self.typingEvents = typingEvents
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case reactions
        
        case updatedAt = "updated_at"
        
        case urlEnrichment = "url_enrichment"
        
        case allowedFlagReasons = "allowed_flag_reasons"
        
        case blocklist
        
        case replies
        
        case uploads
        
        case automodBehavior = "automod_behavior"
        
        case pushNotifications = "push_notifications"
        
        case maxMessageLength = "max_message_length"
        
        case name
        
        case reminders
        
        case automodThresholds = "automod_thresholds"
        
        case createdAt = "created_at"
        
        case connectEvents = "connect_events"
        
        case customEvents = "custom_events"
        
        case quotes
        
        case search
        
        case automod
        
        case blocklistBehavior = "blocklist_behavior"
        
        case mutes
        
        case blocklists
        
        case commands
        
        case messageRetention = "message_retention"
        
        case readEvents = "read_events"
        
        case grants
        
        case markMessagesPending = "mark_messages_pending"
        
        case typingEvents = "typing_events"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(reactions, forKey: .reactions)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(urlEnrichment, forKey: .urlEnrichment)
        
        try container.encode(allowedFlagReasons, forKey: .allowedFlagReasons)
        
        try container.encode(blocklist, forKey: .blocklist)
        
        try container.encode(replies, forKey: .replies)
        
        try container.encode(uploads, forKey: .uploads)
        
        try container.encode(automodBehavior, forKey: .automodBehavior)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(maxMessageLength, forKey: .maxMessageLength)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(reminders, forKey: .reminders)
        
        try container.encode(automodThresholds, forKey: .automodThresholds)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(connectEvents, forKey: .connectEvents)
        
        try container.encode(customEvents, forKey: .customEvents)
        
        try container.encode(quotes, forKey: .quotes)
        
        try container.encode(search, forKey: .search)
        
        try container.encode(automod, forKey: .automod)
        
        try container.encode(blocklistBehavior, forKey: .blocklistBehavior)
        
        try container.encode(mutes, forKey: .mutes)
        
        try container.encode(blocklists, forKey: .blocklists)
        
        try container.encode(commands, forKey: .commands)
        
        try container.encode(messageRetention, forKey: .messageRetention)
        
        try container.encode(readEvents, forKey: .readEvents)
        
        try container.encode(grants, forKey: .grants)
        
        try container.encode(markMessagesPending, forKey: .markMessagesPending)
        
        try container.encode(typingEvents, forKey: .typingEvents)
    }
}
