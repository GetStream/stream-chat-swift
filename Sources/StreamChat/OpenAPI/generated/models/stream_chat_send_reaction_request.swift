//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSendReactionRequest: Codable, Hashable {
    public var reaction: StreamChatReactionRequest
    
    public var enforceUnique: Bool? = nil
    
    public var iD: String? = nil
    
    public var skipPush: Bool? = nil
    
    public init(reaction: StreamChatReactionRequest, enforceUnique: Bool? = nil, iD: String? = nil, skipPush: Bool? = nil) {
        self.reaction = reaction
        
        self.enforceUnique = enforceUnique
        
        self.iD = iD
        
        self.skipPush = skipPush
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case reaction
        
        case enforceUnique = "enforce_unique"
        
        case iD = "ID"
        
        case skipPush = "skip_push"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(enforceUnique, forKey: .enforceUnique)
        
        try container.encode(iD, forKey: .iD)
        
        try container.encode(skipPush, forKey: .skipPush)
    }
}
