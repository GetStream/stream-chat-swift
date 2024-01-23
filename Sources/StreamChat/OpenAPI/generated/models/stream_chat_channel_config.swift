//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelConfig: Codable, Hashable {
    public var automod: String
    
    public var automodBehavior: String
    
    public var connectEvents: Bool
    
    public var createdAt: Date
    
    public var customEvents: Bool
    
    public var markMessagesPending: Bool
    
    public var maxMessageLength: Int
    
    public var messageRetention: String
    
    public var mutes: Bool
    
    public var name: String
    
    public var pushNotifications: Bool
    
    public var quotes: Bool
    
    public var reactions: Bool
    
    public var readEvents: Bool
    
    public var reminders: Bool
    
    public var replies: Bool
    
    public var search: Bool
    
    public var typingEvents: Bool
    
    public var updatedAt: Date
    
    public var uploads: Bool
    
    public var urlEnrichment: Bool
    
    public var commands: [String]
    
    public var blocklist: String? = nil
    
    public var blocklistBehavior: String? = nil
    
    public var allowedFlagReasons: [String]? = nil
    
    public var blocklists: [StreamChatBlockListOptions]? = nil
    
    public var automodThresholds: StreamChatThresholds? = nil
    
    public init(automod: String, automodBehavior: String, connectEvents: Bool, createdAt: Date, customEvents: Bool, markMessagesPending: Bool, maxMessageLength: Int, messageRetention: String, mutes: Bool, name: String, pushNotifications: Bool, quotes: Bool, reactions: Bool, readEvents: Bool, reminders: Bool, replies: Bool, search: Bool, typingEvents: Bool, updatedAt: Date, uploads: Bool, urlEnrichment: Bool, commands: [String], blocklist: String? = nil, blocklistBehavior: String? = nil, allowedFlagReasons: [String]? = nil, blocklists: [StreamChatBlockListOptions]? = nil, automodThresholds: StreamChatThresholds? = nil) {
        self.automod = automod
        
        self.automodBehavior = automodBehavior
        
        self.connectEvents = connectEvents
        
        self.createdAt = createdAt
        
        self.customEvents = customEvents
        
        self.markMessagesPending = markMessagesPending
        
        self.maxMessageLength = maxMessageLength
        
        self.messageRetention = messageRetention
        
        self.mutes = mutes
        
        self.name = name
        
        self.pushNotifications = pushNotifications
        
        self.quotes = quotes
        
        self.reactions = reactions
        
        self.readEvents = readEvents
        
        self.reminders = reminders
        
        self.replies = replies
        
        self.search = search
        
        self.typingEvents = typingEvents
        
        self.updatedAt = updatedAt
        
        self.uploads = uploads
        
        self.urlEnrichment = urlEnrichment
        
        self.commands = commands
        
        self.blocklist = blocklist
        
        self.blocklistBehavior = blocklistBehavior
        
        self.allowedFlagReasons = allowedFlagReasons
        
        self.blocklists = blocklists
        
        self.automodThresholds = automodThresholds
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case automod
        
        case automodBehavior = "automod_behavior"
        
        case connectEvents = "connect_events"
        
        case createdAt = "created_at"
        
        case customEvents = "custom_events"
        
        case markMessagesPending = "mark_messages_pending"
        
        case maxMessageLength = "max_message_length"
        
        case messageRetention = "message_retention"
        
        case mutes
        
        case name
        
        case pushNotifications = "push_notifications"
        
        case quotes
        
        case reactions
        
        case readEvents = "read_events"
        
        case reminders
        
        case replies
        
        case search
        
        case typingEvents = "typing_events"
        
        case updatedAt = "updated_at"
        
        case uploads
        
        case urlEnrichment = "url_enrichment"
        
        case commands
        
        case blocklist
        
        case blocklistBehavior = "blocklist_behavior"
        
        case allowedFlagReasons = "allowed_flag_reasons"
        
        case blocklists
        
        case automodThresholds = "automod_thresholds"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(automod, forKey: .automod)
        
        try container.encode(automodBehavior, forKey: .automodBehavior)
        
        try container.encode(connectEvents, forKey: .connectEvents)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(customEvents, forKey: .customEvents)
        
        try container.encode(markMessagesPending, forKey: .markMessagesPending)
        
        try container.encode(maxMessageLength, forKey: .maxMessageLength)
        
        try container.encode(messageRetention, forKey: .messageRetention)
        
        try container.encode(mutes, forKey: .mutes)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(quotes, forKey: .quotes)
        
        try container.encode(reactions, forKey: .reactions)
        
        try container.encode(readEvents, forKey: .readEvents)
        
        try container.encode(reminders, forKey: .reminders)
        
        try container.encode(replies, forKey: .replies)
        
        try container.encode(search, forKey: .search)
        
        try container.encode(typingEvents, forKey: .typingEvents)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(uploads, forKey: .uploads)
        
        try container.encode(urlEnrichment, forKey: .urlEnrichment)
        
        try container.encode(commands, forKey: .commands)
        
        try container.encode(blocklist, forKey: .blocklist)
        
        try container.encode(blocklistBehavior, forKey: .blocklistBehavior)
        
        try container.encode(allowedFlagReasons, forKey: .allowedFlagReasons)
        
        try container.encode(blocklists, forKey: .blocklists)
        
        try container.encode(automodThresholds, forKey: .automodThresholds)
    }
}
