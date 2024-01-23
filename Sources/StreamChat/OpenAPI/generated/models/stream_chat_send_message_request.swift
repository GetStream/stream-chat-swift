//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSendMessageRequest: Codable, Hashable {
    public var message: StreamChatMessageRequest
    
    public var skipEnrichUrl: Bool? = nil
    
    public var skipPush: Bool? = nil
    
    public init(message: StreamChatMessageRequest, skipEnrichUrl: Bool? = nil, skipPush: Bool? = nil) {
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
