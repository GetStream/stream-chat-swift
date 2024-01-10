//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFlagMessageDetails: Codable, Hashable {
    public var skipPush: Bool?
    
    public var updatedById: String?
    
    public var pinChanged: Bool?
    
    public var shouldEnrich: Bool?
    
    public init(skipPush: Bool?, updatedById: String?, pinChanged: Bool?, shouldEnrich: Bool?) {
        self.skipPush = skipPush
        
        self.updatedById = updatedById
        
        self.pinChanged = pinChanged
        
        self.shouldEnrich = shouldEnrich
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case skipPush = "skip_push"
        
        case updatedById = "updated_by_id"
        
        case pinChanged = "pin_changed"
        
        case shouldEnrich = "should_enrich"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(skipPush, forKey: .skipPush)
        
        try container.encode(updatedById, forKey: .updatedById)
        
        try container.encode(pinChanged, forKey: .pinChanged)
        
        try container.encode(shouldEnrich, forKey: .shouldEnrich)
    }
}
