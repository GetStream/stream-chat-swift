//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelConfigWithInfo: Codable, Hashable {
    public var reminders: Bool
    
    public var search: Bool
    
    public var typingEvents: Bool
    
    public var blocklists: [StreamChatBlockListOptions]?
    
    public var customEvents: Bool
    
    public var pushNotifications: Bool
    
    public var reactions: Bool
    
    public var markMessagesPending: Bool
    
    public var messageRetention: String
    
    public var urlEnrichment: Bool
    
    public var replies: Bool
    
    public var updatedAt: String
    
    public var uploads: Bool
    
    public var automodThresholds: StreamChatThresholds?
    
    public var createdAt: String
    
    public var maxMessageLength: Int
    
    public var readEvents: Bool
    
    public var mutes: Bool
    
    public var grants: [String: RawJSON]?
    
    public var quotes: Bool
    
    public var allowedFlagReasons: [String]?
    
    public var automod: String
    
    public var blocklist: String?
    
    public var commands: [StreamChatCommand?]
    
    public var automodBehavior: String
    
    public var connectEvents: Bool
    
    public var blocklistBehavior: String?
    
    public var name: String
    
    public init(reminders: Bool, search: Bool, typingEvents: Bool, blocklists: [StreamChatBlockListOptions]?, customEvents: Bool, pushNotifications: Bool, reactions: Bool, markMessagesPending: Bool, messageRetention: String, urlEnrichment: Bool, replies: Bool, updatedAt: String, uploads: Bool, automodThresholds: StreamChatThresholds?, createdAt: String, maxMessageLength: Int, readEvents: Bool, mutes: Bool, grants: [String: RawJSON]?, quotes: Bool, allowedFlagReasons: [String]?, automod: String, blocklist: String?, commands: [StreamChatCommand?], automodBehavior: String, connectEvents: Bool, blocklistBehavior: String?, name: String) {
        self.reminders = reminders
        
        self.search = search
        
        self.typingEvents = typingEvents
        
        self.blocklists = blocklists
        
        self.customEvents = customEvents
        
        self.pushNotifications = pushNotifications
        
        self.reactions = reactions
        
        self.markMessagesPending = markMessagesPending
        
        self.messageRetention = messageRetention
        
        self.urlEnrichment = urlEnrichment
        
        self.replies = replies
        
        self.updatedAt = updatedAt
        
        self.uploads = uploads
        
        self.automodThresholds = automodThresholds
        
        self.createdAt = createdAt
        
        self.maxMessageLength = maxMessageLength
        
        self.readEvents = readEvents
        
        self.mutes = mutes
        
        self.grants = grants
        
        self.quotes = quotes
        
        self.allowedFlagReasons = allowedFlagReasons
        
        self.automod = automod
        
        self.blocklist = blocklist
        
        self.commands = commands
        
        self.automodBehavior = automodBehavior
        
        self.connectEvents = connectEvents
        
        self.blocklistBehavior = blocklistBehavior
        
        self.name = name
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case reminders
        
        case search
        
        case typingEvents = "typing_events"
        
        case blocklists
        
        case customEvents = "custom_events"
        
        case pushNotifications = "push_notifications"
        
        case reactions
        
        case markMessagesPending = "mark_messages_pending"
        
        case messageRetention = "message_retention"
        
        case urlEnrichment = "url_enrichment"
        
        case replies
        
        case updatedAt = "updated_at"
        
        case uploads
        
        case automodThresholds = "automod_thresholds"
        
        case createdAt = "created_at"
        
        case maxMessageLength = "max_message_length"
        
        case readEvents = "read_events"
        
        case mutes
        
        case grants
        
        case quotes
        
        case allowedFlagReasons = "allowed_flag_reasons"
        
        case automod
        
        case blocklist
        
        case commands
        
        case automodBehavior = "automod_behavior"
        
        case connectEvents = "connect_events"
        
        case blocklistBehavior = "blocklist_behavior"
        
        case name
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(reminders, forKey: .reminders)
        
        try container.encode(search, forKey: .search)
        
        try container.encode(typingEvents, forKey: .typingEvents)
        
        try container.encode(blocklists, forKey: .blocklists)
        
        try container.encode(customEvents, forKey: .customEvents)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(reactions, forKey: .reactions)
        
        try container.encode(markMessagesPending, forKey: .markMessagesPending)
        
        try container.encode(messageRetention, forKey: .messageRetention)
        
        try container.encode(urlEnrichment, forKey: .urlEnrichment)
        
        try container.encode(replies, forKey: .replies)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(uploads, forKey: .uploads)
        
        try container.encode(automodThresholds, forKey: .automodThresholds)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(maxMessageLength, forKey: .maxMessageLength)
        
        try container.encode(readEvents, forKey: .readEvents)
        
        try container.encode(mutes, forKey: .mutes)
        
        try container.encode(grants, forKey: .grants)
        
        try container.encode(quotes, forKey: .quotes)
        
        try container.encode(allowedFlagReasons, forKey: .allowedFlagReasons)
        
        try container.encode(automod, forKey: .automod)
        
        try container.encode(blocklist, forKey: .blocklist)
        
        try container.encode(commands, forKey: .commands)
        
        try container.encode(automodBehavior, forKey: .automodBehavior)
        
        try container.encode(connectEvents, forKey: .connectEvents)
        
        try container.encode(blocklistBehavior, forKey: .blocklistBehavior)
        
        try container.encode(name, forKey: .name)
    }
}
