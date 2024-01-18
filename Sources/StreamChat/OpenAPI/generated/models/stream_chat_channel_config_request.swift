//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelConfigRequest: Codable, Hashable {
    public var commands: [String]?
    
    public var grants: [String: RawJSON]?
    
    public var reactions: Bool?
    
    public var typingEvents: Bool?
    
    public var uploads: Bool?
    
    public var blocklistBehavior: String?
    
    public var maxMessageLength: Int?
    
    public var quotes: Bool?
    
    public var replies: Bool?
    
    public var urlEnrichment: Bool?
    
    public var blocklist: String?
    
    public init(commands: [String]?, grants: [String: RawJSON]?, reactions: Bool?, typingEvents: Bool?, uploads: Bool?, blocklistBehavior: String?, maxMessageLength: Int?, quotes: Bool?, replies: Bool?, urlEnrichment: Bool?, blocklist: String?) {
        self.commands = commands
        
        self.grants = grants
        
        self.reactions = reactions
        
        self.typingEvents = typingEvents
        
        self.uploads = uploads
        
        self.blocklistBehavior = blocklistBehavior
        
        self.maxMessageLength = maxMessageLength
        
        self.quotes = quotes
        
        self.replies = replies
        
        self.urlEnrichment = urlEnrichment
        
        self.blocklist = blocklist
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case commands
        
        case grants
        
        case reactions
        
        case typingEvents = "typing_events"
        
        case uploads
        
        case blocklistBehavior = "blocklist_behavior"
        
        case maxMessageLength = "max_message_length"
        
        case quotes
        
        case replies
        
        case urlEnrichment = "url_enrichment"
        
        case blocklist
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(commands, forKey: .commands)
        
        try container.encode(grants, forKey: .grants)
        
        try container.encode(reactions, forKey: .reactions)
        
        try container.encode(typingEvents, forKey: .typingEvents)
        
        try container.encode(uploads, forKey: .uploads)
        
        try container.encode(blocklistBehavior, forKey: .blocklistBehavior)
        
        try container.encode(maxMessageLength, forKey: .maxMessageLength)
        
        try container.encode(quotes, forKey: .quotes)
        
        try container.encode(replies, forKey: .replies)
        
        try container.encode(urlEnrichment, forKey: .urlEnrichment)
        
        try container.encode(blocklist, forKey: .blocklist)
    }
}
