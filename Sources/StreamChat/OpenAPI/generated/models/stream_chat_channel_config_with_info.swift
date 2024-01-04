//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelConfigWithInfo: Codable, Hashable {
    public var messageRetention: String
    
    public var readEvents: Bool
    
    public var grants: [String: RawJSON]?
    
    public var mutes: Bool
    
    public var updatedAt: String
    
    public var urlEnrichment: Bool
    
    public var automodThresholds: StreamChatThresholds?
    
    public var connectEvents: Bool
    
    public var quotes: Bool
    
    public var blocklist: String?
    
    public var customEvents: Bool
    
    public var typingEvents: Bool
    
    public var blocklistBehavior: String?
    
    public var replies: Bool
    
    public var createdAt: String
    
    public var pushNotifications: Bool
    
    public var markMessagesPending: Bool
    
    public var maxMessageLength: Int
    
    public var reminders: Bool
    
    public var search: Bool
    
    public var commands: [StreamChatCommand?]
    
    public var reactions: Bool
    
    public var automodBehavior: String
    
    public var blocklists: [StreamChatBlockListOptions]?
    
    public var name: String
    
    public var uploads: Bool
    
    public var allowedFlagReasons: [String]?
    
    public var automod: String
    
    public init(messageRetention: String, readEvents: Bool, grants: [String: RawJSON]?, mutes: Bool, updatedAt: String, urlEnrichment: Bool, automodThresholds: StreamChatThresholds?, connectEvents: Bool, quotes: Bool, blocklist: String?, customEvents: Bool, typingEvents: Bool, blocklistBehavior: String?, replies: Bool, createdAt: String, pushNotifications: Bool, markMessagesPending: Bool, maxMessageLength: Int, reminders: Bool, search: Bool, commands: [StreamChatCommand?], reactions: Bool, automodBehavior: String, blocklists: [StreamChatBlockListOptions]?, name: String, uploads: Bool, allowedFlagReasons: [String]?, automod: String) {
        self.messageRetention = messageRetention
        
        self.readEvents = readEvents
        
        self.grants = grants
        
        self.mutes = mutes
        
        self.updatedAt = updatedAt
        
        self.urlEnrichment = urlEnrichment
        
        self.automodThresholds = automodThresholds
        
        self.connectEvents = connectEvents
        
        self.quotes = quotes
        
        self.blocklist = blocklist
        
        self.customEvents = customEvents
        
        self.typingEvents = typingEvents
        
        self.blocklistBehavior = blocklistBehavior
        
        self.replies = replies
        
        self.createdAt = createdAt
        
        self.pushNotifications = pushNotifications
        
        self.markMessagesPending = markMessagesPending
        
        self.maxMessageLength = maxMessageLength
        
        self.reminders = reminders
        
        self.search = search
        
        self.commands = commands
        
        self.reactions = reactions
        
        self.automodBehavior = automodBehavior
        
        self.blocklists = blocklists
        
        self.name = name
        
        self.uploads = uploads
        
        self.allowedFlagReasons = allowedFlagReasons
        
        self.automod = automod
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case messageRetention = "message_retention"
        
        case readEvents = "read_events"
        
        case grants
        
        case mutes
        
        case updatedAt = "updated_at"
        
        case urlEnrichment = "url_enrichment"
        
        case automodThresholds = "automod_thresholds"
        
        case connectEvents = "connect_events"
        
        case quotes
        
        case blocklist
        
        case customEvents = "custom_events"
        
        case typingEvents = "typing_events"
        
        case blocklistBehavior = "blocklist_behavior"
        
        case replies
        
        case createdAt = "created_at"
        
        case pushNotifications = "push_notifications"
        
        case markMessagesPending = "mark_messages_pending"
        
        case maxMessageLength = "max_message_length"
        
        case reminders
        
        case search
        
        case commands
        
        case reactions
        
        case automodBehavior = "automod_behavior"
        
        case blocklists
        
        case name
        
        case uploads
        
        case allowedFlagReasons = "allowed_flag_reasons"
        
        case automod
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(messageRetention, forKey: .messageRetention)
        
        try container.encode(readEvents, forKey: .readEvents)
        
        try container.encode(grants, forKey: .grants)
        
        try container.encode(mutes, forKey: .mutes)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(urlEnrichment, forKey: .urlEnrichment)
        
        try container.encode(automodThresholds, forKey: .automodThresholds)
        
        try container.encode(connectEvents, forKey: .connectEvents)
        
        try container.encode(quotes, forKey: .quotes)
        
        try container.encode(blocklist, forKey: .blocklist)
        
        try container.encode(customEvents, forKey: .customEvents)
        
        try container.encode(typingEvents, forKey: .typingEvents)
        
        try container.encode(blocklistBehavior, forKey: .blocklistBehavior)
        
        try container.encode(replies, forKey: .replies)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(markMessagesPending, forKey: .markMessagesPending)
        
        try container.encode(maxMessageLength, forKey: .maxMessageLength)
        
        try container.encode(reminders, forKey: .reminders)
        
        try container.encode(search, forKey: .search)
        
        try container.encode(commands, forKey: .commands)
        
        try container.encode(reactions, forKey: .reactions)
        
        try container.encode(automodBehavior, forKey: .automodBehavior)
        
        try container.encode(blocklists, forKey: .blocklists)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(uploads, forKey: .uploads)
        
        try container.encode(allowedFlagReasons, forKey: .allowedFlagReasons)
        
        try container.encode(automod, forKey: .automod)
    }
}
