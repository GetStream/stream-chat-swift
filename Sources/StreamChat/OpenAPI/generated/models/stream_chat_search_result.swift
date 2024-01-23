//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSearchResult: Codable, Hashable {
    public var message: StreamChatSearchResultMessage? = nil
    
    public init(message: StreamChatSearchResultMessage? = nil) {
        self.message = message
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case message
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(message, forKey: .message)
    }
}
