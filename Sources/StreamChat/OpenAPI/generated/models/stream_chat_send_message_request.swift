//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSendMessageRequest: Codable, Hashable {
    public var skipEnrichUrl: Bool?
    
    public var skipPush: Bool?
    
    public var message: StreamChatMessageRequest
    
    public init(skipEnrichUrl: Bool?, skipPush: Bool?, message: StreamChatMessageRequest) {
        self.skipEnrichUrl = skipEnrichUrl
        
        self.skipPush = skipPush
        
        self.message = message
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case skipEnrichUrl = "skip_enrich_url"
        
        case skipPush = "skip_push"
        
        case message
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(skipEnrichUrl, forKey: .skipEnrichUrl)
        
        try container.encode(skipPush, forKey: .skipPush)
        
        try container.encode(message, forKey: .message)
    }
}
