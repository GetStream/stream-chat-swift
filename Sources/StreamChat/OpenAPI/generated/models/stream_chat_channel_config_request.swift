//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelConfigRequest: Codable, Hashable {
    public var urlEnrichment: Bool?
    
    public var blocklist: String?
    
    public var blocklistBehavior: String?
    
    public var replies: Bool?
    
    public var typingEvents: Bool?
    
    public var uploads: Bool?
    
    public var commands: [String]?
    
    public var grants: [String: RawJSON]?
    
    public var maxMessageLength: Int?
    
    public var quotes: Bool?
    
    public var reactions: Bool?
    
    public init(urlEnrichment: Bool?, blocklist: String?, blocklistBehavior: String?, replies: Bool?, typingEvents: Bool?, uploads: Bool?, commands: [String]?, grants: [String: RawJSON]?, maxMessageLength: Int?, quotes: Bool?, reactions: Bool?) {
        self.urlEnrichment = urlEnrichment
        
        self.blocklist = blocklist
        
        self.blocklistBehavior = blocklistBehavior
        
        self.replies = replies
        
        self.typingEvents = typingEvents
        
        self.uploads = uploads
        
        self.commands = commands
        
        self.grants = grants
        
        self.maxMessageLength = maxMessageLength
        
        self.quotes = quotes
        
        self.reactions = reactions
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case urlEnrichment = "url_enrichment"
        
        case blocklist
        
        case blocklistBehavior = "blocklist_behavior"
        
        case replies
        
        case typingEvents = "typing_events"
        
        case uploads
        
        case commands
        
        case grants
        
        case maxMessageLength = "max_message_length"
        
        case quotes
        
        case reactions
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(urlEnrichment, forKey: .urlEnrichment)
        
        try container.encode(blocklist, forKey: .blocklist)
        
        try container.encode(blocklistBehavior, forKey: .blocklistBehavior)
        
        try container.encode(replies, forKey: .replies)
        
        try container.encode(typingEvents, forKey: .typingEvents)
        
        try container.encode(uploads, forKey: .uploads)
        
        try container.encode(commands, forKey: .commands)
        
        try container.encode(grants, forKey: .grants)
        
        try container.encode(maxMessageLength, forKey: .maxMessageLength)
        
        try container.encode(quotes, forKey: .quotes)
        
        try container.encode(reactions, forKey: .reactions)
    }
}
