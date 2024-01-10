//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatDataDogInfo: Codable, Hashable {
    public var site: String
    
    public var apiKey: String
    
    public init(site: String, apiKey: String) {
        self.site = site
        
        self.apiKey = apiKey
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case site
        
        case apiKey = "api_key"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(site, forKey: .site)
        
        try container.encode(apiKey, forKey: .apiKey)
    }
}
