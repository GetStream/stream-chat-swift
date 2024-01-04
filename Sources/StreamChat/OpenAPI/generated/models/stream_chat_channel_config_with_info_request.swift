//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelConfigWithInfoRequest: Codable, Hashable {
    public var markMessagesPending: Bool?
    
    public var search: Bool?
    
    public var uploads: Bool?
    
    public var blocklistBehavior: String?
    
    public var blocklists: [StreamChatBlockListOptionsRequest]?
    
    public var reminders: Bool?
    
    public var blocklist: String?
    
    public var typingEvents: Bool?
    
    public var mutes: Bool?
    
    public var customEvents: Bool?
    
    public var maxMessageLength: Int?
    
    public var quotes: Bool?
    
    public var urlEnrichment: Bool?
    
    public var commands: [StreamChatCommandRequest?]?
    
    public var createdAt: String?
    
    public var grants: [String: RawJSON]?
    
    public var name: String?
    
    public var pushNotifications: Bool?
    
    public var replies: Bool?
    
    public var automodThresholds: StreamChatThresholdsRequest?
    
    public var automodBehavior: String?
    
    public var automod: String
    
    public var connectEvents: Bool?
    
    public var messageRetention: String?
    
    public var updatedAt: String?
    
    public var allowedFlagReasons: [String]?
    
    public var readEvents: Bool?
    
    public var reactions: Bool?
    
    public init(markMessagesPending: Bool?, search: Bool?, uploads: Bool?, blocklistBehavior: String?, blocklists: [StreamChatBlockListOptionsRequest]?, reminders: Bool?, blocklist: String?, typingEvents: Bool?, mutes: Bool?, customEvents: Bool?, maxMessageLength: Int?, quotes: Bool?, urlEnrichment: Bool?, commands: [StreamChatCommandRequest?]?, createdAt: String?, grants: [String: RawJSON]?, name: String?, pushNotifications: Bool?, replies: Bool?, automodThresholds: StreamChatThresholdsRequest?, automodBehavior: String?, automod: String, connectEvents: Bool?, messageRetention: String?, updatedAt: String?, allowedFlagReasons: [String]?, readEvents: Bool?, reactions: Bool?) {
        self.markMessagesPending = markMessagesPending
        
        self.search = search
        
        self.uploads = uploads
        
        self.blocklistBehavior = blocklistBehavior
        
        self.blocklists = blocklists
        
        self.reminders = reminders
        
        self.blocklist = blocklist
        
        self.typingEvents = typingEvents
        
        self.mutes = mutes
        
        self.customEvents = customEvents
        
        self.maxMessageLength = maxMessageLength
        
        self.quotes = quotes
        
        self.urlEnrichment = urlEnrichment
        
        self.commands = commands
        
        self.createdAt = createdAt
        
        self.grants = grants
        
        self.name = name
        
        self.pushNotifications = pushNotifications
        
        self.replies = replies
        
        self.automodThresholds = automodThresholds
        
        self.automodBehavior = automodBehavior
        
        self.automod = automod
        
        self.connectEvents = connectEvents
        
        self.messageRetention = messageRetention
        
        self.updatedAt = updatedAt
        
        self.allowedFlagReasons = allowedFlagReasons
        
        self.readEvents = readEvents
        
        self.reactions = reactions
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case markMessagesPending = "mark_messages_pending"
        
        case search
        
        case uploads
        
        case blocklistBehavior = "blocklist_behavior"
        
        case blocklists
        
        case reminders
        
        case blocklist
        
        case typingEvents = "typing_events"
        
        case mutes
        
        case customEvents = "custom_events"
        
        case maxMessageLength = "max_message_length"
        
        case quotes
        
        case urlEnrichment = "url_enrichment"
        
        case commands
        
        case createdAt = "created_at"
        
        case grants
        
        case name
        
        case pushNotifications = "push_notifications"
        
        case replies
        
        case automodThresholds = "automod_thresholds"
        
        case automodBehavior = "automod_behavior"
        
        case automod
        
        case connectEvents = "connect_events"
        
        case messageRetention = "message_retention"
        
        case updatedAt = "updated_at"
        
        case allowedFlagReasons = "allowed_flag_reasons"
        
        case readEvents = "read_events"
        
        case reactions
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(markMessagesPending, forKey: .markMessagesPending)
        
        try container.encode(search, forKey: .search)
        
        try container.encode(uploads, forKey: .uploads)
        
        try container.encode(blocklistBehavior, forKey: .blocklistBehavior)
        
        try container.encode(blocklists, forKey: .blocklists)
        
        try container.encode(reminders, forKey: .reminders)
        
        try container.encode(blocklist, forKey: .blocklist)
        
        try container.encode(typingEvents, forKey: .typingEvents)
        
        try container.encode(mutes, forKey: .mutes)
        
        try container.encode(customEvents, forKey: .customEvents)
        
        try container.encode(maxMessageLength, forKey: .maxMessageLength)
        
        try container.encode(quotes, forKey: .quotes)
        
        try container.encode(urlEnrichment, forKey: .urlEnrichment)
        
        try container.encode(commands, forKey: .commands)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(grants, forKey: .grants)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(pushNotifications, forKey: .pushNotifications)
        
        try container.encode(replies, forKey: .replies)
        
        try container.encode(automodThresholds, forKey: .automodThresholds)
        
        try container.encode(automodBehavior, forKey: .automodBehavior)
        
        try container.encode(automod, forKey: .automod)
        
        try container.encode(connectEvents, forKey: .connectEvents)
        
        try container.encode(messageRetention, forKey: .messageRetention)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(allowedFlagReasons, forKey: .allowedFlagReasons)
        
        try container.encode(readEvents, forKey: .readEvents)
        
        try container.encode(reactions, forKey: .reactions)
    }
}
