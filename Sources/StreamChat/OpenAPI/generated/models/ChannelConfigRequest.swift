//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelConfigRequest: Codable, Hashable {
    public var blocklist: String? = nil
    public var blocklistBehavior: String? = nil
    public var maxMessageLength: Int? = nil
    public var quotes: Bool? = nil
    public var reactions: Bool? = nil
    public var replies: Bool? = nil
    public var typingEvents: Bool? = nil
    public var uploads: Bool? = nil
    public var urlEnrichment: Bool? = nil
    public var commands: [String]? = nil
    public var grants: [String: [String]]? = nil

    public init(blocklist: String? = nil, blocklistBehavior: String? = nil, maxMessageLength: Int? = nil, quotes: Bool? = nil, reactions: Bool? = nil, replies: Bool? = nil, typingEvents: Bool? = nil, uploads: Bool? = nil, urlEnrichment: Bool? = nil, commands: [String]? = nil, grants: [String: [String]]? = nil) {
        self.blocklist = blocklist
        self.blocklistBehavior = blocklistBehavior
        self.maxMessageLength = maxMessageLength
        self.quotes = quotes
        self.reactions = reactions
        self.replies = replies
        self.typingEvents = typingEvents
        self.uploads = uploads
        self.urlEnrichment = urlEnrichment
        self.commands = commands
        self.grants = grants
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case blocklist
        case blocklistBehavior = "blocklist_behavior"
        case maxMessageLength = "max_message_length"
        case quotes
        case reactions
        case replies
        case typingEvents = "typing_events"
        case uploads
        case urlEnrichment = "url_enrichment"
        case commands
        case grants
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(blocklist, forKey: .blocklist)
        try container.encode(blocklistBehavior, forKey: .blocklistBehavior)
        try container.encode(maxMessageLength, forKey: .maxMessageLength)
        try container.encode(quotes, forKey: .quotes)
        try container.encode(reactions, forKey: .reactions)
        try container.encode(replies, forKey: .replies)
        try container.encode(typingEvents, forKey: .typingEvents)
        try container.encode(uploads, forKey: .uploads)
        try container.encode(urlEnrichment, forKey: .urlEnrichment)
        try container.encode(commands, forKey: .commands)
        try container.encode(grants, forKey: .grants)
    }
}
