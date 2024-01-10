//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelConfigRequest: Codable, Hashable {
    public var commands: [String]?
    
    public var quotes: Bool?
    
    public var reactions: Bool?
    
    public var replies: Bool?
    
    public var typingEvents: Bool?
    
    public var urlEnrichment: Bool?
    
    public var blocklist: String?
    
    public var blocklistBehavior: String?
    
    public var grants: [String: RawJSON]?
    
    public var maxMessageLength: Int?
    
    public var uploads: Bool?
    
    public init(commands: [String]?, quotes: Bool?, reactions: Bool?, replies: Bool?, typingEvents: Bool?, urlEnrichment: Bool?, blocklist: String?, blocklistBehavior: String?, grants: [String: RawJSON]?, maxMessageLength: Int?, uploads: Bool?) {
        self.commands = commands
        
        self.quotes = quotes
        
        self.reactions = reactions
        
        self.replies = replies
        
        self.typingEvents = typingEvents
        
        self.urlEnrichment = urlEnrichment
        
        self.blocklist = blocklist
        
        self.blocklistBehavior = blocklistBehavior
        
        self.grants = grants
        
        self.maxMessageLength = maxMessageLength
        
        self.uploads = uploads
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case commands
        
        case quotes
        
        case reactions
        
        case replies
        
        case typingEvents = "typing_events"
        
        case urlEnrichment = "url_enrichment"
        
        case blocklist
        
        case blocklistBehavior = "blocklist_behavior"
        
        case grants
        
        case maxMessageLength = "max_message_length"
        
        case uploads
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(commands, forKey: .commands)
        
        try container.encode(quotes, forKey: .quotes)
        
        try container.encode(reactions, forKey: .reactions)
        
        try container.encode(replies, forKey: .replies)
        
        try container.encode(typingEvents, forKey: .typingEvents)
        
        try container.encode(urlEnrichment, forKey: .urlEnrichment)
        
        try container.encode(blocklist, forKey: .blocklist)
        
        try container.encode(blocklistBehavior, forKey: .blocklistBehavior)
        
        try container.encode(grants, forKey: .grants)
        
        try container.encode(maxMessageLength, forKey: .maxMessageLength)
        
        try container.encode(uploads, forKey: .uploads)
    }
}
