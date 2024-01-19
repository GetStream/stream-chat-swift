//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelConfigWithInfo: Codable, Hashable {
    public var reactions: Bool
    
    public var typingEvents: Bool
    
    public var allowedFlagReasons: [String]?
    
    public var automod: String
    
    public var connectEvents: Bool
    
    public var markMessagesPending: Bool
    
    public var name: String
    
    public var pushNotifications: Bool
    
    public var automodThresholds: StreamChatThresholds?
    
    public var blocklist: String?
    
    public var quotes: Bool
    
    public var blocklists: [StreamChatBlockListOptions]?
    
    public var createdAt: Date
    
    public var readEvents: Bool
    
    public var commands: [StreamChatCommand?]
    
    public var customEvents: Bool
    
    public var grants: [String: RawJSON]?
    
    public var mutes: Bool
    
    public var replies: Bool
    
    public var search: Bool
    
    public var updatedAt: Date
    
    public var uploads: Bool
    
    public var blocklistBehavior: String?
    
    public var messageRetention: String
    
    public var reminders: Bool
    
    public var urlEnrichment: Bool
    
    public var automodBehavior: String
    
    public var maxMessageLength: Int
    
    public init(reactions: Bool, typingEvents: Bool, allowedFlagReasons: [String]?, automod: String, connectEvents: Bool, markMessagesPending: Bool, name: String, pushNotifications: Bool, automodThresholds: StreamChatThresholds?, blocklist: String?, quotes: Bool, blocklists: [StreamChatBlockListOptions]?, createdAt: Date, readEvents: Bool, commands: [StreamChatCommand?], customEvents: Bool, grants: [String: RawJSON]?, mutes: Bool, replies: Bool, search: Bool, updatedAt: Date, uploads: Bool, blocklistBehavior: String?, messageRetention: String, reminders: Bool, urlEnrichment: Bool, automodBehavior: String, maxMessageLength: Int) {
        self.reactions = reactions
        
        self.typingEvents = typingEvents
        
        self.allowedFlagReasons = allowedFlagReasons
        
        self.automod = automod
        
        self.connectEvents = connectEvents
        
        self.markMessagesPending = markMessagesPending
        
        self.name = name
        
        self.pushNotifications = pushNotifications
        
        self.automodThresholds = automodThresholds
        
        self.blocklist = blocklist
        
        self.quotes = quotes
        
        self.blocklists = blocklists
        
        self.createdAt = createdAt
        
        self.readEvents = readEvents
        
        self.commands = commands
        
        self.customEvents = customEvents
        
        self.grants = grants
        
        self.mutes = mutes
        
        self.replies = replies
        
        self.search = search
        
        self.updatedAt = updatedAt
        
        self.uploads = uploads
        
        self.blocklistBehavior = blocklistBehavior
        
        self.messageRetention = messageRetention
        
        self.reminders = reminders
        
        self.urlEnrichment = urlEnrichment
        
        self.automodBehavior = automodBehavior
        
        self.maxMessageLength = maxMessageLength
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case reactions
        
        case typingEvents = "typing_events"
        
        case allowedFlagReasons = "allowed_flag_reasons"
        
        case automod
        
        case connectEvents = "connect_events"
        
        case markMessagesPending = "mark_messages_pending"
        
        case name
        
        case pushNotifications = "push_notifications"
        
        case automodThresholds = "automod_thresholds"
        
        case blocklist
        
        case quotes
        
        case blocklists
        
        case createdAt = "created_at"
        
        case readEvents = "read_events"
        
        case commands
        
        case customEvents = "custom_events"
        
        case grants
        
        case mutes
        
        case replies
        
        case search
        
        case updatedAt = "updated_at"
        
        case uploads
        
        case blocklistBehavior = "blocklist_behavior"
        
        case messageRetention = "message_retention"
        
        case reminders
        
        case urlEnrichment = "url_enrichment"
        
        case automodBehavior = "automod_behavior"
        
        case maxMessageLength = "max_message_length"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(reactions, forKey: .reactions)
        
        try container.encode(typingEvents, forKey: .typingEvents)
        
        try container.encode(allowedFlagReasons, forKey: .allowedFlagReasons)
        
        try container.encode(automod, forKey: .automod)
        
        try container.encode(connectEvents, forKey: .connectEvents)
        
        try container.encode(markMessagesPending, forKey: .markMessagesPending)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(automodThresholds, forKey: .automodThresholds)
        
        try container.encode(blocklist, forKey: .blocklist)
        
        try container.encode(quotes, forKey: .quotes)
        
        try container.encode(blocklists, forKey: .blocklists)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(readEvents, forKey: .readEvents)
        
        try container.encode(commands, forKey: .commands)
        
        try container.encode(customEvents, forKey: .customEvents)
        
        try container.encode(grants, forKey: .grants)
        
        try container.encode(mutes, forKey: .mutes)
        
        try container.encode(replies, forKey: .replies)
        
        try container.encode(search, forKey: .search)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(uploads, forKey: .uploads)
        
        try container.encode(blocklistBehavior, forKey: .blocklistBehavior)
        
        try container.encode(messageRetention, forKey: .messageRetention)
        
        try container.encode(reminders, forKey: .reminders)
        
        try container.encode(urlEnrichment, forKey: .urlEnrichment)
        
        try container.encode(automodBehavior, forKey: .automodBehavior)
        
        try container.encode(maxMessageLength, forKey: .maxMessageLength)
    }
}
