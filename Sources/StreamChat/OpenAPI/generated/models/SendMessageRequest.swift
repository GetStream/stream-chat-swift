//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct SendMessageRequest: Codable, Hashable {
    public var message: MessageRequest
    
    public var skipEnrichUrl: Bool? = nil
    
    public var skipPush: Bool? = nil
    
    public init(message: MessageRequest, skipEnrichUrl: Bool? = nil, skipPush: Bool? = nil) {
        self.message = message
        
        self.skipEnrichUrl = skipEnrichUrl
        
        self.skipPush = skipPush
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case message
        
        case skipEnrichUrl = "skip_enrich_url"
        
        case skipPush = "skip_push"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(skipEnrichUrl, forKey: .skipEnrichUrl)
        
        try container.encode(skipPush, forKey: .skipPush)
    }
}
