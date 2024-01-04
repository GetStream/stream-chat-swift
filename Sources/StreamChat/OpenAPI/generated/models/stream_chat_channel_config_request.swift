//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelConfigRequest: Codable, Hashable {
    public var blocklist: String?
    
    public var grants: [String: RawJSON]?
    
    public var maxMessageLength: Int?
    
    public var typingEvents: Bool?
    
    public var uploads: Bool?
    
    public var blocklistBehavior: String?
    
    public var commands: [String]?
    
    public var quotes: Bool?
    
    public var reactions: Bool?
    
    public var replies: Bool?
    
    public var urlEnrichment: Bool?
    
    public init(blocklist: String?, grants: [String: RawJSON]?, maxMessageLength: Int?, typingEvents: Bool?, uploads: Bool?, blocklistBehavior: String?, commands: [String]?, quotes: Bool?, reactions: Bool?, replies: Bool?, urlEnrichment: Bool?) {
        self.blocklist = blocklist
        
        self.grants = grants
        
        self.maxMessageLength = maxMessageLength
        
        self.typingEvents = typingEvents
        
        self.uploads = uploads
        
        self.blocklistBehavior = blocklistBehavior
        
        self.commands = commands
        
        self.quotes = quotes
        
        self.reactions = reactions
        
        self.replies = replies
        
        self.urlEnrichment = urlEnrichment
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case blocklist
        
        case grants
        
        case maxMessageLength = "max_message_length"
        
        case typingEvents = "typing_events"
        
        case uploads
        
        case blocklistBehavior = "blocklist_behavior"
        
        case commands
        
        case quotes
        
        case reactions
        
        case replies
        
        case urlEnrichment = "url_enrichment"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(blocklist, forKey: .blocklist)
        
        try container.encode(grants, forKey: .grants)
        
        try container.encode(maxMessageLength, forKey: .maxMessageLength)
        
        try container.encode(typingEvents, forKey: .typingEvents)
        
        try container.encode(uploads, forKey: .uploads)
        
        try container.encode(blocklistBehavior, forKey: .blocklistBehavior)
        
        try container.encode(commands, forKey: .commands)
        
        try container.encode(quotes, forKey: .quotes)
        
        try container.encode(reactions, forKey: .reactions)
        
        try container.encode(replies, forKey: .replies)
        
        try container.encode(urlEnrichment, forKey: .urlEnrichment)
    }
}
