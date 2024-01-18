//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSendReactionRequest: Codable, Hashable {
    public var enforceUnique: Bool?
    
    public var reaction: StreamChatReactionRequest
    
    public var skipPush: Bool?
    
    public var iD: String?
    
    public init(enforceUnique: Bool?, reaction: StreamChatReactionRequest, skipPush: Bool?, iD: String?) {
        self.enforceUnique = enforceUnique
        
        self.reaction = reaction
        
        self.skipPush = skipPush
        
        self.iD = iD
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enforceUnique = "enforce_unique"
        
        case reaction
        
        case skipPush = "skip_push"
        
        case iD = "ID"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(enforceUnique, forKey: .enforceUnique)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(skipPush, forKey: .skipPush)
        
        try container.encode(iD, forKey: .iD)
    }
}
