//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelConfigRequest: Codable, Hashable {
    public var quotes: Bool?
    
    public var replies: Bool?
    
    public var typingEvents: Bool?
    
    public var uploads: Bool?
    
    public var blocklist: String?
    
    public var blocklistBehavior: String?
    
    public var grants: [String: RawJSON]?
    
    public var maxMessageLength: Int?
    
    public var commands: [String]?
    
    public var reactions: Bool?
    
    public var urlEnrichment: Bool?
    
    public init(quotes: Bool?, replies: Bool?, typingEvents: Bool?, uploads: Bool?, blocklist: String?, blocklistBehavior: String?, grants: [String: RawJSON]?, maxMessageLength: Int?, commands: [String]?, reactions: Bool?, urlEnrichment: Bool?) {
        self.quotes = quotes
        
        self.replies = replies
        
        self.typingEvents = typingEvents
        
        self.uploads = uploads
        
        self.blocklist = blocklist
        
        self.blocklistBehavior = blocklistBehavior
        
        self.grants = grants
        
        self.maxMessageLength = maxMessageLength
        
        self.commands = commands
        
        self.reactions = reactions
        
        self.urlEnrichment = urlEnrichment
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case quotes
        
        case replies
        
        case typingEvents = "typing_events"
        
        case uploads
        
        case blocklist
        
        case blocklistBehavior = "blocklist_behavior"
        
        case grants
        
        case maxMessageLength = "max_message_length"
        
        case commands
        
        case reactions
        
        case urlEnrichment = "url_enrichment"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(quotes, forKey: .quotes)
        
        try container.encode(replies, forKey: .replies)
        
        try container.encode(typingEvents, forKey: .typingEvents)
        
        try container.encode(uploads, forKey: .uploads)
        
        try container.encode(blocklist, forKey: .blocklist)
        
        try container.encode(blocklistBehavior, forKey: .blocklistBehavior)
        
        try container.encode(grants, forKey: .grants)
        
        try container.encode(maxMessageLength, forKey: .maxMessageLength)
        
        try container.encode(commands, forKey: .commands)
        
        try container.encode(reactions, forKey: .reactions)
        
        try container.encode(urlEnrichment, forKey: .urlEnrichment)
    }
}
