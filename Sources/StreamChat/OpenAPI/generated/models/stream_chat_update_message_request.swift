//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateMessageRequest: Codable, Hashable {
    public var message: StreamChatMessageRequest
    
    public var skipEnrichUrl: Bool?
    
    public init(message: StreamChatMessageRequest, skipEnrichUrl: Bool?) {
        self.message = message
        
        self.skipEnrichUrl = skipEnrichUrl
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case message
        
        case skipEnrichUrl = "skip_enrich_url"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(skipEnrichUrl, forKey: .skipEnrichUrl)
    }
}
