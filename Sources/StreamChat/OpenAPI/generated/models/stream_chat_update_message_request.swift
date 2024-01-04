//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateMessageRequest: Codable, Hashable {
    public var skipEnrichUrl: Bool?
    
    public var message: StreamChatMessageRequest1
    
    public init(skipEnrichUrl: Bool?, message: StreamChatMessageRequest1) {
        self.skipEnrichUrl = skipEnrichUrl
        
        self.message = message
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case skipEnrichUrl = "skip_enrich_url"
        
        case message
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(skipEnrichUrl, forKey: .skipEnrichUrl)
        
        try container.encode(message, forKey: .message)
    }
}
