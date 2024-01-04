//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSendReactionRequest: Codable, Hashable {
    public var iD: String?
    
    public var enforceUnique: Bool?
    
    public var reaction: StreamChatReactionRequest
    
    public var skipPush: Bool?
    
    public init(iD: String?, enforceUnique: Bool?, reaction: StreamChatReactionRequest, skipPush: Bool?) {
        self.iD = iD
        
        self.enforceUnique = enforceUnique
        
        self.reaction = reaction
        
        self.skipPush = skipPush
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case iD = "ID"
        
        case enforceUnique = "enforce_unique"
        
        case reaction
        
        case skipPush = "skip_push"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(iD, forKey: .iD)
        
        try container.encode(enforceUnique, forKey: .enforceUnique)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(skipPush, forKey: .skipPush)
    }
}
